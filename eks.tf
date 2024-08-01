module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.20.0"

  cluster_name    = var.eks_cluster_name
  cluster_version = var.eks_cluster_version

  cluster_endpoint_public_access  = false
  cluster_endpoint_private_access = true

  enable_kms_key_rotation = true
  kms_key_description     = "KMS key for OpsFleet EKS cluster"

  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    coredns = {
      addon_version = var.cluster_addons_versions.coredns
    }
    kube-proxy = {
      addon_version = var.cluster_addons_versions.kube-proxy
    }
    vpc-cni = {
      addon_version  = var.cluster_addons_versions.vpc-cni
      before_compute = true
    }
  }

  vpc_id                   = var.vpc_id
  subnet_ids               = var.eks_subnets
  control_plane_subnet_ids = var.eks_subnets

  cluster_additional_security_group_ids = [
    aws_security_group.eks.id
  ]

  eks_managed_node_groups = {
    eks-main = {
      min_size     = 1
      max_size     = 10
      desired_size = 1

      taints = {
        dedicated = {
          key    = "Dedicated"
          value  = "karpenter-controller"
          effect = "NO_SCHEDULE"
        }
      }
    }
  }
}

resource "aws_security_group" "eks" {
  name        = "eks"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for EKS"

  # VPC
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = var.allowed_sg
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks"
  }
}
