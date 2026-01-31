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

## Kubernetes Practice Exercises

This section contains hands-on Kubernetes exercises for learning and practice. All exercises are designed to work with the existing EKS cluster and Node.js application.

### 🚀 Exercise 1: Basic Pod Troubleshooting

**File**: `k8s/debug.yaml` (create your own)
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: debug-pod
spec:
  containers:
  - name: debug-container
    image: alpine
    command: ['sleep', '3600']
```

**Commands**:
```bash
# Create and check pod
kubectl apply -f k8s/debug.yaml
kubectl get pods

# Debug inside pod
kubectl exec -it debug-pod -- sh
kubectl describe pod debug-pod
kubectl logs debug-pod

# Clean up
kubectl delete pod debug-pod
```

**Learning**: Basic pod operations, shell access, troubleshooting

---

### ⚙️ Exercise 2: ConfigMaps for Configuration

**File**: `k8s/configmaps.yml`
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: practice-app-config
  namespace: practice-app
data:
  NODE_ENV: "production"
  PORT: "3000"
  LOG_LEVEL: "info"
  API_VERSION: "v1"
  DB_HOST: "practice-db.example.com"
  DB_PORT: "5432"
  REDIS_URL: "redis://practice-redis:6379"
```

**Commands**:
```bash
# Apply ConfigMap and deployment
kubectl apply -f k8s/configmaps.yml

# Check environment variables in pod
kubectl exec -it <pod-name> -n practice-app -- env | grep -E "(NODE_ENV|PORT|LOG_LEVEL)"

# Update ConfigMap
kubectl patch configmap practice-app-config -n practice-app -p '{"data":{"LOG_LEVEL":"debug"}}'

# Restart deployment to pick up changes
kubectl rollout restart deployment practice-node-app-config -n practice-app

# Verify updated values
kubectl exec -it <new-pod-name> -n practice-app -- env | grep LOG_LEVEL
```

**Learning**: Configuration management, environment variable injection, ConfigMap updates

---

### 🔗 Exercise 3: Service Discovery

**File**: `k8s/service-discovery.yml`
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: client-pod
  namespace: practice-app
spec:
  containers:
  - name: curl
    image: curlimages/curl
    command: ['sleep', '3600']
```

**Commands**:
```bash
# Apply client pod
kubectl apply -f k8s/service-discovery.yml

# Test service discovery
kubectl exec -it client-pod -n practice-app -- curl http://practice-node-app/health
kubectl exec -it client-pod -n practice-app -- curl http://practice-node-app-enhanced/health

# Check DNS resolution
kubectl exec -it client-pod -n practice-app -- nslookup practice-node-app
```

**Learning**: Internal Kubernetes networking, service discovery, DNS resolution

---

### 🔐 Exercise 4: Secrets Management

**File**: Part of `k8s/service-discovery.yml`
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: practice-app-secrets
  namespace: practice-app
type: Opaque
data:
  DB_PASSWORD: cGFzc3dvcmQxMjM=  # base64 encoded "password123"
  API_KEY: YXBpa2V5c2VjcmV0MTIz  # base64 encoded "apikeysecret123"
```

**Commands**:
```bash
# Create secret manually
echo -n "password123" | base64
echo -n "apikeysecret123" | base64

# Apply and verify
kubectl apply -f k8s/service-discovery.yml
kubectl get secret practice-app-secrets -n practice-app -o yaml

# Check environment variables in pod
kubectl exec -it <pod-name> -n practice-app -- env | grep -E "(DB_PASSWORD|API_KEY)"
```

**Learning**: Secret creation, base64 encoding, secure environment variable injection

---

### 📊 Exercise 5: Resource Limits & Health Probes

**File**: Part of `k8s/service-discovery.yml`
```yaml
resources:
  requests:
    memory: "128Mi"
    cpu: "100m"
  limits:
    memory: "256Mi"
    cpu: "200m"
livenessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 30
  periodSeconds: 10
readinessProbe:
  httpGet:
    path: /health
    port: 3000
  initialDelaySeconds: 5
  periodSeconds: 5
```

**Commands**:
```bash
# Apply enhanced deployment
kubectl apply -f k8s/service-discovery.yml

# Check resource allocation
kubectl describe pod <pod-name> -n practice-app | grep -A 10 "Requests\|Limits"

# Monitor health probes
kubectl describe pod <pod-name> -n practice-app | grep -A 5 "Liveness\|Readiness"

# Test resource pressure (if metrics server available)
kubectl top pods -n practice-app
```

**Learning**: Resource management, health monitoring, probe configuration

---

### 🛡️ Exercise 6: Network Policies

**File**: Part of `k8s/advanced-k8s.yml`
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: practice-app-netpol
  namespace: practice-app
spec:
  podSelector:
    matchLabels:
      app: practice-node-app-enhanced
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: client-pod
    ports:
    - protocol: TCP
      port: 3000
```

**Commands**:
```bash
# Apply network policy
kubectl apply -f k8s/advanced-k8s.yml

# Test allowed traffic
kubectl exec -it client-pod -n practice-app -- curl http://practice-node-app-enhanced/health

# Test blocked traffic (create unauthorized pod)
kubectl run unauthorized --image=curlimages/curl --rm -it --restart=Never -- curl http://practice-node-app-enhanced/health

