output "ecr_repository_url" {
  description = "URL of the ECR repository hosting the practice-node-app image."
  value       = aws_ecr_repository.practice_node_app.repository_url
}

output "cluster_name" {
  description = "Name of the provisioned EKS cluster."
  value       = aws_eks_cluster.practice.name
}

output "cluster_endpoint" {
  description = "Endpoint used to connect to the EKS cluster."
  value       = aws_eks_cluster.practice.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Certificate authority data required for kubeconfig."
  value       = aws_eks_cluster.practice.certificate_authority[0].data
}

output "public_subnet_ids" {
  description = "Identifiers for the public subnets used by the cluster."
  value       = aws_subnet.public[*].id
}
