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

# Resolve AWS account ID so bucket/table names are globally unique
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="us-east-1"
BUCKET_NAME="practice-node-app-terraform-state-${ACCOUNT_ID}-dev"
DYNAMO_TABLE="practice-node-app-terraform-locks-${ACCOUNT_ID}-dev"

echo "📦 Creating S3 bucket for Terraform state: $BUCKET_NAME"
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo "Bucket already exists, skipping creation"
else
    aws s3api create-bucket \
        --bucket "$BUCKET_NAME" \
        --region "$AWS_REGION"
fi

aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
    }'

echo "🔒 Creating DynamoDB table for state locking: $DYNAMO_TABLE"
aws dynamodb create-table \
    --table-name "$DYNAMO_TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$AWS_REGION" 2>/dev/null && echo "Table created" || echo "Table already exists, skipping"

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