# Check network policy
kubectl describe networkpolicy practice-app-netpol -n practice-app
```

**Learning**: Network security, traffic control, policy enforcement

---

### 📈 Exercise 7: Horizontal Pod Autoscaling

**File**: Part of `k8s/advanced-k8s.yml`
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: practice-app-hpa
  namespace: practice-app
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: practice-node-app-enhanced
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

**Commands**:
```bash
# Apply HPA
kubectl apply -f k8s/advanced-k8s.yml

# Check HPA status
kubectl get hpa -n practice-app
kubectl describe hpa practice-app-hpa -n practice-app

# Generate load for testing
kubectl apply -f k8s/advanced-k8s.yml  # includes load-tester pod

# Monitor scaling events
kubectl get pods -n practice-app -w
kubectl describe hpa practice-app-hpa -n practice-app
```

**Learning**: Auto-scaling configuration, load testing, scaling events

---

### 🗄️ Exercise 8: Persistent Storage

**File**: Part of `k8s/advanced-k8s.yml`
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: practice-app-pvc
  namespace: practice-app
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: gp2
```

**Commands**:
```bash
# Apply PVC
kubectl apply -f k8s/advanced-k8s.yml

# Check PVC status
kubectl get pvc -n practice-app
kubectl describe pvc practice-app-pvc -n practice-app

# Check volume mounting in pod
kubectl describe pod <pod-name> -n practice-app | grep -A 5 "Mounts\|Volumes"
```

**Learning**: Persistent storage, volume claims, storage classes

---

### 🚀 Exercise 9: Init Containers & Startup Probes

**File**: Part of `k8s/advanced-k8s.yml`
```yaml
spec:
  initContainers:
  - name: init-db
    image: busybox:1.35
    command: ['sh', '-c', 'echo "Initializing database..." && sleep 5']
  - name: init-cache
    image: busybox:1.35
    command: ['sh', '-c', 'echo "Warming up cache..." && sleep 3']
  containers:
  - name: node-app
    startupProbe:
      httpGet:
        path: /health
        port: 3000
      initialDelaySeconds: 10
      periodSeconds: 5
      failureThreshold: 6
```

**Commands**:
```bash
# Apply advanced deployment
kubectl apply -f k8s/advanced-k8s.yml

# Watch init container logs
kubectl logs <pod-name> -n practice-app -c init-db
kubectl logs <pod-name> -n practice-app -c init-cache

# Check startup probe status
kubectl describe pod <pod-name> -n practice-app | grep -A 5 "Startup"
```

**Learning**: Initialization sequences, startup probes, multi-container patterns

---

## 🧪 Important Commands Reference

### **Pod Management**
```bash
kubectl get pods -n practice-app
kubectl describe pod <pod-name> -n practice-app
kubectl logs <pod-name> -n practice-app
kubectl exec -it <pod-name> -n practice-app -- sh
kubectl delete pod <pod-name> -n practice-app
```

### **Configuration**
```bash
kubectl get configmap -n practice-app
kubectl describe configmap <name> -n practice-app
kubectl get secret -n practice-app
kubectl describe secret <name> -n practice-app
```

### **Services & Networking**
```bash
kubectl get svc -n practice-app
kubectl describe svc <service-name> -n practice-app
kubectl get networkpolicy -n practice-app
kubectl describe networkpolicy <policy-name> -n practice-app
```

### **Scaling & Resources**
```bash
kubectl get hpa -n practice-app
kubectl describe hpa <hpa-name> -n practice-app
kubectl top pods -n practice-app  # if metrics server installed
kubectl describe pod <pod-name> -n practice-app | grep -A 10 "Resources"
```

### **Storage**
```bash
kubectl get pvc -n practice-app
kubectl describe pvc <pvc-name> -n practice-app
kubectl get pv
```

### **Deployment Management**
```bash
kubectl get deployment -n practice-app
kubectl describe deployment <deployment-name> -n practice-app
kubectl rollout status deployment/<deployment-name> -n practice-app
kubectl rollout restart deployment/<deployment-name> -n practice-app
kubectl rollout history deployment/<deployment-name> -n practice-app
```

### **Troubleshooting**
```bash
kubectl get events -n practice-app --sort-by=.metadata.creationTimestamp
kubectl get all -n practice-app
kubectl explain <resource-type>
kubectl api-resources | grep <resource>
```

## 🎯 Learning Outcomes

After completing these exercises, you'll have mastered:
- ✅ **Pod lifecycle management** and troubleshooting
- ✅ **Configuration management** with ConfigMaps and Secrets
- ✅ **Service discovery** and internal networking
- ✅ **Resource management** and health monitoring
- ✅ **Network security** with policies
- ✅ **Auto-scaling** based on resource usage
- ✅ **Persistent storage** for stateful applications
- ✅ **Advanced deployment patterns** with init containers
- ✅ **Production-ready** Kubernetes configurations

These exercises cover the essential Kubernetes skills needed for real-world deployments and production environments.

## Application Deployment Prerequisites
⚠️ **Important**: Before deploying the application, ensure:
- ECR repository exists (created by Terraform)
- EKS cluster is running and kubectl is configured
- AWS Load Balancer Controller is installed

**Common Issues:**
- `ImagePullBackOff`: ECR repository is empty - run GitHub Actions workflow or build/push manually
- `Pending` ALB: Check AWS Load Balancer Controller logs in `kube-system` namespace
- Pod failures: Use `kubectl describe pod <pod-name> -n practice-app` for debugging

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
