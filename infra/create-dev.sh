#!/bin/bash
# =================================================================
# CREATE DEVELOPMENT ENVIRONMENT
# =================================================================

set -e

echo "🚀 Creating DEVELOPMENT Environment..."

# Check if we're in the right directory
if [ ! -d "environments/dev" ]; then
    echo "❌ Error: Please run this script from the infra/ directory"
    exit 1
fi

# Setup state backend
echo "🔧 Setting up state backend..."
./setup-dev.sh

# Go to dev environment directory
cd environments/dev

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

echo "🔐 Configuring kubectl for the dev cluster..."
aws eks update-kubeconfig --name practice-node-app-dev --region us-east-1

echo "✅ Development environment created successfully!"
echo ""
echo "🔧 Next steps (from repo root):"
echo "1. Set secrets: ./scripts/setup-parameter-store.sh"
echo "2. Apply SecretStore: kubectl apply -f k8s/addons/external-secrets-dev.yaml"
echo "3. Deploy app: kubectl apply -f k8s/environments/dev/all-in-one.yaml"
echo "   (later: merge to develop for auto-deploy via GitHub Actions)"
