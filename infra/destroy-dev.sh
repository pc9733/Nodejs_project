#!/bin/bash
# =================================================================
# DESTROY DEVELOPMENT ENVIRONMENT
# Safely destroys development infrastructure
# =================================================================

set -e

echo "🔥 Destroying Development Environment..."

# Check if we're in the right directory
if [ ! -d "environments/dev" ]; then
    echo "❌ Error: Please run this script from the infra/ directory"
    exit 1
fi

# Setup state backend first
echo "� Setting up state backend..."
./setup-dev.sh

# Go to dev environment directory
cd environments/dev

# Initialize Terraform
echo "� Initializing Terraform..."
terraform init

# Destroy infrastructure
echo "🗑️  Destroying infrastructure..."
terraform destroy -auto-approve

# Clean up S3 bucket and DynamoDB table
echo "🗑️  Cleaning up state management..."
cd ..
aws s3 rb "s3://practice-node-app-terraform-state-dev" --force || true
aws dynamodb delete-table --table-name practice-node-app-terraform-locks-dev --region us-east-1 || true

echo "✅ Development environment destroyed successfully!"
