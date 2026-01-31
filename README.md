# Nodejs_project

## Overview
This repository provisions and deploys a sample Node.js application onto an Amazon EKS cluster. Terraform is used to stand up every AWS dependency (VPC, subnets, IAM, EKS, ECR, and the AWS Load Balancer Controller). Kubernetes manifests deploy the application, service, and ingress. GitHub Actions automate both the infrastructure lifecycle and the application delivery pipeline.

## Repository Layout
- `infra/` – Terraform configuration that creates network primitives, an ECR repository, the EKS control plane + managed node group, and installs the AWS Load Balancer Controller through Helm/IRSA.
- `k8s/` – Namespace, Deployment, Service, and Ingress manifests for the Node.js workload; the service is exposed via an ALB managed by the controller.
- `node-app/` – Source for the Node.js application that is containerized and pushed to ECR.
- `.github/workflows/` – Deployment workflow for the Node app (build → push → kube apply), Terraform plan/apply workflows, and a nightly destroy workflow that tears down infra at 12 AM IST.

## Terraform Infrastructure (`infra/`)
1. **Providers & Data Sources** – The AWS provider talks to the target region. After the cluster is created, data sources fetch the cluster endpoint/CA/token for the Kubernetes and Helm providers so Terraform can install cluster add‑ons.
2. **Networking** – `aws_vpc`, public subnets, route table, and associations give EKS workers public internet access and tag subnets for load balancers.
3. **ECR** – `aws_ecr_repository.practice_node_app` stores images built by CI, with lifecycle rules ignoring mutable attributes.
4. **IAM** – Cluster and node-group roles attach the standard AWS managed policies. An IAM OIDC provider plus a custom role/policy powers IRSA for the AWS Load Balancer Controller.
5. **EKS + Node Group** – `aws_eks_cluster.practice` and `aws_eks_node_group.default` form the control plane and worker nodes, sized through variables.
6. **AWS Load Balancer Controller** – Terraform creates the service account, attaches the IAM policy from `iam-policy-alb.json`, then installs the Helm chart to automatically manage ALBs for ingress objects.

## Working with Terraform

### Initial Setup (One-time)
```bash
cd infra
# Setup remote state backend to prevent state loss
./setup-remote-state.sh

# Initialize Terraform with remote backend
terraform init
```

### Daily Workflow
```bash
cd infra
terraform plan          # review changes
terraform apply         # create/update resources
```

### Safe Destroy Workflow
⚠️ **Important**: Use the automated destroy script to preserve IAM resources and avoid import issues:

```bash
cd infra
./auto-destroy.sh       # Safe automated cleanup (preserves IAM)
```

**Why use `auto-destroy.sh` instead of `terraform destroy`?**
- Preserves IAM roles/policies to avoid "resource already exists" errors
- Uses remote state backend to prevent state loss
- Automated cleanup of all resources in correct dependency order
- No manual imports required after destruction

### Manual Destroy (Not Recommended)
```bash
terraform destroy       # Will fail due to IAM resource protection
```

### State Management
- **Remote Backend**: State is stored in S3 with DynamoDB locking
- **IAM Protection**: Critical IAM resources have `prevent_destroy = true`
- **Recovery**: If state is lost, IAM resources are preserved in AWS

### Troubleshooting State Issues
- If you accidentally delete IAM resources, re-import them:
  ```bash
  terraform import aws_iam_role.eks_cluster practice-node-app-cluster-role
  terraform import aws_iam_role.eks_node_group practice-node-app-node-role
  terraform import aws_iam_policy.alb_controller arn:aws:iam::852994641319:policy/practice-node-app-alb-controller-policy
  terraform import aws_eks_cluster.practice practice-node-app
  terraform import aws_eks_node_group.default practice-node-app:practice-node-app-node-group
  terraform import aws_iam_openid_connect_provider.eks arn:aws:iam::852994641319:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/[CLUSTER_ID]
  terraform import aws_iam_role.alb_controller practice-node-app-alb-controller
  ```

