#!/bin/bash
# =================================================================
# CREATE PRODUCTION ENVIRONMENT
# =================================================================

set -e

echo "🚀 Creating PRODUCTION Environment..."

# Safety check
echo "⚠️  WARNING: This will create the PRODUCTION environment!"
echo "🔒 Type 'create-production' to confirm:"
read -r confirmation
if [ "$confirmation" != "create-production" ]; then
    echo "❌ Creation cancelled. Confirmation not provided."
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

# Plan and apply
echo "📋 Planning infrastructure changes..."
terraform plan

echo "🚀 Applying infrastructure..."
terraform apply -auto-approve

# Get outputs
echo "📊 Infrastructure Outputs:"
terraform output

echo "✅ Production environment created successfully!"
echo ""
echo "🔧 Next steps:"
echo "1. Configure kubectl: aws eks update-kubeconfig --name practice-node-app-prod --region us-east-1"
echo "2. Set secrets: ../scripts/setup-parameter-store.sh"
echo "3. Deploy app: Actions → Deploy to Production (deploy-prod.yml)"
