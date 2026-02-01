#!/bin/bash
# =================================================================
# DESTROY PRODUCTION ENVIRONMENT
# =================================================================

set -e

echo "🔥 Destroying PRODUCTION Environment..."

# Safety check
echo "⚠️  WARNING: This will destroy the PRODUCTION environment!"
echo "🔒 Type 'destroy-production' to confirm:"
read -r confirmation
if [ "$confirmation" != "destroy-production" ]; then
    echo "❌ Destruction cancelled. Confirmation not provided."
    exit 1
fi

# Check if we're in the right directory
if [ ! -d "environments/prod" ]; then
    echo "❌ Error: Please run this script from the infra/ directory"
    exit 1
fi

# Setup state backend
echo "🔧 Setting up state backend..."
./setup-prod.sh

# Go to prod environment directory
cd environments/prod

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Destroy infrastructure
echo "🗑️  Destroying infrastructure..."
terraform destroy -auto-approve

# Clean up state management
echo "🗑️  Cleaning up state management..."
cd ..
aws s3 rb "s3://practice-node-app-terraform-state-prod" --force || true
aws dynamodb delete-table --table-name practice-node-app-terraform-locks-prod --region us-east-1 || true

echo "✅ Production environment destroyed successfully!"
