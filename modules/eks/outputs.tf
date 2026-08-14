output "cluster_id" {
  value = aws_eks_cluster.main.id
}

output "cluster_arn" {
  value = aws_eks_cluster.main.arn
}

output "cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "cluster_certificate_authority_data" {
  value = aws_eks_cluster.main.certificate_authority[0].data
}

output "cluster_version" {
  value = aws_eks_cluster.main.version
}

output "cluster_oidc_issuer_url" {
  value = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

output "cluster_security_group_id" {
  value = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "irsa_role_arns" {
  description = "IRSA role ARNs — consumed as env vars by Helmfile"
  value = {
    ebs_csi            = aws_iam_role.ebs_csi.arn
    alb_controller     = aws_iam_role.alb_controller.arn
    vpc_cni            = aws_iam_role.vpc_cni.arn
    karpenter          = aws_iam_role.karpenter.arn
    external_dns       = aws_iam_role.external_dns.arn
    vault              = aws_iam_role.vault.arn
    ack_secretsmanager = aws_iam_role.ack_secretsmanager.arn
    ack_iam            = aws_iam_role.ack_iam.arn
    crossplane         = aws_iam_role.crossplane.arn
  }
}
