output "ecr_repository_url" {
  description = "URL of the ECR repository hosting the practice-node-app image."
  value       = aws_ecr_repository.practice_node_app.repository_url
}
