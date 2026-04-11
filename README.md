# Node.js EKS Project

Complete infrastructure-as-code solution for deploying a Node.js application on Amazon EKS with automated CI/CD.

## � Quick Start

### 1. Infrastructure Setup
```bash
cd infra

# Development
./create-dev.sh

# Production (requires confirmation prompt)
./create-prod.sh
```
These helper scripts handle backend bootstrapping (S3 bucket + DynamoDB table), run `terraform init/plan`, and apply the environment automatically.

### 2. Deploy Application
```bash
# Dev deploys automatically after every push to develop.
# For prod, trigger manually via GitHub Actions:
#   Actions → Deploy to Production → Run workflow

# Get ALB endpoint
kubectl get ingress practice-node-app-prod -n practice-app-prod
```

## �📁 Repository Structure

```
├── infra/                    # Terraform AWS infrastructure
├── k8s/                      # Kubernetes manifests
│   ├── environments/         # Environment-specific configs
│   ├── *.yaml               # Core application files
│   └── *.yml                # Advanced examples
├── node-app/                 # Node.js application source
├── .github/workflows/        # CI/CD pipelines
└── docs/                     # Detailed documentation
    ├── INFRASTRUCTURE.md     # AWS infrastructure details
    ├── KUBERNETES.md         # Kubernetes manifests guide
    ├── CICD.md              # CI/CD pipeline documentation
    └── TROUBLESHOOTING.md    # Common issues and solutions
```

## 🏗️ Architecture Overview

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

**Main Workflow Features:**
- 🔍 **Security:** Trivy vulnerability scanning
- 🚀 **Deployment:** Multi-environment support
- 🛡️ **Safety:** Automatic rollback on failure
- 📊 **Monitoring:** Health checks + performance testing
- 🧹 **Cleanup:** Automated ECR image management

**Canary Deployments:**
- 🎯 **Traffic Splitting:** Configurable percentage (1-50%)
- 📈 **Monitoring:** Health verification and metrics
- 🔄 **Control:** Promote or rollback decisions

## 🌍 Environments

| Environment | Namespace | Replicas | Resources | Ingress |
|-------------|-----------|----------|-----------|---------|
| **Development** | `practice-app-dev` | 2 | Low | NGINX |
| **Production** | `practice-app-prod` | 3–10 (HPA) | High | ALB (internet-facing) |

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
kubectl get all -n practice-app-dev
kubectl get all -n practice-app-prod

# Debug issues
kubectl describe pod <name> -n practice-app-prod
kubectl logs -f deployment/practice-node-app-prod -n practice-app-prod

# Port forward for local testing
kubectl port-forward service/practice-node-app-dev 3000:80 -n practice-app-dev
```

## 📖 Documentation

- **[Workflows & Branching](docs/WORKFLOWS.md)** - How CI/CD works, when to use each workflow
- **[Infrastructure Guide](docs/INFRASTRUCTURE.md)** - AWS infrastructure details
- **[Kubernetes Guide](docs/KUBERNETES.md)** - Application manifests and examples
- **[Troubleshooting Guide](docs/TROUBLESHOOTING.md)** - Common issues and solutions
- **[Fresh AWS Account Setup](docs/FRESH_AWS_ACCOUNT_SETUP.md)** - First-time setup guide
- **[Parameter Store Setup](docs/PARAMETER_STORE_SETUP.md)** - Secret management

## 💰 Cost Optimization

- **Automated Cleanup:** `./auto-destroy.sh` removes all resources
- **IAM Preservation:** Critical resources reused across deployments
- **Nightly Destroy:** GitHub Actions auto-cleanup at 12 AM IST

## 🔒 Security Features

- **IAM Protection:** `prevent_destroy = true` on critical resources
- **Remote State:** Encrypted S3 with DynamoDB locking
- **Vulnerability Scanning:** Trivy integration in CI/CD
- **Network Policies:** Pod-level traffic control

---

**End-to-End Flow:** Code → GitHub Actions → ECR → EKS → ALB → Production

This setup provides a complete, production-ready deployment pipeline with proper security, monitoring, and cost management.
