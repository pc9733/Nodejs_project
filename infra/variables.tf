variable "aws_region" {
  description = "AWS region where infrastructure is created."
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name for the EKS cluster and related resources."
  type        = string
  default     = "practice-node-app"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC that hosts the EKS cluster."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets used by the EKS cluster."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "node_group_desired_size" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 2
}

variable "node_group_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 2
}

variable "node_group_max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 4
}

variable "node_instance_types" {
  description = "EC2 instance types used by the EKS node group."
  type        = list(string)
  default     = ["t3.small"]
}
