#!/bin/bash

set -e

echo "🔥 Automated infrastructure cleanup..."

# Remove from Terraform state (preserves IAM resources)
terraform state rm aws_eks_cluster.practice aws_eks_node_group.default aws_iam_openid_connect_provider.eks aws_route_table_association.public aws_route_table.public aws_internet_gateway.eks aws_subnet.public aws_vpc.eks aws_ecr_repository.practice_node_app aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy aws_iam_role_policy_attachment.eks_cluster_AmazonEKSVPCResourceController aws_iam_role_policy_attachment.eks_node_group_AmazonEKSWorkerNodePolicy aws_iam_role_policy_attachment.eks_node_group_AmazonEKS_CNI_Policy aws_iam_role_policy_attachment.eks_node_group_AmazonEC2ContainerRegistryReadOnly aws_iam_role_policy_attachment.alb_controller kubernetes_service_account_v1.alb_controller helm_release.aws_load_balancer_controller 2>/dev/null || true

# Delete Kubernetes resources first (if cluster exists)
if aws eks describe-cluster --name practice-node-app --region us-east-1 2>/dev/null; then
    echo "🗑️  Deleting Kubernetes resources..."
    aws eks update-kubeconfig --name practice-node-app --region us-east-1 2>/dev/null || true
    kubectl delete ingress practice-node-app -n practice-app 2>/dev/null || true
    kubectl delete service practice-node-app -n practice-app 2>/dev/null || true
    kubectl delete deployment practice-node-app -n practice-app 2>/dev/null || true
    kubectl delete namespace practice-app 2>/dev/null || true
    kubectl delete serviceaccount aws-load-balancer-controller -n kube-system 2>/dev/null || true
    helm uninstall aws-load-balancer-controller -n kube-system 2>/dev/null || true
fi

# Delete EKS resources
aws eks delete-nodegroup --cluster-name practice-node-app --nodegroup-name practice-node-app-node-group --region us-east-1 2>/dev/null || true
echo "⏳ Waiting for nodegroup deletion..."
aws eks wait nodegroup-deleted --cluster-name practice-node-app --nodegroup-name practice-node-app-node-group --region us-east-1 2>/dev/null || true

aws eks delete-cluster --name practice-node-app --region us-east-1 2>/dev/null || true
echo "⏳ Waiting for cluster deletion..."
aws eks wait cluster-deleted --name practice-node-app --region us-east-1 2>/dev/null || true

# Delete VPC resources
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=practice-node-app-vpc" --query "Vpcs[0].VpcId" --output text --region us-east-1 2>/dev/null || echo "")
if [ "$VPC_ID" != "None" ] && [ -n "$VPC_ID" ]; then
    # Delete IGW
    IGW_ID=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query "InternetGateways[0].InternetGatewayId" --output text --region us-east-1 2>/dev/null || echo "")
    if [ "$IGW_ID" != "None" ] && [ -n "$IGW_ID" ]; then
        aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID --region us-east-1
        aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID --region us-east-1
    fi
    
    # Delete subnets
    SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[].SubnetId" --output text --region us-east-1 2>/dev/null || echo "")
    for SUBNET_ID in $SUBNET_IDS; do
        aws ec2 delete-subnet --subnet-id $SUBNET_ID --region us-east-1 2>/dev/null || true
    done
    
    # Delete VPC
    aws ec2 delete-vpc --vpc-id $VPC_ID --region us-east-1 2>/dev/null || true
fi

# Delete ECR repository
aws ecr delete-repository --repository-name practice-node-app --force --region us-east-1 2>/dev/null || true

echo "🎉 Cleanup completed! IAM resources preserved."
