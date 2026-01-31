# =================================================================
# ECR MODULE VARIABLES
# =================================================================

variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
}

variable "image_tag_mutability" {
  description = "Image tag mutability setting"
  type        = string
  default     = "MUTABLE"
  
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "Image tag mutability must be either MUTABLE or IMMUTABLE."
  }
}

variable "scan_on_push" {
  description = "Whether to scan images on push"
  type        = bool
  default     = true
}

variable "encryption_type" {
  description = "Encryption type for the repository"
  type        = string
  default     = "AES256"
  
  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "Encryption type must be either AES256 or KMS."
  }
}

variable "kms_key" {
  description = "KMS key for encryption (only if encryption_type is KMS)"
  type        = string
  default     = null
}

variable "repository_policy" {
  description = "Repository policy document"
  type        = string
  default     = null
}

variable "enable_lifecycle_policy" {
  description = "Whether to enable lifecycle policy"
  type        = bool
  default     = true
}

variable "lifecycle_policy" {
  description = "Lifecycle policy document"
  type        = string
  default = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep untagged images for 7 days"
        selection = {
          tagStatus = "untagged"
          countType = "sinceImagePushed"
          countUnit = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

variable "enable_registry_scanning" {
  description = "Whether to enable registry scanning configuration"
  type        = bool
  default     = false
}

variable "registry_scan_type" {
  description = "Registry scan type"
  type        = string
  default     = "ENHANCED"
  
  validation {
    condition     = contains(["BASIC", "ENHANCED"], var.registry_scan_type)
    error_message = "Registry scan type must be either BASIC or ENHANCED."
  }
}

variable "scan_frequency" {
  description = "Scan frequency for registry scanning"
  type        = string
  default     = "SCAN_ON_PUSH"
  
  validation {
    condition     = contains(["CONTINUOUS_SCAN", "SCAN_ON_PUSH", "MANUAL"], var.scan_frequency)
    error_message = "Scan frequency must be one of CONTINUOUS_SCAN, SCAN_ON_PUSH, or MANUAL."
  }
}

variable "tag_status" {
  description = "Tag status for registry scanning"
  type        = string
  default     = "ANY"
  
  validation {
    condition     = contains(["TAGGED", "UNTAGGED", "ANY"], var.tag_status)
    error_message = "Tag status must be one of TAGGED, UNTAGGED, or ANY."
  }
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
