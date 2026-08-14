# Exports consumed by Helmfile (ARNs, IDs, etc.)

output "vpc_id" {
  value = var.create_vpc ? module.vpc[0].vpc_id : null
}

output "private_subnet_ids" {
  value = var.create_vpc ? module.vpc[0].private_subnet_ids : null
}

output "public_subnet_ids" {
  value = var.create_vpc ? module.vpc[0].public_subnet_ids : null
}

output "cluster_id" {
  value = var.create_eks ? module.eks[0].cluster_id : null
}

output "cluster_endpoint" {
  value = var.create_eks ? module.eks[0].cluster_endpoint : null
}

output "cluster_certificate_authority_data" {
  value = var.create_eks ? module.eks[0].cluster_certificate_authority_data : null
}

output "cluster_oidc_issuer_url" {
  value = var.create_eks ? module.eks[0].cluster_oidc_issuer_url : null
}

output "irsa_role_arns" {
  description = "IRSA role ARNs — consumed as env vars by Helmfile"
  value       = var.create_eks ? module.eks[0].irsa_role_arns : null
}
