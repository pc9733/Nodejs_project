# =================================================================
# PARAMETER STORE - Development Environment
# Creates encrypted parameters in AWS Systems Manager Parameter Store
# =================================================================

# Development API Key
resource "aws_ssm_parameter" "dev_api_key" {
  name        = "/practice-node-app-dev/dev/api-key"
  description = "API key for development environment"
  type        = "SecureString"
  value       = var.dev_api_key != "" ? var.dev_api_key : "CHANGEME-dev-api-key-secret"
  overwrite   = true

  tags = {
    Name        = "practice-node-app-dev-api-key"
    Environment = "development"
  }

  lifecycle {
    ignore_changes = [value]
  }
}

# Development JWT Secret
resource "aws_ssm_parameter" "dev_jwt_secret" {
  name        = "/practice-node-app-dev/dev/jwt-secret"
  description = "JWT secret for development environment"
  type        = "SecureString"
  value       = var.dev_jwt_secret != "" ? var.dev_jwt_secret : "CHANGEME-dev-jwt-secret-key"
  overwrite   = true

  tags = {
    Name        = "practice-node-app-dev-jwt-secret"
    Environment = "development"
  }

  lifecycle {
    ignore_changes = [value]
  }
}


# Outputs
output "parameter_store_paths" {
  description = "Parameter Store paths created"
  value = {
    api_key    = aws_ssm_parameter.dev_api_key.name
    jwt_secret = aws_ssm_parameter.dev_jwt_secret.name
  }
}