The nightly destroy GitHub Action can be disabled if persistent environments are needed. After any Terraform change, re-run `terraform plan` to update `.terraform.lock.hcl` so the provider versions stay in sync.

## Kubernetes Manifests (`k8s/`)
- `namespace.yaml` – Creates the `practice-app` namespace.
- `deployment.yaml` – Deploys the Node.js container pulled from ECR.
- `service.yaml` – Exposes pods on port 80 using the cluster IP; the AWS Load Balancer Controller registers targets from this service.
- `ingress.yaml` – Requests an internet-facing ALB (`alb.ingress.kubernetes.io/scheme`) with IP targets and HTTP listener on port 80. Once the controller reconciles it, the `kubectl get ingress -n practice-app` output shows the ALB DNS name.

Apply/update the manifests:
```bash
kubectl apply -f k8s/namespace.yaml \
  -f k8s/deployment.yaml \
  -f k8s/service.yaml \
  -f k8s/ingress.yaml
```
Verify ALB provisioning with `kubectl get ingress practice-node-app -n practice-app -o wide` and curl the returned DNS name.

## GitHub Actions
1. **deploy-node-app.yml** – Builds the Docker image, logs into ECR, pushes the new tag, updates the Kubernetes deployment, and rolls out changes.
2. **Terraform Plan/Apply workflows** – Run Terraform in GitHub-hosted runners. Separate jobs perform plan (for review) and apply (after approval). AWS credentials are passed through encrypted secrets (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, etc.).
3. **terraform-destroy.yml** – **Updated**: Scheduled workflow that runs `./auto-destroy.sh` nightly (cron for 12 AM IST) to keep AWS usage low while preserving IAM resources to avoid import issues.

### GitHub Actions Destroy Workflow
⚠️ **Important**: The destroy workflow has been updated to use `./auto-destroy.sh` instead of `terraform destroy` to prevent failures:

```yaml
- name: Automated destroy (preserves IAM resources)
  run: ./auto-destroy.sh
```

**Benefits:**
- ✅ No more "Instance cannot be destroyed" errors
- ✅ Preserves IAM roles/policies for reuse
- ✅ Automated cleanup in correct dependency order
- ✅ Consistent behavior between local and CI/CD environments

## Kubernetes Manifests

The `k8s/` directory contains all Kubernetes manifests for deploying the Node.js application to EKS:

### **Core Application Files**

#### `namespace.yaml`
Creates the `practice-app` namespace for isolating application resources.

#### `deployment.yaml`
Main application deployment with:
- 2 replicas of the Node.js container
- Health checks (readiness/liveness probes)
- Basic environment configuration

#### `service.yaml`
ClusterIP service exposing the application on port 80 internally.

#### `ingress.yaml`
AWS Load Balancer Controller ingress with:
- Internet-facing ALB
- HTTP traffic routing to the service
- ALB-specific annotations

### **Configuration & Advanced Examples**

#### `configmaps.yml`
Demonstrates ConfigMap usage with:
- Application configuration (NODE_ENV, LOG_LEVEL, etc.)
- Alternative deployment using ConfigMap environment injection

#### `service-discovery.yml`
Complete example showcasing:
- Client pod for testing service discovery
- Enhanced deployment with resource limits
- Secrets management for sensitive data
- Service-to-service communication

#### `advanced-k8s.yml`
Production-ready patterns including:
- Horizontal Pod Autoscaling (HPA)
- Network policies for security
- Persistent volume claims
- Init containers and startup probes
- Load testing capabilities

## Kubernetes Deployment

### **Quick Start**
```bash
# Deploy core application
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml

# Check deployment status
kubectl get all -n practice-app

# Get ALB endpoint
kubectl get ingress practice-node-app -n practice-app
```

