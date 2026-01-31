#!/bin/bash
# =================================================================
# APPLY DEVELOPMENT ENVIRONMENT
# Creates or updates development infrastructure
# =================================================================

set -e

echo "🚀 Applying Development Environment..."

# Check if we're in the right directory
if [ ! -d "environments/dev" ]; then
    echo "❌ Error: Please run this script from the infra/ directory"
    exit 1
fi

# Go to dev environment directory
cd environments/dev

# Initialize Terraform (if not already done)
if [ ! -d ".terraform" ]; then
    echo "🔧 Initializing Terraform..."
    terraform init
fi

# Plan the changes
echo "📋 Planning Terraform changes..."
terraform plan

# Apply the changes
echo "✅ Applying Terraform changes..."
terraform apply -auto-approve

# Configure kubectl
echo "🔧 Configuring kubectl..."
aws eks update-kubeconfig --name practice-node-app-dev --region us-east-1

# Verify cluster is ready
echo "🔍 Verifying cluster..."
kubectl get nodes
kubectl get namespaces

echo "✅ Development environment applied successfully!"
echo ""
echo "Next steps:"
echo "1. Trigger deploy-dev.yml GitHub Actions workflow"
echo "2. Or deploy manually: kubectl apply -f ../../k8s/environments/dev/all-in-one.yaml"
echo ""
echo "Cluster access configured. Use 'kubectl' to manage the cluster."
