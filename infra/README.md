# Infrastructure Management

Simplified infrastructure management for AWS EKS, VPC, and ECR using Terraform with environment separation.

## 🎯 Quick Start

### **Create Environments:**
```bash
cd infra

# Development (no confirmation needed)
./create-dev.sh

# Production (requires safety confirmation)
./create-prod.sh
# Type: create-production
```

### **Destroy Environments:**
```bash
cd infra

# Development (no confirmation needed)
./destroy-dev-simple.sh

# Production (requires safety confirmation)
./destroy-prod-simple.sh
# Type: destroy-production
```

## 📁 File Structure

```
infra/
├── environments/              # Environment-specific configs
│   ├── dev/                   # Development environment
│   └── prod/                  # Production environment
├── modules/                   # Reusable Terraform modules
│   ├── vpc/                   # VPC, subnets, networking
│   ├── eks/                   # EKS cluster, node groups
│   ├── ecr/                   # ECR repositories
│   └── security/              # Security configurations
├── create-dev.sh             # Create development environment
├── create-prod.sh            # Create production environment
├── destroy-dev-simple.sh     # Destroy development environment
├── destroy-prod-simple.sh    # Destroy production environment
├── setup-dev.sh              # Setup development state backend
├── setup-prod.sh             # Setup production state backend
├── main.tf                   # Main Terraform configuration
├── variables.tf              # Terraform variables
├── outputs.tf                # Terraform outputs
└── backend.tf                # Terraform backend configuration
```

## 🚀 Environment Details

### **Development Environment:**
- **Cluster Name:** `practice-node-app-dev`
- **ECR Repository:** `practice-node-app-dev`
- **Namespace:** `practice-app-dev`
- **Node Size:** `t3.small`
- **Node Count:** 1-2 nodes

### **Production Environment:**
- **Cluster Name:** `practice-node-app-prod`
- **ECR Repository:** `practice-node-app-prod`
- **Namespace:** `practice-app-prod`
- **Node Size:** `t3.medium`
- **Node Count:** 2-4 nodes

## 🛡️ Safety Features

### **Production Protection:**
- ✅ **Typed confirmation required** for create/destroy operations
- ✅ **Clear warnings** before destructive actions
- ✅ **State management cleanup** to prevent orphaned resources

### **Error Handling:**
- ✅ **Scripts stop on errors** with `set -e`
- ✅ **Directory validation** ensures running from correct location
- ✅ **State backend setup** before operations

## 📋 Script Functions

### **create-dev.sh**
1. Validates directory structure
2. Sets up development state backend (S3 + DynamoDB)
3. Initializes Terraform
4. Plans infrastructure changes
5. Applies infrastructure automatically
6. Displays Terraform outputs

### **create-prod.sh**
1. Safety confirmation (type: `create-production`)
2. Validates directory structure
3. Sets up production state backend (S3 + DynamoDB)
4. Initializes Terraform
5. Plans infrastructure changes
6. Applies infrastructure automatically
7. Displays Terraform outputs

### **destroy-dev-simple.sh**
1. Validates directory structure
2. Sets up development state backend
3. Initializes Terraform
4. Destroys all infrastructure
5. Cleans up state management (S3 bucket + DynamoDB table)

### **destroy-prod-simple.sh**
1. Safety confirmation (type: `destroy-production`)
2. Validates directory structure
3. Sets up production state backend
4. Initializes Terraform
5. Destroys all infrastructure
6. Cleans up state management (S3 bucket + DynamoDB table)

## 🔧 State Management

### **Development:**
- **S3 Bucket:** `practice-node-app-terraform-state-dev`
- **DynamoDB Table:** `practice-node-app-terraform-locks-dev`
- **State Key:** `dev/terraform.tfstate`

### **Production:**
- **S3 Bucket:** `practice-node-app-terraform-state-prod`
- **DynamoDB Table:** `practice-node-app-terraform-locks-prod`
- **State Key:** `prod/terraform.tfstate`

## 🚀 GitHub Actions Integration

Use GitHub Actions workflows for CI/CD:

### **Infrastructure:**
- **`terraform-apply.yml`** - Manual infrastructure creation
- **`terraform-destroy.yml`** - Manual infrastructure destruction
- **`terraform-plan.yml`** - Infrastructure planning and PR comments

### **Deployments:**
- **`deploy-dev.yml`** - Automatic development deployments
- **`deploy-prod.yml`** - Manual production deployments
- **`promote-to-prod.yml`** - Production promotion workflow

## 📊 Infrastructure Components

### **VPC Module:**
- Public and private subnets
- Internet gateway and NAT gateways
- Route tables and associations
- Security groups

### **EKS Module:**
- EKS cluster with control plane
- Managed node groups
- IAM roles and policies
- AWS Load Balancer Controller
- Kubernetes cluster access

### **ECR Module:**
- Private container registry
- Image scanning on push
- Lifecycle policies
- Encryption at rest

## 🔧 Prerequisites

### **AWS CLI:**
```bash
aws configure
# Enter AWS Access Key ID, Secret Access Key, Region (us-east-1)
```

### **Terraform:**
```bash
# Install Terraform >= 1.0
# Follow: https://learn.hashicorp.com/tutorials/terraform/install-cli
```

### **kubectl:**
```bash
# Install kubectl
# Follow: https://kubernetes.io/docs/tasks/tools/
```

## 📝 Usage Examples

### **Create Development Environment:**
```bash
cd infra
./create-dev.sh
# Output: EKS cluster endpoint, ECR repository URL, etc.
```

### **Configure kubectl:**
```bash
aws eks update-kubeconfig --name practice-node-app-dev --region us-east-1
kubectl get nodes
```

### **Destroy Development Environment:**
```bash
cd infra
./destroy-dev-simple.sh
# All infrastructure removed
```

## 🚨 Important Notes

### **Production Safety:**
- Always confirm production actions by typing the required phrase
- Double-check environment before running destructive commands
- Use GitHub Actions for production deployments when possible

### **State Management:**
- Never manually delete S3 state buckets or DynamoDB tables
- Always use the provided scripts for cleanup
- State files are encrypted and versioned

### **Cost Management:**
- Development environment uses smaller instances for cost efficiency
- Remember to destroy environments when not in use
- Monitor AWS costs in the console

## 🔍 Troubleshooting

### **Common Issues:**
1. **"State bucket not found"** - Run setup script first
2. **"Permission denied"** - Check AWS credentials
3. **"Terraform init failed"** - Verify backend configuration
4. **"Cluster already exists"** - Destroy existing environment first

### **Get Help:**
```bash
# Check Terraform state
cd environments/dev && terraform state list

# Check AWS resources
aws eks list-clusters --region us-east-1
aws ecr describe-repositories --region us-east-1
```

## 📚 Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
