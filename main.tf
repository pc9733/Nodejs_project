provider "aws" {
  region = "us-east-1"
}

variable "environment" {
  description = "Environment name used to influence instance sizing."
  type        = string
  default     = "dev"
}

variable "include_dev" {
  description = "Whether a dev instance should be created alongside prod."
  type        = bool
  default     = true
}

variable "egress_rules" {
  description = "Egress firewall rules configured through a dynamic block."
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      description = "Allow all egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

locals {
  base_names     = toset(["prd-1"])
  instance_names = var.include_dev ? toset(["prd-1", "dev-1"]) : local.base_names
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "dynamic" {
  name        = "practice-dynamic"
  description = "Security group managed via dynamic blocks"
  vpc_id      = data.aws_vpc.default.id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = var.egress_rules
    content {
      description = egress.value.description
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }

  tags = {
    Name = "practice-dynamic"
  }
}

resource "aws_instance" "practice" {
  for_each               = local.instance_names
  instance_type          = var.environment == "prod" ? "t3.medium" : "t3.micro"
  ami                    = "ami-0ad50334604831820"
  key_name               = "new"
  vpc_security_group_ids = [aws_security_group.dynamic.id]

  tags = {
    Name = each.key
  }
}
