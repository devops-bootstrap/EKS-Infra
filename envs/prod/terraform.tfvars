region              = "us-east-1"
environment         = "prod"
eks_cluster_name    = "prod-eks-cluster"
eks_cluster_version = "1.34"

cidr_block           = "10.1.0.0/16"
private_subnet_cidrs = ["10.1.0.0/19", "10.1.32.0/19", "10.1.64.0/19"]
public_subnet_cidrs  = ["10.1.96.0/19", "10.1.128.0/19", "10.1.160.0/19"]

eks_cluster_endpoint_private_access = true
eks_cluster_endpoint_public_access  = false

eks_node_group_ami_type       = "BOTTLEROCKET_x86_64"
eks_node_group_instance_types = ["m5.large"]
eks_node_group_desired_size   = 3
eks_node_group_min_size       = 3
eks_node_group_max_size       = 10

vpc_endpoint_services = [
  "com.amazonaws.us-east-1.s3",
  "com.amazonaws.us-east-1.dynamodb"
]

addon_versions = {
  ebs_csi = null
  efs_csi = null
}

default_tags = {
  Environment = "prod"
  Owner       = "PlatformTeam"
  ManagedBy   = "Terraform"
}