### **Advanced Deployment Examples**
```bash
# Deploy with ConfigMaps
kubectl apply -f k8s/configmaps.yml

# Deploy enhanced version with secrets and resource limits
kubectl apply -f k8s/service-discovery.yml

# Deploy production-ready setup with autoscaling
kubectl apply -f k8s/advanced-k8s.yml
```

### **Common Commands**
```bash
# View all resources in namespace
kubectl get all -n practice-app

# Check pod logs
kubectl logs -f deployment/practice-node-app -n practice-app

# Debug pod issues
kubectl describe pod <pod-name> -n practice-app

# Access application locally
kubectl port-forward service/practice-node-app 3000:80 -n practice-app

# Scale deployment
kubectl scale deployment practice-node-app --replicas=3 -n practice-app
```

### **Troubleshooting**
- **ImagePullBackOff**: Ensure ECR repository has the built image
- **Pending pods**: Check resource requests vs node capacity
- **Ingress issues**: Verify AWS Load Balancer Controller is running
- **Network policies**: Ensure proper pod selectors for traffic flow

## Application Deployment Prerequisites
⚠️ **Important**: Before deploying the application, ensure:
- ECR repository exists (created by Terraform)
- EKS cluster is running and kubectl is configured
- AWS Load Balancer Controller is installed

**Common Issues:**
- `ImagePullBackOff`: ECR repository is empty - run GitHub Actions workflow or build/push manually
- `Pending` ALB: Check AWS Load Balancer Controller logs in `kube-system` namespace
- Pod failures: Use `kubectl describe pod <pod-name> -n practice-app` for debugging

## GitHub Actions CI/CD

This repository includes comprehensive CI/CD workflows for automated building, testing, and deployment.

### **Main CI/CD Pipeline** (`.github/workflows/deploy-node-app.yml`)

**Triggers:**
- Manual workflow dispatch
- Push to `main` branch
- Pull requests to `main` branch

**Features:**
- ✅ **Automated builds** with Docker layer caching
- ✅ **Vulnerability scanning** with Trivy
- ✅ **Multi-environment deployment** (staging/production)
- ✅ **Rollback capability** on deployment failure
- ✅ **Health checks** and ALB verification
- ✅ **Performance testing** with k6 load testing
- ✅ **Automated cleanup** of old ECR images
- ✅ **Deployment notifications** and status reporting

**Deployment Strategy:**
- **Pull Requests**: Deploy core manifests only
- **Main Branch**: Full deployment with ConfigMaps and advanced features
- **All Deployments**: Include ingress, health checks, and rollback protection

### **Canary Deployments** (`.github/workflows/canary-deploy.yml`)

**Features:**
- ✅ **Traffic splitting** (configurable percentage)
- ✅ **Canary monitoring** and health verification
- ✅ **Promote/Rollback** decisions
- ✅ **Zero-downtime** deployments

**Usage:**
1. Trigger canary workflow with desired traffic percentage
2. Monitor canary performance
3. Promote to main or rollback as needed

### **Environment-Specific Deployments**

**Staging Environment:**
- Namespace: `practice-app-staging`
- 1 replica, minimal resources
- No external ingress (internal only)

**Production Environment:**
- Namespace: `practice-app-prod`
- 3 replicas, higher resource allocation
- Full ALB ingress with internet-facing access

### **CI/CD Workflow Steps**

1. **Code Quality & Testing**
   - Node.js setup and dependency installation
   - Automated test execution
   - Smoke test validation

2. **Build & Security**
   - Docker image building with caching
   - ECR registry push with metadata tags
   - Trivy vulnerability scanning
   - SARIF report upload to GitHub

3. **Deployment**
   - Kubernetes manifest application
   - Environment-specific configuration
   - Image updates with proper tagging
   - Rollback verification

4. **Verification & Monitoring**
   - Rollout status monitoring
   - Health check validation
   - ALB endpoint testing
   - Performance testing with k6

