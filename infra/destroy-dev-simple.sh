#!/bin/bash
# =================================================================
# DESTROY DEVELOPMENT ENVIRONMENT
# =================================================================

set -e

echo "🔥 Destroying DEVELOPMENT Environment..."

# Check if we're in the right directory
if [ ! -d "environments/dev" ]; then
    echo "❌ Error: Please run this script from the infra/ directory"
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="us-east-1"
CLUSTER_NAME="practice-node-app-dev"
NAMESPACE="practice-app-dev"

# Step 1 — delete K8s Ingresses/Services so the ALB controller removes ALBs gracefully.
echo "🧹 Removing Kubernetes Ingresses and LoadBalancer services..."
if aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$AWS_REGION" 2>/dev/null; then
    kubectl delete ingress --all -n "$NAMESPACE" --ignore-not-found 2>/dev/null || true
    kubectl delete service --all -n "$NAMESPACE" --ignore-not-found 2>/dev/null || true
    echo "⏳ Waiting 60s for ALB controller to delete load balancers..."
    sleep 60
else
    echo "⚠️  Cluster unreachable (may already be gone) — falling back to AWS CLI cleanup..."
fi

# Step 2 — AWS CLI fallback: find and delete any ALBs/NLBs still in the VPC.
# Covers the case where the cluster is gone but the ALBs are still alive
# (which would block subnet/IGW destruction for 10+ minutes).
echo "🔍 Checking for leftover load balancers in the VPC..."
VPC_ID=$(aws ec2 describe-vpcs --region "$AWS_REGION" \
    --filters "Name=tag:Name,Values=${CLUSTER_NAME}-vpc" \
    --query 'Vpcs[0].VpcId' --output text 2>/dev/null || echo "")

if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then
    LB_ARNS=$(aws elbv2 describe-load-balancers --region "$AWS_REGION" \
        --query "LoadBalancers[?VpcId=='${VPC_ID}'].LoadBalancerArn" \
        --output text 2>/dev/null || echo "")

    if [ -n "$LB_ARNS" ]; then
        echo "Found load balancers — deleting..."
        for ARN in $LB_ARNS; do
            aws elbv2 delete-load-balancer --load-balancer-arn "$ARN" --region "$AWS_REGION"
            echo "  Deleted: $ARN"
        done
        echo "⏳ Waiting 60s for AWS to release load balancer ENIs..."
        sleep 60
    else
        echo "No leftover load balancers found."
    fi
else
    echo "VPC not found — already destroyed or never created."
fi

# Go to dev environment directory
cd environments/dev

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Destroy infrastructure
echo "🗑️  Destroying infrastructure..."
terraform destroy -auto-approve

# Clean up state management (account-ID-qualified names match what setup-dev.sh created)
echo "🗑️  Cleaning up state management..."
aws s3 rb "s3://practice-node-app-terraform-state-${ACCOUNT_ID}-dev" --force 2>/dev/null || true
aws dynamodb delete-table \
    --table-name "practice-node-app-terraform-locks-${ACCOUNT_ID}-dev" \
    --region "$AWS_REGION" 2>/dev/null || true

echo "✅ Development environment destroyed successfully!"
