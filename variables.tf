variable "create_vpc" {
  type        = bool
  description = "Whether to provision the VPC module"
  default     = true
}

variable "create_eks" {
  type        = bool
  description = "Whether to provision the EKS module (and supporting module)"
  default     = true
}

# Used when create_vpc = false and create_eks = true
variable "existing_vpc_id" {
  type        = string
  description = "Existing VPC ID to use when create_vpc = false"
  default     = ""
}

variable "existing_subnet_ids" {
  type        = list(string)
  description = "Existing subnet IDs to use when create_vpc = false"
  default     = []
}

variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
  default     = "dev"
}

variable "eks_cluster_name" {
  type        = string
  description = "EKS Cluster name"
  default     = "my-eks-cluster"
}

variable "eks_cluster_version" {
  type        = string
  description = "Kubernetes version for the EKS cluster"
  default     = "1.34"
}

variable "default_tags" {
  type        = map(string)
  description = "Base tags to apply to all resources"
  default = {
    Environment = "Test"
    Owner       = "PlatformTeam"
  }
}

# VPC
variable "cidr_block" {
  type        = string
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private subnet CIDRs"
  default     = ["10.0.0.0/19", "10.0.32.0/19", "10.0.64.0/19"]
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public subnet CIDRs"
  default     = ["10.0.96.0/19", "10.0.128.0/19", "10.0.160.0/19"]
}

# EKS
variable "eks_cluster_endpoint_private_access" {
  type    = bool
  default = true
}

variable "eks_cluster_endpoint_public_access" {
  type    = bool
  default = true
}

variable "eks_cluster_endpoint_public_access_cidrs" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "eks_cluster_service_ipv4_cidr" {
  type    = string
  default = "172.20.0.0/16"
}

variable "eks_node_group_ami_type" {
  type    = string
  default = "BOTTLEROCKET_x86_64"
}

variable "eks_node_group_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "eks_node_group_desired_size" {
  type    = number
  default = 3
}

variable "eks_node_group_min_size" {
  type    = number
  default = 3
}

variable "eks_node_group_max_size" {
  type    = number
  default = 5
}

variable "vpc_endpoint_services" {
  type        = list(string)
  description = "VPC Gateway Endpoint services"
  default     = ["com.amazonaws.us-east-1.s3", "com.amazonaws.us-east-1.dynamodb"]
}

variable "addon_versions" {
  type = object({
    ebs_csi = optional(string)
    efs_csi = optional(string)
  })
  default = {
    ebs_csi = null
    efs_csi = null
  }
}
