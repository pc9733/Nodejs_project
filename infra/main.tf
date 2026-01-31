// Terraform composition:
// 1. Networking layer (VPC, subnets, routing) dedicated to EKS.
// 2. Container registry (ECR) for the Node.js image pushed from CI.
// 3. IAM roles/policies for both the EKS control plane and worker nodes.
// 4. EKS cluster + managed node group hosting the workloads.
provider "aws" {
  region = var.aws_region
}

data "aws_eks_cluster" "practice" {
  name       = aws_eks_cluster.practice.name
  depends_on = [aws_eks_cluster.practice]
}

data "aws_eks_cluster_auth" "practice" {
  name       = aws_eks_cluster.practice.name
  depends_on = [aws_eks_cluster.practice]
}

data "tls_certificate" "eks" {
  url = aws_eks_cluster.practice.identity[0].oidc[0].issuer
}

// provider "kubernetes" {
//   host                   = data.aws_eks_cluster.practice.endpoint
//   cluster_ca_certificate = base64decode(data.aws_eks_cluster.practice.certificate_authority[0].data)
//   token                  = data.aws_eks_cluster_auth.practice.token
// }

// provider "helm" {
//   kubernetes = {
//     host                   = data.aws_eks_cluster.practice.endpoint
//     cluster_ca_certificate = base64decode(data.aws_eks_cluster.practice.certificate_authority[0].data)
//     token                  = data.aws_eks_cluster_auth.practice.token
//   }
// }
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  // Map each requested subnet CIDR to a real AZ by slicing the available list.
  availability_zones = slice(
    data.aws_availability_zones.available.names,
    0,
    length(var.public_subnet_cidrs)
  )
}

// Core networking: VPC with public subnets, IGW, and routing for EKS workers.
resource "aws_vpc" "eks" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.cluster_name}-vpc"
  }
}

// Internet gateway exposes the VPC to the public internet for worker nodes/kubectl.
resource "aws_internet_gateway" "eks" {
  vpc_id = aws_vpc.eks.id

  tags = {
    Name = "${var.cluster_name}-igw"
  }
}

// Public subnets span the selected AZs and auto-assign public IPs to worker nodes.
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.eks.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = local.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                                        = "${var.cluster_name}-public-${count.index + 1}"
    "kubernetes.io/role/elb"                    = "1"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

// Internet route table advertises a default route through the IGW created above.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.eks.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks.id
  }

  tags = {
    Name = "${var.cluster_name}-public-rt"
  }
}

// Bind every subnet to the public route table so nodes can reach the internet.
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

// Container registry that holds the app image referenced by GitHub Actions.
resource "aws_ecr_repository" "practice_node_app" {
  name                 = "practice-node-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "practice-node-app"
  }

  lifecycle {
    ignore_changes = [
      image_tag_mutability,
      image_scanning_configuration
    ]
  }
}

// IAM role assumed by the EKS control plane for AWS API access.
resource "aws_iam_role" "eks_cluster" {
  name = "${var.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster.name
}

// EKS control plane running in the subnets created above.
resource "aws_eks_cluster" "practice" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = aws_subnet.public[*].id
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSVPCResourceController
  ]
}

resource "aws_iam_openid_connect_provider" "eks" {
  url             = aws_eks_cluster.practice.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
}

// IAM role used by worker nodes (EC2) when the node group launches instances.
resource "aws_iam_role" "eks_node_group" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  lifecycle {
    prevent_destroy = true
    ignore_changes = [tags]
  }
}

resource "aws_iam_role_policy_attachment" "eks_node_group_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "eks_node_group_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "eks_node_group_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group.name
}

// IAM role + policy for AWS Load Balancer Controller via IRSA.
data "aws_iam_policy_document" "alb_controller_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values = [
        "system:serviceaccount:kube-system:aws-load-balancer-controller"
      ]
    }
  }
}

resource "aws_iam_role" "alb_controller" {
  name               = "${var.cluster_name}-alb-controller"
  assume_role_policy = data.aws_iam_policy_document.alb_controller_assume_role.json

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_policy" "alb_controller" {
  name   = "${var.cluster_name}-alb-controller-policy"
  policy = file("${path.module}/iam-policy-alb.json")

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  policy_arn = aws_iam_policy.alb_controller.arn
  role       = aws_iam_role.alb_controller.name
}

// resource "kubernetes_service_account_v1" "alb_controller" {
//   metadata {
//     name      = "aws-load-balancer-controller"
//     namespace = "kube-system"
//     labels = {
//       "app.kubernetes.io/name" = "aws-load-balancer-controller"
//     }
//     annotations = {
//       "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller.arn
//     }
//   }
// }

// resource "helm_release" "aws_load_balancer_controller" {
//   name       = "aws-load-balancer-controller"
//   repository = "https://aws.github.io/eks-charts"
//   chart      = "aws-load-balancer-controller"
//   namespace  = "kube-system"
//   version    = "1.10.0"

//   values = [
//     yamlencode({
//       clusterName = aws_eks_cluster.practice.name
//       serviceAccount = {
//         create = false
//         name   = kubernetes_service_account_v1.alb_controller.metadata[0].name
//       }
//       region       = var.aws_region
//       vpcId        = aws_vpc.eks.id
//       enableShield = true
//       enableWaf    = true
//     })
//   ]

//   depends_on = [
//     kubernetes_service_account_v1.alb_controller
//   ]
// }
// Managed node group that provisions EC2 worker nodes of the desired size.
resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.practice.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_group.arn
  subnet_ids      = aws_subnet.public[*].id
  instance_types  = var.node_instance_types
  capacity_type   = "ON_DEMAND"

  scaling_config {
    desired_size = var.node_group_desired_size
    max_size     = var.node_group_max_size
    min_size     = var.node_group_min_size
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_group_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_node_group_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks_node_group_AmazonEC2ContainerRegistryReadOnly
  ]
}
