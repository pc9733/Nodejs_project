#!/bin/bash
# =================================================================
# SETUP DEV ENVIRONMENT
# Creates development infrastructure using Terraform modules
# =================================================================

set -e

echo "🚀 Setting up Development Environment..."

# Check if we're in the right directory
if [ ! -d "environments/dev" ]; then
    echo "❌ Error: Please run this script from the infra/ directory"
    exit 1
fi

# Create S3 bucket for Terraform state
echo "📦 Creating S3 bucket for Terraform state..."
BUCKET_NAME="practice-node-app-terraform-state-dev"
AWS_REGION="us-east-1"

if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "Bucket already exists"
else
    if [ "$AWS_REGION" = "us-east-1" ]; then
        aws s3api create-bucket \
            --bucket "$BUCKET_NAME" \
            --region "$AWS_REGION"
    else
        aws s3api create-bucket \
            --bucket "$BUCKET_NAME" \
            --region "$AWS_REGION" \
            --create-bucket-configuration LocationConstraint="$AWS_REGION"
    fi
fi

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }'

# Create DynamoDB table for state locking
echo "🔒 Creating DynamoDB table for state locking..."
aws dynamodb create-table \
    --table-name practice-node-app-terraform-locks-dev \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region us-east-1 || echo "Table already exists"

# Initialize Terraform
echo "🔧 Initializing Terraform..."
cd environments/dev
terraform init

# Plan and apply
echo "📋 Planning Terraform changes..."
terraform plan

echo "✅ Development environment setup complete!"
echo ""
echo "Next steps:"
echo "1. Review the plan above"
echo "2. Run: cd environments/dev && terraform apply"
echo "3. Configure kubectl: terraform output -raw configure_kubectl | bash"
echo ""
echo "Resources that will be created:"
echo "- VPC with public subnets"
echo "- EKS cluster (1 node, t3.small)"
echo "- ECR repository"
echo "- AWS Load Balancer Controller"