5. **Cleanup & Notification**
   - Old ECR image cleanup (keep last 5)
   - Deployment success notifications
   - Failure alerts and rollback

### **Manual Deployment Options**

**Quick Deploy:**
```bash
# Deploy core application
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
kubectl apply -f k8s/deployment.yaml
```

**Environment-Specific:**
```bash
# Staging
kubectl apply -f k8s/environments/staging/

# Production
kubectl apply -f k8s/environments/production/
```

**Advanced Features:**
```bash
# With ConfigMaps and Secrets
kubectl apply -f k8s/configmaps.yml
kubectl apply -f k8s/service-discovery.yml

# Production-ready with autoscaling
kubectl apply -f k8s/advanced-k8s.yml
```

### **Troubleshooting CI/CD**

**Common Issues:**
- **Build Failures**: Check Dockerfile and dependencies
- **ECR Push Issues**: Verify AWS credentials and permissions
- **Deployment Failures**: Check Kubernetes manifests and resource limits
- **Health Check Failures**: Verify application `/health` endpoint
- **ALB Issues**: Check AWS Load Balancer Controller logs

**Debug Commands:**
```bash
# Check workflow logs in GitHub Actions
# Verify ECR images
aws ecr list-images --repository-name practice-node-app

# Check Kubernetes resources
kubectl get all -n practice-app
kubectl describe deployment practice-node-app -n practice-app
kubectl logs -f deployment/practice-node-app -n practice-app
```

## End-to-End Flow
1. Commit application or infra changes.
2. Terraform plan/apply workflows provision/modify the AWS stack.
3. **Deploy Application**: Use GitHub Actions or manual build/push:
   ```bash
   # Option A: GitHub Actions (Recommended)
   # Trigger deploy-node-app.yml workflow
   
   # Option B: Manual deployment
   cd node-app
   docker build -t practice-node-app:latest .
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 852994641319.dkr.ecr.us-east-1.amazonaws.com
   docker tag practice-node-app:latest 852994641319.dkr.ecr.us-east-1.amazonaws.com/practice-node-app:latest
   docker push 852994641319.dkr.ecr.us-east-1.amazonaws.com/practice-node-app:latest
   kubectl apply -f k8s/
   ```
4. The AWS Load Balancer Controller creates an ALB.
5. Access the app via the ALB DNS name.

## Troubleshooting Tips
- If Terraform complains about lock-file mismatches, rerun `terraform init -upgrade`.
- When the ingress lacks an address, inspect controller logs: `kubectl -n kube-system logs deploy/aws-load-balancer-controller`.
- Use `aws eks update-kubeconfig --name practice-node-app --region <region>` after cluster creation to interact with kubectl locally.
- **Resource Already Exists Errors**: Use `./auto-destroy.sh` instead of `terraform destroy` to prevent IAM resource conflicts.
- **State Lock Issues**: If Terraform is stuck with a state lock, wait a few minutes or use `terraform force-unlock <LOCK_ID>`.
- **Remote State Issues**: Ensure S3 bucket and DynamoDB table exist by running `./setup-remote-state.sh`.

## Cost Optimization
- **Automated Cleanup**: Use `./auto-destroy.sh` to remove all resources when not in use.
- **IAM Preservation**: Critical IAM resources are protected and reused, reducing setup time.
- **Nightly Destroy**: GitHub Actions automatically destroy resources at 12 AM IST to minimize costs.

## Security Best Practices
- **IAM Role Protection**: `prevent_destroy = true` prevents accidental deletion of critical IAM resources.
- **Remote State Encryption**: S3 bucket is encrypted with versioning enabled.
- **State Locking**: DynamoDB table prevents concurrent state modifications.
- **Least Privilege**: IAM roles use AWS managed policies with minimal required permissions.

With these pieces working together, you can reproducibly create, deploy, and tear down the entire environment from source control.
