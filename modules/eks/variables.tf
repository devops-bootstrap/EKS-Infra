variable "eks_cluster_name" {
  type = string
}

variable "eks_cluster_version" {
  type = string
}

variable "eks_cluster_service_ipv4_cidr" {
  type = string
}

variable "eks_cluster_endpoint_private_access" {
  type = bool
}

variable "eks_cluster_endpoint_public_access" {
  type = bool
}

variable "eks_cluster_endpoint_public_access_cidrs" {
  type = list(string)
}

variable "subnet_ids" {
  type = list(string)
}

variable "eks_node_group_ami_type" {
  type = string
}

variable "eks_node_group_instance_types" {
  type = list(string)
}

variable "eks_node_group_desired_size" {
  type = number
}

variable "eks_node_group_min_size" {
  type = number
}

variable "eks_node_group_max_size" {
  type = number
}

variable "environment" {
  type = string
}

variable "addon_versions" {
  type = object({
    ebs_csi = optional(string)
  })
}
