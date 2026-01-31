#!/bin/bash
# =================================================================
# APPLY PRODUCTION ENVIRONMENT
# Creates or updates production infrastructure
# =================================================================

set -e

echo "🚀 Applying Production Environment..."

# Check if we're in the right directory
if [ ! -d "environments/prod" ]; then
    echo "❌ Error: Please run this script from the infra/ directory"
    exit 1
fi

# Safety check for production
echo "⚠️  WARNING: This will apply changes to the PRODUCTION environment!"
echo "🔒 Type 'apply-production' to confirm:"
read -r confirmation
if [ "$confirmation" != "apply-production" ]; then
    echo "❌ Apply cancelled. Confirmation not provided."
    exit 1
fi

# Go to prod environment directory
cd environments/prod

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
aws eks update-kubeconfig --name practice-node-app-prod --region us-east-1

# Verify cluster is ready
echo "🔍 Verifying cluster..."
kubectl get nodes
kubectl get namespaces

echo "✅ Production environment applied successfully!"
echo ""
echo "Next steps:"
echo "1. Trigger deploy-prod.yml GitHub Actions workflow with approval"
echo "2. Or deploy manually: kubectl apply -f ../../k8s/environments/prod/all-in-one.yaml"
echo ""
echo "Cluster access configured. Use 'kubectl' to manage the cluster."
echo "🌐 Production URL will be available after deployment."
