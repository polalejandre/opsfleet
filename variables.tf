variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}

variable "eks_cluster_name" {
  description = "The EKS cluster name"
  type        = string
}

variable "eks_cluster_version" {
  description = "The EKS cluster version"
  type        = string
}

variable "eks_subnets" {
  description = "The EKS subnets"
  type        = list(string)
}

variable "allowed_sg" {
  description = "The allowed Security Groups"
  type        = list(string)
}
