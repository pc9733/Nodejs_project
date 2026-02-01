# Infrastructure Management

This directory contains Terraform configurations for managing AWS infrastructure using a modular, environment-separated approach.

## 🏗️ Architecture

```
infra/
├── modules/                    # Reusable Terraform modules
│   ├── vpc/                   # VPC, subnets, networking
│   ├── eks/                   # EKS cluster, node groups
│   ├── ecr/                   # ECR repositories
│   └── security/              # Security configurations
├── environments/              # Environment-specific configs
│   ├── dev/                   # Development environment
│   └── prod/                  # Production environment
├── setup-dev.sh              # Setup development environment
├── setup-prod.sh             # Setup production environment
├── apply-dev.sh              # Apply development changes
├── apply-prod.sh             # Apply production changes
├── destroy-dev.sh            # Destroy development environment
├── destroy-prod.sh           # Destroy production environment
├── apply-all.sh              # Apply all environments
├── destroy-all.sh            # Destroy all environments
└── auto-destroy.sh           # Legacy single-environment destroy
```

## 🚀 Quick Start

### Development Environment

```bash
# Setup (one-time)
./setup-dev.sh

# Apply infrastructure
./apply-dev.sh

# Deploy application
# Trigger deploy-dev.yml GitHub Actions workflow
```

### Production Environment

```bash
# Setup (one-time)
./setup-prod.sh

# Apply infrastructure
./apply-prod.sh

# Deploy application
# Trigger deploy-prod.yml GitHub Actions workflow with approval
```

## 📋 Environment Comparison

| Feature | Development | Production |
|---------|-------------|-------------|
| **VPC CIDR** | 10.1.0.0/16 | 10.2.0.0/16 |
| **EKS Nodes** | 1 (t3.small) | 3 (t3.medium/large) |
| **ECR** | Mutable tags | Immutable tags |
| **Encryption** | AES256 | KMS |
| **NAT Gateway** | Disabled | Enabled |
| **ALB Access** | Internal | Internet-facing |
| **Logging** | Basic | Enhanced |
| **Security** | Basic | Advanced |

## 🔧 Script Usage

### Setup Scripts

```bash
./setup-dev.sh    # Creates S3 bucket, DynamoDB table, initializes Terraform
./setup-prod.sh   # Creates production resources with enhanced security
```

### Apply Scripts

```bash
./apply-dev.sh    # Applies development infrastructure
./apply-prod.sh   # Applies production infrastructure (requires confirmation)
./apply-all.sh    # Applies both environments (requires confirmation)
```

### Destroy Scripts

```bash
./destroy-dev.sh    # Destroys development environment
./destroy-prod.sh   # Destroys production environment (requires confirmation)
./destroy-all.sh    # Destroys both environments (requires confirmation)
./auto-destroy.sh   # Legacy single-environment destroy (deprecated)
```

## 🔒 Safety Features

### Production Protection
- **Manual Confirmation**: Production operations require typed confirmation
- **Enhanced Security**: KMS encryption, private endpoints, network policies
- **Resource Limits**: Quotas and PDBs to prevent resource exhaustion

### State Management
- **Separate Backends**: Dev and prod use different S3 buckets
- **State Locking**: DynamoDB tables prevent concurrent modifications
- **Encryption**: All state files are encrypted at rest

## 📊 Cost Management

### Development Environment
- **Minimal Resources**: Single t3.small node
- **No NAT Gateway**: Saves costs on private subnet access
- **Basic Logging**: Reduced CloudWatch costs

### Production Environment
- **High Availability**: Multiple nodes across AZs
- **Enhanced Monitoring**: Comprehensive logging and metrics
- **Security Features**: Advanced security controls

## 🔄 Workflow Integration

### Development Pipeline
- **Triggers**: `develop`, `feature/*`, `hotfix/*` branches
- **Repository**: `practice-node-app-dev`
- **Namespace**: `practice-app-dev`
- **Deployment**: Fast, basic testing

### Production Pipeline
- **Triggers**: `main` branch, releases, manual approval
- **Repository**: `practice-node-app-prod`
- **Namespace**: `practice-app-prod`
- **Deployment**: Security scanning, performance testing, rollback

## 🛠️ Manual Operations

### Terraform Commands

```bash
# Development
cd environments/dev
terraform plan    # Preview changes
terraform apply   # Apply changes
terraform destroy # Destroy environment

# Production
cd environments/prod
terraform plan    # Preview changes
terraform apply   # Apply changes
terraform destroy # Destroy environment
```

### Kubernetes Commands

```bash
# Development
aws eks update-kubeconfig --name practice-node-app-dev
kubectl get pods -n practice-app-dev

# Production
aws eks update-kubeconfig --name practice-node-app-prod
kubectl get pods -n practice-app-prod
```

## 🚨 Emergency Procedures

### Complete Cleanup
```bash
# Destroy everything
./destroy-all.sh

# Clean up any remaining resources
aws cloudformation delete-stack --stack-name practice-node-app-dev || true
aws cloudformation delete-stack --stack-name practice-node-app-prod || true
```

### Recovery
```bash
# Recreate from scratch
./setup-dev.sh && ./apply-dev.sh
./setup-prod.sh && ./apply-prod.sh
```

## 📈 Monitoring

### AWS Resources
- **CloudWatch**: EKS metrics, logs, alarms
- **Cost Explorer**: Track spending by environment
- **CloudTrail**: Audit all API calls

### Kubernetes Resources
- **kubectl**: Pod status, events, logs
- **Prometheus**: Metrics collection (if configured)
- **Grafana**: Visualization (if configured)

## 🔍 Troubleshooting

### Common Issues

**Terraform State Lock**
```bash
# Force unlock (use with caution)
terraform force-unlock LOCK_ID
```

**EKS Cluster Not Ready**
```bash
# Check cluster status
aws eks describe-cluster --name practice-node-app-dev

# Check node group status
aws eks describe-nodegroup --cluster-name practice-node-app-dev --nodegroup-name practice-node-app-dev-node-group
```

**kubectl Connection Issues**
```bash
# Update kubeconfig
aws eks update-kubeconfig --name practice-node-app-dev --region us-east-1

# Test connection
kubectl get nodes
```

## 📚 Documentation

- **[Main README](../README.md)** - Project overview
- **[Infrastructure Guide](../docs/INFRASTRUCTURE.md)** - Detailed infrastructure documentation
- **[Kubernetes Guide](../docs/KUBERNETES.md)** - Kubernetes manifests and usage
- **[CI/CD Documentation](../docs/CICD.md)** - Pipeline configuration

## 🤝 Contributing

When making changes to infrastructure:

1. **Test in Development First**: Always test changes in dev environment
2. **Use Terraform Format**: `terraform fmt` before committing
3. **Document Changes**: Update relevant documentation
4. **Review Plans**: Always review `terraform plan` output
5. **Tag Resources**: Use consistent tagging across environments

## 📞 Support

For infrastructure issues:
1. Check the troubleshooting section
2. Review AWS CloudWatch logs
3. Examine Terraform state and outputs
4. Check GitHub Actions workflow logs
