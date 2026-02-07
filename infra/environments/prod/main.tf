# =================================================================
# PRODUCTION ENVIRONMENT TERRAFORM CONFIGURATION
# Creates production infrastructure using reusable modules
# =================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket         = "practice-node-app-terraform-state-prod"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "practice-node-app-terraform-locks-prod"
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr               = var.vpc_cidr
  vpc_name               = "${var.project_name}-prod"
  cluster_name           = "${var.project_name}-prod"
  public_subnet_cidrs    = var.public_subnet_cidrs
  private_subnet_cidrs   = var.private_subnet_cidrs
  availability_zones     = var.availability_zones
  enable_nat_gateway     = var.enable_nat_gateway

  tags = merge(
    {
      Environment = "production"
      Project     = var.project_name
    },
    var.tags
  )
}

# ECR Module
module "ecr" {
  source = "../../modules/ecr"

  repository_name       = "${var.project_name}-prod"
  image_tag_mutability  = "IMMUTABLE"  # Immutable for prod
  scan_on_push          = true
  encryption_type       = "KMS"
  kms_key               = aws_kms_key.ecr_key.arn
  enable_lifecycle_policy = true
  enable_registry_scanning = true
  registry_scan_type    = "ENHANCED"
  scan_frequency        = "CONTINUOUS_SCAN"

  tags = merge(
    {
      Environment = "production"
      Project     = var.project_name
    },
    var.tags
  )
}

# KMS Key for ECR
resource "aws_kms_key" "ecr_key" {
  description             = "ECR encryption key for production"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow ECR to use the key"
        Effect = "Allow"
        Principal = {
          Service = "ecr.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    {
      Name = "${var.project_name}-prod-ecr-key"
      Environment = "production"
    },
    var.tags
  )
}

# EKS Module
module "eks" {
  source = "../../modules/eks"

  cluster_name                 = "${var.project_name}-prod"
  kubernetes_version          = var.kubernetes_version
  subnet_ids                  = concat(module.vpc.public_subnet_ids, module.vpc.private_subnet_ids)
  endpoint_public_access      = var.endpoint_public_access
  endpoint_private_access     = true
  public_access_cidrs         = var.public_access_cidrs
  service_ipv4_cidr           = "172.21.0.0/16"
  encryption_resources        = ["secrets", "configmaps"]
  enabled_cluster_log_types   = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  
  # Larger node group for prod
  desired_size                = 3
  max_size                    = 6
  min_size                    = 2
  instance_types              = ["t3.medium", "t3.large"]
  ami_type                    = "AL2_x86_64"
  capacity_type               = "ON_DEMAND"
  disk_size                   = 50
  max_unavailable_percentage = 33
  
  enable_alb_controller       = true
  alb_controller_version      = "3.0.0"

  tags = merge(
    {
      Environment = "production"
      Project     = var.project_name
    },
    var.tags
  )
}

# CloudWatch Log Group for EKS
resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.project_name}-prod/cluster"
  retention_in_days = 30

  tags = merge(
    {
      Environment = "production"
      Project     = var.project_name
    },
    var.tags
  )
}

# Data source for current account
data "aws_caller_identity" "current" {}
