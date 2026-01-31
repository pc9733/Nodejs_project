# =================================================================
# ECR MODULE OUTPUTS
# =================================================================

output "repository_name" {
  description = "Name of the ECR repository"
  value       = aws_ecr_repository.this.name
}

output "repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.this.repository_url
}

output "repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.this.arn
}

output "repository_registry_id" {
  description = "Registry ID of the ECR repository"
  value       = aws_ecr_repository.this.registry_id
}

output "repository_id" {
  description = "ID of the ECR repository"
  value       = aws_ecr_repository.this.id
}
