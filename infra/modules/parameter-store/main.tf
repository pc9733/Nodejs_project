# =================================================================
# AWS SYSTEMS MANAGER PARAMETER STORE MODULE
# Creates secure parameters for application secrets
# =================================================================

# Dev Environment Secrets
resource "aws_ssm_parameter" "dev_db_password" {
  count = var.environment == "dev" ? 1 : 0

  name        = "/${var.cluster_name}/dev/db-password"
  description = "Database password for development environment"
  type        = "SecureString"
  value       = var.dev_db_password
  tier        = "Standard"

  tags = merge(
    {
      Name        = "${var.cluster_name}-dev-db-password"
      Environment = "development"
    },
    var.tags
  )
}

resource "aws_ssm_parameter" "dev_api_key" {
  count = var.environment == "dev" ? 1 : 0

  name        = "/${var.cluster_name}/dev/api-key"
  description = "API key for development environment"
  type        = "SecureString"
  value       = var.dev_api_key
  tier        = "Standard"

  tags = merge(
    {
      Name        = "${var.cluster_name}-dev-api-key"
      Environment = "development"
    },
    var.tags
  )
}

resource "aws_ssm_parameter" "dev_jwt_secret" {
  count = var.environment == "dev" ? 1 : 0

  name        = "/${var.cluster_name}/dev/jwt-secret"
  description = "JWT secret for development environment"
  type        = "SecureString"
  value       = var.dev_jwt_secret
  tier        = "Standard"

  tags = merge(
    {
      Name        = "${var.cluster_name}-dev-jwt-secret"
      Environment = "development"
    },
    var.tags
  )
}

# Production Environment Secrets
resource "aws_ssm_parameter" "prod_db_password" {
  count = var.environment == "prod" ? 1 : 0

  name        = "/${var.cluster_name}/prod/db-password"
  description = "Database password for production environment"
  type        = "SecureString"
  value       = var.prod_db_password
  tier        = "Standard"

  tags = merge(
    {
      Name        = "${var.cluster_name}-prod-db-password"
      Environment = "production"
    },
    var.tags
  )
}

resource "aws_ssm_parameter" "prod_api_key" {
  count = var.environment == "prod" ? 1 : 0

  name        = "/${var.cluster_name}/prod/api-key"
  description = "API key for production environment"
  type        = "SecureString"
  value       = var.prod_api_key
  tier        = "Standard"

  tags = merge(
    {
      Name        = "${var.cluster_name}-prod-api-key"
      Environment = "production"
    },
    var.tags
  )
}

resource "aws_ssm_parameter" "prod_jwt_secret" {
  count = var.environment == "prod" ? 1 : 0

  name        = "/${var.cluster_name}/prod/jwt-secret"
  description = "JWT secret for production environment"
  type        = "SecureString"
  value       = var.prod_jwt_secret
  tier        = "Standard"

  tags = merge(
    {
      Name        = "${var.cluster_name}-prod-jwt-secret"
      Environment = "production"
    },
    var.tags
  )
}

# Datadog API Key (shared across environments)
resource "aws_ssm_parameter" "datadog_api_key" {
  count = var.datadog_api_key != "" ? 1 : 0

  name        = "/${var.cluster_name}/${var.environment}/datadog-api-key"
  description = "Datadog API key for monitoring"
  type        = "SecureString"
  value       = var.datadog_api_key
  tier        = "Standard"

  tags = merge(
    {
      Name        = "${var.cluster_name}-${var.environment}-datadog-api-key"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_ssm_parameter" "datadog_app_key" {
  count = var.datadog_app_key != "" ? 1 : 0

  name        = "/${var.cluster_name}/${var.environment}/datadog-app-key"
  description = "Datadog application key for monitoring"
  type        = "SecureString"
  value       = var.datadog_app_key
  tier        = "Standard"

  tags = merge(
    {
      Name        = "${var.cluster_name}-${var.environment}-datadog-app-key"
      Environment = var.environment
    },
    var.tags
  )
}
