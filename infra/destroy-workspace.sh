#!/bin/bash

# Safe destroy workflow that preserves IAM resources
echo "Starting safe destroy workflow..."

# First, destroy Kubernetes resources
echo "Destroying Kubernetes resources..."
terraform destroy -target=helm_release.aws_load_balancer_controller -auto-approve
terraform destroy -target=kubernetes_service_account_v1.alb_controller -auto-approve

# Then destroy EKS resources
echo "Destroying EKS resources..."
terraform destroy -target=aws_eks_node_group.default -auto-approve
terraform destroy -target=aws_eks_cluster.practice -auto-approve

# Finally destroy networking and other resources
echo "Destroying networking resources..."
terraform destroy -target=aws_route_table_association.public -auto-approve
terraform destroy -target=aws_route_table.public -auto-approve
terraform destroy -target=aws_internet_gateway.eks -auto-approve
terraform destroy -target=aws_subnet.public -auto-approve
terraform destroy -target=aws_vpc.eks -auto-approve

# IAM resources are protected and won't be destroyed
echo "Destroy completed. IAM resources preserved for next deployment."
