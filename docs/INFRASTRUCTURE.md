# AWS Infrastructure Documentation

## Terraform Configuration (`infra/`)

### Infrastructure Components

#### 1. **Providers & Data Sources**
- **AWS Provider**: Manages AWS resources in `us-east-1`
- **Kubernetes Provider**: Interacts with EKS cluster after creation
- **Helm Provider**: Installs AWS Load Balancer Controller

#### 2. **Networking**
- **VPC**: `10.0.0.0/16` with DNS support and hostnames
- **Public Subnets**: 3 subnets across availability zones
- **Internet Gateway**: Provides internet access
- **Route Tables**: Direct traffic to internet gateway
- **EKS Subnet Tags**: Required for ALB controller

#### 3. **ECR Repository**
- **Repository**: `practice-node-app`
- **Lifecycle Rules**: Prevent deletion of immutable tags
- **Image Scanning**: Enabled on push

#### 4. **IAM Configuration**
- **EKS Cluster Role**: `practice-node-app-cluster-role`
- **EKS Node Group Role**: `practice-node-app-node-role`
- **OIDC Provider**: For service account IAM roles
- **ALB Controller Role**: `practice-node-app-alb-controller`

#### 5. **EKS Cluster**
- **Cluster Name**: `practice-node-app`
- **Kubernetes Version**: Latest stable
- **Node Group**: Managed with t3.medium instances
- **IAM OIDC**: Enabled for IRSA

#### 6. **AWS Load Balancer Controller**
- **Helm Chart**: `aws-load-balancer-controller`
- **Repository**: `https://aws.github.io/eks-charts`
- **Service Account**: With IAM role binding
- **Namespace**: `kube-system`

### Working with Terraform

#### Initial Setup
```bash
cd infra

# Development backend + init
./setup-dev.sh

# Production backend + init
./setup-prod.sh
```
Each script provisions the S3 bucket + DynamoDB lock table for its environment, enables encryption/versioning, and runs `terraform init` (and an initial `plan`) within `infra/environments/<env>`.

#### Daily Operations
```bash
terraform plan            # Review changes
terraform apply           # Apply changes
terraform output         # View outputs
```

#### Safe Cleanup
```bash
./auto-destroy.sh        # Preserves IAM resources
```

### State Management

#### Remote Backend Configuration
- **S3 Bucket**: Terraform state storage
- **DynamoDB Table**: State locking
- **Encryption**: Server-side encryption enabled
- **Versioning**: State file versioning

#### IAM Resource Protection
```hcl
resource "aws_iam_role" "eks_cluster" {
  # ... other config
  
  lifecycle {
    prevent_destroy = true  # Prevents accidental deletion
  }
}
```

### Variables Configuration

#### `variables.tf`
```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "practice-node-app"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}
```

### Outputs

#### Key Outputs Available
- **cluster_endpoint**: EKS API server endpoint
- **cluster_certificate_authority_data**: EKS CA certificate
- **cluster_name**: EKS cluster name
- **ecr_repository_url**: ECR repository URI
- **node_group_role_arn**: Node group IAM role ARN

### Troubleshooting Infrastructure

#### Common Issues

**Resource Already Exists**
```bash
# Import existing resources
terraform import aws_iam_role.eks_cluster practice-node-app-cluster-role
terraform import aws_eks_cluster.practice practice-node-app
```

**State Lock Issues**
```bash
# Force unlock (use with caution)
terraform force-unlock LOCK_ID
```

**Provider Configuration**
```bash
# Re-initialize providers
terraform init -upgrade
```

#### Debug Commands
```bash
# Check state
terraform state list

# Show resource details
terraform state show aws_eks_cluster.practice

# Validate configuration
terraform validate

# Format configuration
terraform fmt
```

### Cost Management

#### Resource Costs
- **EKS Cluster**: ~$0.10/hour
- **EKS Nodes**: ~$0.04/hour per t3.medium
- **ALB**: ~$0.0225/hour + data transfer
- **ECR Storage**: ~$0.10/GB/month

#### Cost Optimization
- Use `./auto-destroy.sh` when not in use
- Enable ECR lifecycle policies
- Monitor with AWS Cost Explorer
- Set up billing alerts

### Security Best Practices

#### IAM Security
- **Least Privilege**: Minimal required permissions
- **Role Separation**: Different roles for cluster and nodes
- **OIDC Integration**: No long-lived credentials in pods
- **Resource Protection**: `prevent_destroy` on critical resources

#### Network Security
- **VPC Isolation**: Private network space
- **Security Groups**: Restrictive inbound/outbound rules
- **Subnet Tags**: Proper tagging for ALB controller
- **Encryption**: EKS secrets encryption enabled

#### Monitoring & Logging
- **CloudWatch**: Container insights enabled
- **Audit Logging**: EKS control plane logging
- **VPC Flow Logs**: Network traffic monitoring
- **CloudTrail**: API call auditing

### Advanced Configuration

#### Custom Node Groups
```hcl
resource "aws_eks_node_group" "custom" {
  cluster_name    = aws_eks_cluster.practice.name
  node_group_name = "custom-nodes"
  node_role_arn   = aws_iam_role.eks_node_group.arn
  subnet_ids      = aws_subnet.public[*].id
  
  scaling_config {
    desired_size = 3
    max_size     = 5
    min_size     = 1
  }
  
  instance_types = ["t3.large", "t3.xlarge"]
}
```

#### Additional Add-ons
```hcl
# Example: Cluster Autoscaler
resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
}
```

This infrastructure provides a solid foundation for running containerized applications on AWS EKS with proper security, monitoring, and cost management.
