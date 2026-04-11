# =================================================================
# PARAMETER STORE MODULE VARIABLES
# =================================================================

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be either 'dev' or 'prod'."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# Dev Environment Variables
variable "dev_db_password" {
  description = "Database password for development environment"
  type        = string
  default     = ""
  sensitive   = true
}

variable "dev_api_key" {
  description = "API key for development environment"
  type        = string
  default     = ""
  sensitive   = true
}

variable "dev_jwt_secret" {
  description = "JWT secret for development environment"
  type        = string
  default     = ""
  sensitive   = true
}

# Production Environment Variables
variable "prod_db_password" {
  description = "Database password for production environment"
  type        = string
  default     = ""
  sensitive   = true
}

variable "prod_api_key" {
  description = "API key for production environment"
  type        = string
  default     = ""
  sensitive   = true
}

variable "prod_jwt_secret" {
  description = "JWT secret for production environment"
  type        = string
  default     = ""
  sensitive   = true
}

# Datadog Secrets
variable "datadog_api_key" {
  description = "Datadog API key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "datadog_app_key" {
  description = "Datadog application key"
  type        = string
  default     = ""
  sensitive   = true
}
