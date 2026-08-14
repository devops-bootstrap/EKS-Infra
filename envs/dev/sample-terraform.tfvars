create_vpc = true
create_eks = true

# Uncomment and set these when create_vpc = false
# existing_vpc_id     = "vpc-xxxxxxxxxxxxxxxxx"
# existing_subnet_ids = ["subnet-xxxxxxxxxxxxxxxxx", "subnet-yyyyyyyyyyyyyyyyy"]

region              = "us-east-1"
environment         = "dev"
eks_cluster_name    = "peeks-spoke-test"
eks_cluster_version = "1.34"

cidr_block           = "10.0.0.0/16"
private_subnet_cidrs = ["10.0.0.0/19", "10.0.32.0/19", "10.0.64.0/19"]
public_subnet_cidrs  = ["10.0.96.0/19", "10.0.128.0/19", "10.0.160.0/19"]

eks_cluster_endpoint_private_access = true
eks_cluster_endpoint_public_access  = true

eks_node_group_ami_type       = "BOTTLEROCKET_x86_64"
eks_node_group_instance_types = ["t3.medium"]
eks_node_group_desired_size   = 4
eks_node_group_min_size       = 4
eks_node_group_max_size       = 4

vpc_endpoint_services = [
  "com.amazonaws.us-east-1.s3",
  "com.amazonaws.us-east-1.dynamodb"
]

addon_versions = {
  ebs_csi = null
}

default_tags = {
  Environment = "dev"
  Owner       = "PlatformTeam"
  ManagedBy   = "Terraform"
}
