# Node.js EKS Project

Complete infrastructure-as-code solution for deploying a Node.js application on Amazon EKS with automated CI/CD.

## 📁 Repository Structure

```
├── infra/                    # Terraform AWS infrastructure
├── k8s/                      # Kubernetes manifests
│   ├── environments/         # Environment-specific configs
│   ├── *.yaml               # Core application files
│   └── *.yml                # Advanced examples
├── node-app/                 # Node.js application source
└── .github/workflows/        # CI/CD pipelines
```

## 🚀 Quick Start

### 1. Infrastructure Setup
```bash
cd infra
./setup-remote-state.sh    # One-time setup
terraform init
terraform apply            # Create AWS resources
```

### 2. Deploy Application
```bash
# Option A: Automated (Recommended)
# Trigger GitHub Actions workflow: deploy-node-app.yml

# Option B: Manual
kubectl apply -f k8s/namespace.yaml \
  -f k8s/deployment.yaml \
  -f k8s/service.yaml \
  -f k8s/ingress.yaml

# Get ALB endpoint
kubectl get ingress practice-node-app -n practice-app
```

## 🏗️ Infrastructure Components

**AWS Resources (Terraform):**
- ✅ VPC, subnets, internet gateway
- ✅ EKS cluster + managed node group
- ✅ ECR repository for container images
- ✅ IAM roles with OIDC provider
- ✅ AWS Load Balancer Controller (Helm)

**Kubernetes Resources:**
- ✅ Namespace isolation
- ✅ Deployment with health checks
- ✅ Service and Ingress (ALB)
- ✅ ConfigMaps and Secrets
- ✅ Advanced patterns (HPA, Network Policies)

## 🔄 CI/CD Pipeline

### Main Workflow (`deploy-node-app.yml`)
**Triggers:** Manual, push to main, PRs

**Features:**
- 🔍 **Security:** Trivy vulnerability scanning
- 🚀 **Deployment:** Multi-environment support
- 🛡️ **Safety:** Automatic rollback on failure
- 📊 **Monitoring:** Health checks + performance testing
- 🧹 **Cleanup:** Automated ECR image management

### Canary Deployments (`canary-deploy.yml`)
- 🎯 **Traffic Splitting:** Configurable percentage (1-50%)
- 📈 **Monitoring:** Health verification and metrics
- 🔄 **Control:** Promote or rollback decisions

## 🌍 Environments

| Environment | Namespace | Replicas | Resources | Ingress |
|-------------|-----------|----------|-----------|---------|
| **Staging** | `practice-app-staging` | 1 | Minimal | Internal |
| **Production** | `practice-app-prod` | 3 | High | ALB |

## 🛠️ Common Commands

### Terraform
```bash
cd infra
terraform plan             # Preview changes
terraform apply            # Apply changes
./auto-destroy.sh          # Safe cleanup (preserves IAM)
```

### Kubernetes
```bash
# View resources
kubectl get all -n practice-app

# Debug issues
kubectl describe pod <name> -n practice-app
kubectl logs -f deployment/practice-node-app -n practice-app

# Scale application
kubectl scale deployment practice-node-app --replicas=3 -n practice-app

# Port forward for local testing
kubectl port-forward service/practice-node-app 3000:80 -n practice-app
```

## 📋 Advanced Deployment Options

### Environment-Specific
```bash
# Staging
kubectl apply -f k8s/environments/staging/

# Production  
kubectl apply -f k8s/environments/production/
```

### Advanced Features
```bash
# With ConfigMaps and Secrets
kubectl apply -f k8s/configmaps.yml
kubectl apply -f k8s/service-discovery.yml

# Production-ready with autoscaling
kubectl apply -f k8s/advanced-k8s.yml
```

## 🔧 Troubleshooting

### Common Issues
- **ImagePullBackOff:** Run GitHub Actions workflow or build/push manually
- **Pending pods:** Check resource requests vs node capacity  
- **ALB issues:** Verify AWS Load Balancer Controller logs
- **Terraform state:** Use `./auto-destroy.sh` instead of `terraform destroy`

### Debug Commands
```bash
# Check ECR images
aws ecr list-images --repository-name practice-node-app

# Check ALB status
kubectl get ingress practice-node-app -n practice-app -o wide

# Terraform state issues
terraform force-unlock <LOCK_ID>  # If state locked
```

## 💰 Cost Optimization

- **Automated Cleanup:** `./auto-destroy.sh` removes all resources
- **IAM Preservation:** Critical resources reused across deployments
- **Nightly Destroy:** GitHub Actions auto-cleanup at 12 AM IST

## 🔒 Security Features

- **IAM Protection:** `prevent_destroy = true` on critical resources
- **Remote State:** Encrypted S3 with DynamoDB locking
- **Vulnerability Scanning:** Trivy integration in CI/CD
- **Network Policies:** Pod-level traffic control

## 📖 Documentation

- **Terraform:** `infra/` - AWS infrastructure definitions
- **Kubernetes:** `k8s/` - Application manifests and examples
- **CI/CD:** `.github/workflows/` - Automated deployment pipelines
- **Application:** `node-app/` - Node.js source code

---

**End-to-End Flow:** Code → GitHub Actions → ECR → EKS → ALB → Production

This setup provides a complete, production-ready deployment pipeline with proper security, monitoring, and cost management.
