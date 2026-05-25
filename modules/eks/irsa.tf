# One IAM role per controller (least-privilege)

locals {
  oidc_issuer = trimprefix(aws_eks_cluster.main.identity[0].oidc[0].issuer, "https://")
  oidc_arn    = aws_iam_openid_connect_provider.cluster.arn

  irsa_roles = {
    ebs_csi            = { ns = "kube-system", sa = "ebs-csi-controller-sa" }
    alb_controller     = { ns = "kube-system", sa = "aws-load-balancer-controller" }
    vpc_cni            = { ns = "kube-system", sa = "aws-node" }
    karpenter          = { ns = "kube-system", sa = "karpenter" }
    external_dns       = { ns = "external-dns", sa = "external-dns" }
    vault              = { ns = "vault", sa = "vault" }
    ack_secretsmanager = { ns = "ack-system", sa = "ack-secretsmanager-controller" }
  }
}

# VPC CNI
resource "aws_iam_role" "vpc_cni" {
  name               = "${var.eks_cluster_name}-vpc-cni"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = local.oidc_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = { StringEquals = {
        "${local.oidc_issuer}:sub" = "system:serviceaccount:${local.irsa_roles.vpc_cni.ns}:${local.irsa_roles.vpc_cni.sa}"
        "${local.oidc_issuer}:aud" = "sts.amazonaws.com"
      }}
    }]
  })
}

resource "aws_iam_role_policy_attachment" "vpc_cni" {
  role       = aws_iam_role.vpc_cni.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# EBS CSI
resource "aws_iam_role" "ebs_csi" {
  name               = "${var.eks_cluster_name}-ebs-csi"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = local.oidc_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = { StringEquals = {
        "${local.oidc_issuer}:sub" = "system:serviceaccount:${local.irsa_roles.ebs_csi.ns}:${local.irsa_roles.ebs_csi.sa}"
        "${local.oidc_issuer}:aud" = "sts.amazonaws.com"
      }}
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}


# ALB Controller
resource "aws_iam_role" "alb_controller" {
  name               = "${var.eks_cluster_name}-alb-controller"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = local.oidc_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = { StringEquals = {
        "${local.oidc_issuer}:sub" = "system:serviceaccount:${local.irsa_roles.alb_controller.ns}:${local.irsa_roles.alb_controller.sa}"
        "${local.oidc_issuer}:aud" = "sts.amazonaws.com"
      }}
    }]
  })
}

data "http" "alb_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "alb_controller" {
  name   = "${var.eks_cluster_name}-alb-controller"
  policy = data.http.alb_policy.response_body
}

resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = aws_iam_policy.alb_controller.arn
}

# Karpenter
resource "aws_iam_role" "karpenter" {
  name               = "${var.eks_cluster_name}-karpenter"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = local.oidc_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = { StringEquals = {
        "${local.oidc_issuer}:sub" = "system:serviceaccount:${local.irsa_roles.karpenter.ns}:${local.irsa_roles.karpenter.sa}"
        "${local.oidc_issuer}:aud" = "sts.amazonaws.com"
      }}
    }]
  })
}

resource "aws_iam_instance_profile" "karpenter" {
  name = "${var.eks_cluster_name}-karpenter"
  role = aws_iam_role.karpenter.name
}

# External DNS
resource "aws_iam_role" "external_dns" {
  name               = "${var.eks_cluster_name}-external-dns"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = local.oidc_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = { StringEquals = {
        "${local.oidc_issuer}:sub" = "system:serviceaccount:${local.irsa_roles.external_dns.ns}:${local.irsa_roles.external_dns.sa}"
        "${local.oidc_issuer}:aud" = "sts.amazonaws.com"
      }}
    }]
  })
}

# Vault
resource "aws_iam_role" "vault" {
  name               = "${var.eks_cluster_name}-vault"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = local.oidc_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = { StringEquals = {
        "${local.oidc_issuer}:sub" = "system:serviceaccount:${local.irsa_roles.vault.ns}:${local.irsa_roles.vault.sa}"
        "${local.oidc_issuer}:aud" = "sts.amazonaws.com"
      }}
    }]
  })
}

# ACK Secrets Manager Controller
resource "aws_iam_role" "ack_secretsmanager" {
  name               = "${var.eks_cluster_name}-ack-secretsmanager"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = local.oidc_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = { StringEquals = {
        "${local.oidc_issuer}:sub" = "system:serviceaccount:${local.irsa_roles.ack_secretsmanager.ns}:${local.irsa_roles.ack_secretsmanager.sa}"
        "${local.oidc_issuer}:aud" = "sts.amazonaws.com"
      }}
    }]
  })
}

resource "aws_iam_policy" "ack_secretsmanager" {
  name = "${var.eks_cluster_name}-ack-secretsmanager"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:CreateSecret",
          "secretsmanager:DeleteSecret",
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:ListSecrets",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecret",
          "secretsmanager:TagResource",
          "secretsmanager:UntagResource",
          "secretsmanager:RestoreSecret"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ack_secretsmanager" {
  role       = aws_iam_role.ack_secretsmanager.name
  policy_arn = aws_iam_policy.ack_secretsmanager.arn
}
