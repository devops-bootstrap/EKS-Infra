# Root module: wires all child modules together

locals {
  vpc_id     = var.create_vpc ? module.vpc[0].vpc_id : var.existing_vpc_id
  subnet_ids = var.create_vpc ? module.vpc[0].public_subnet_ids : var.existing_subnet_ids
}

module "vpc" {
  count  = var.create_vpc ? 1 : 0
  source = "./modules/vpc"

  cidr_block            = var.cidr_block
  private_subnet_cidrs  = var.private_subnet_cidrs
  public_subnet_cidrs   = var.public_subnet_cidrs
  environment           = var.environment
  vpc_endpoint_services = var.vpc_endpoint_services
}

module "eks" {
  count  = var.create_eks ? 1 : 0
  source = "./modules/eks"

  eks_cluster_name                         = var.eks_cluster_name
  eks_cluster_version                      = var.eks_cluster_version
  eks_cluster_service_ipv4_cidr            = var.eks_cluster_service_ipv4_cidr
  eks_cluster_endpoint_private_access      = var.eks_cluster_endpoint_private_access
  eks_cluster_endpoint_public_access       = var.eks_cluster_endpoint_public_access
  eks_cluster_endpoint_public_access_cidrs = var.eks_cluster_endpoint_public_access_cidrs
  subnet_ids                               = local.subnet_ids
  eks_node_group_ami_type                  = var.eks_node_group_ami_type
  eks_node_group_instance_types            = var.eks_node_group_instance_types
  eks_node_group_desired_size              = var.eks_node_group_desired_size
  eks_node_group_min_size                  = var.eks_node_group_min_size
  eks_node_group_max_size                  = var.eks_node_group_max_size
  environment                              = var.environment
  addon_versions                           = var.addon_versions

  depends_on = [module.vpc]
}

module "supporting" {
  count  = var.create_eks ? 1 : 0
  source = "./modules/supporting"

  eks_cluster_name = var.eks_cluster_name
  vpc_id           = local.vpc_id
  environment      = var.environment

  depends_on = [module.vpc, module.eks]
}
