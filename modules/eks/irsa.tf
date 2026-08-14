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
    crossplane         = { ns = "crossplane-system", sa = "upbound-provider-aws-*" }
    ack_iam            = { ns = "ack-system", sa = "ack-iam-controller" }
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

resource "aws_iam_policy" "karpenter" {
  name = "${var.eks_cluster_name}-karpenter"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:CreateTags",
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "ec2:DeleteLaunchTemplate"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = "arn:aws:iam::*:role/${var.eks_cluster_name}-nodegroup-role"
      },
      {
        Effect = "Allow"
        Action = [
          "iam:ListInstanceProfiles",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:GetInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:TagInstanceProfile"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "pricing:GetProducts",
          "ssm:GetParameter"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ReceiveMessage"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "karpenter" {
  role       = aws_iam_role.karpenter.name
  policy_arn = aws_iam_policy.karpenter.arn
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

# ACK IAM Controller
resource "aws_iam_role" "ack_iam" {
  name               = "${var.eks_cluster_name}-ack-iam"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = local.oidc_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = { StringEquals = {
        "${local.oidc_issuer}:sub" = "system:serviceaccount:${local.irsa_roles.ack_iam.ns}:${local.irsa_roles.ack_iam.sa}"
        "${local.oidc_issuer}:aud" = "sts.amazonaws.com"
      }}
    }]
  })
}

resource "aws_iam_policy" "ack_iam" {
  name = "${var.eks_cluster_name}-ack-iam"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:UpdateRole",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:ListRoleTags",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:CreatePolicyVersion",
          "iam:DeletePolicyVersion",
          "iam:ListPolicyVersions",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:GetRolePolicy"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ack_iam" {
  role       = aws_iam_role.ack_iam.name
  policy_arn = aws_iam_policy.ack_iam.arn
}

# Crossplane AWS Provider
resource "aws_iam_role" "crossplane" {
  name               = "${var.eks_cluster_name}-crossplane-provider-aws"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = local.oidc_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringLike = {
          "${local.oidc_issuer}:sub" = "system:serviceaccount:${local.irsa_roles.crossplane.ns}:${local.irsa_roles.crossplane.sa}"
        }
        StringEquals = {
          "${local.oidc_issuer}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "crossplane" {
  name = "${var.eks_cluster_name}-crossplane-provider-aws"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # S3
          "s3:*",
          # RDS
          "rds:*",
          # EC2 (VPC, subnets, security groups)
          "ec2:Describe*",
          "ec2:CreateVpc",
          "ec2:DeleteVpc",
          "ec2:CreateSubnet",
          "ec2:DeleteSubnet",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:CreateTags",
          # IAM (for managed resources)
          "iam:GetRole",
          "iam:PassRole",
          # Tagging
          "tag:GetResources",
          "tag:TagResources"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "crossplane" {
  role       = aws_iam_role.crossplane.name
  policy_arn = aws_iam_policy.crossplane.arn
}
