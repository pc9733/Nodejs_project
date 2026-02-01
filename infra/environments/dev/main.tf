# =================================================================
# DEVELOPMENT ENVIRONMENT TERRAFORM CONFIGURATION
# Creates development infrastructure using reusable modules
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
    bucket         = "practice-node-app-terraform-state-dev"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "practice-node-app-terraform-locks-dev"
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr               = var.vpc_cidr
  vpc_name               = "${var.project_name}-dev"
  cluster_name           = "${var.project_name}-dev"
  public_subnet_cidrs    = var.public_subnet_cidrs
  private_subnet_cidrs   = var.private_subnet_cidrs
  availability_zones     = var.availability_zones
  enable_nat_gateway     = var.enable_nat_gateway

  tags = merge(
    {
      Environment = "development"
      Project     = var.project_name
    },
    var.tags
  )
}

# ECR Module
module "ecr" {
  source = "../../modules/ecr"

  repository_name       = "${var.project_name}-dev"
  image_tag_mutability  = "MUTABLE"
  scan_on_push          = true
  encryption_type       = "AES256"
  enable_lifecycle_policy = true

  tags = merge(
    {
      Environment = "development"
      Project     = var.project_name
    },
    var.tags
  )
}

# EKS Module
module "eks" {
  source = "../../modules/eks"

  cluster_name                 = "${var.project_name}-dev"
  kubernetes_version          = var.kubernetes_version
  subnet_ids                  = module.vpc.public_subnet_ids
  endpoint_public_access      = true
  endpoint_private_access     = true
  public_access_cidrs         = ["0.0.0.0/0"]
  service_ipv4_cidr           = "172.20.0.0/16"
  encryption_resources        = ["secrets"]
  enabled_cluster_log_types   = ["api", "audit"]
  
  # Smaller node group for dev
  desired_size                = 1
  max_size                    = 2
  min_size                    = 1
  instance_types              = ["t3.small"]
  ami_type                    = "AL2_x86_64"
  capacity_type               = "ON_DEMAND"
  disk_size                   = 20
  max_unavailable_percentage = 50
  
  enable_alb_controller       = true
  alb_controller_version      = "3.0.0"

  tags = merge(
    {
      Environment = "development"
      Project     = var.project_name
    },
    var.tags
  )
}
