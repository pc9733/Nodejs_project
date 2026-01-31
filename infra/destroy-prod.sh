#!/bin/bash
# =================================================================
# DESTROY PRODUCTION ENVIRONMENT
# Safely destroys production infrastructure
# =================================================================

set -e

echo "🔥 Destroying Production Environment..."

# Check if we're in the right directory
if [ ! -d "environments/prod" ]; then
    echo "❌ Error: Please run this script from the infra/ directory"
    exit 1
fi

# Safety check for production
echo "⚠️  WARNING: This will destroy the PRODUCTION environment!"
echo "🔒 Type 'destroy-production' to confirm:"
read -r confirmation
if [ "$confirmation" != "destroy-production" ]; then
    echo "❌ Destruction cancelled. Confirmation not provided."
    exit 1
fi

# Delete Kubernetes resources first (if cluster exists)
if aws eks describe-cluster --name practice-node-app-prod --region us-east-1 2>/dev/null; then
    echo "🗑️  Deleting Kubernetes resources..."
    aws eks update-kubeconfig --name practice-node-app-prod --region us-east-1 2>/dev/null || true
    
    # Delete all resources in prod namespace
    kubectl delete namespace practice-app-prod --ignore-not-found=true || true
    
    # Delete ALB controller
    kubectl delete serviceaccount aws-load-balancer-controller -n kube-system --ignore-not-found=true || true
    helm uninstall aws-load-balancer-controller -n kube-system --ignore-not-found=true || true
fi

# Go to prod environment directory
cd environments/prod

# Remove from Terraform state (preserves IAM resources)
echo "🗑️  Removing resources from Terraform state..."
terraform state rm 'module.eks.aws_eks_cluster.this' 2>/dev/null || true
terraform state rm 'module.eks.aws_eks_node_group.this' 2>/dev/null || true
terraform state rm 'module.eks.aws_iam_oidc_provider.eks' 2>/dev/null || true
terraform state rm 'module.eks.helm_release.aws_load_balancer_controller[0]' 2>/dev/null || true
terraform state rm 'module.eks.aws_iam_role.alb_controller[0]' 2>/dev/null || true
terraform state rm 'module.eks.aws_iam_role_policy_attachment.alb_controller_policy[0]' 2>/dev/null || true

# Delete EKS resources
echo "🗑️  Deleting EKS resources..."
aws eks delete-nodegroup --cluster-name practice-node-app-prod --nodegroup-name practice-node-app-prod-node-group --region us-east-1 2>/dev/null || true
echo "⏳ Waiting for nodegroup deletion..."
aws eks wait nodegroup-deleted --cluster-name practice-node-app-prod --nodegroup-name practice-node-app-prod-node-group --region us-east-1 2>/dev/null || true

aws eks delete-cluster --name practice-node-app-prod --region us-east-1 2>/dev/null || true
echo "⏳ Waiting for cluster deletion..."
aws eks wait cluster-deleted --cluster-name practice-node-app-prod --region us-east-1 2>/dev/null || true

# Destroy remaining infrastructure
echo "🗑️  Destroying remaining infrastructure..."
terraform destroy -auto-approve

# Clean up S3 bucket and DynamoDB table
echo "🗑️  Cleaning up state management..."
aws s3 rb "s3://practice-node-app-terraform-state-prod" --force || true
aws dynamodb delete-table --table-name practice-node-app-terraform-locks-prod --region us-east-1 || true

echo "✅ Production environment destroyed successfully!"
