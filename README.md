# EKS-Infra

Infrastructure as Code (IaC) for deploying Amazon EKS (Elastic Kubernetes Service) clusters on AWS using Terraform.

## Overview

This repository contains Terraform code to provision a complete EKS infrastructure including:
- **VPC**: Custom VPC with public and private subnets across multiple availability zones
- **EKS Cluster**: Kubernetes cluster with configurable versions and endpoint access
- **Node Groups**: Managed node groups with configurable instance types and scaling parameters
- **IAM Roles**: IRSA (IAM Roles for Service Accounts) for pod-level permissions
- **Supporting Resources**: ECR repositories, security groups, and other supporting AWS resources

## Architecture

The infrastructure is organized into three main modules:

### 1. VPC Module (`./modules/vpc`)
Creates a highly available VPC with:
- Public subnets (3 across AZs) with Internet Gateway
- Private subnets (3 across AZs) with NAT Gateway
- Route tables and associations for routing
- VPC Gateway Endpoints for S3 and DynamoDB
- Proper Kubernetes subnet tags for ELB provisioning

### 2. EKS Module (`./modules/eks`)
Provisions the EKS cluster with:
- EKS control plane with configurable Kubernetes version
- OIDC provider for IAM integration
- Cluster IAM roles and policies
- Managed node groups with auto-scaling
- EBS CSI driver for persistent volumes
- IRSA roles for:
  - EBS CSI Driver
  - AWS Load Balancer Controller
  - VPC CNI
  - Karpenter (auto-scaling)
  - External DNS
  - HashiCorp Vault

### 3. Supporting Module (`./modules/supporting`)
Manages additional resources:
- ECR repositories for container images
- Security group configurations

## Prerequisites

- **Terraform**: >= 1.5.0
- **AWS Account**: with appropriate permissions
- **AWS CLI**: configured with credentials
- **Providers**:
  - AWS Provider: ~> 6.0
  - TLS Provider: ~> 4.0
  - HTTP Provider: ~> 3.0

## Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/devops-bootstrap/EKS-Infra.git
cd EKS-Infra
```

### 2. Initialize Terraform
```bash
terraform init
```

### 3. Review and Customize Variables
Create a `terraform.tfvars` file to override default values:
```hcl
region     = "us-east-1"
environment = "dev"
eks_cluster_name = "my-eks-cluster"
eks_cluster_version = "1.34"

# VPC Configuration
cidr_block           = "10.0.0.0/16"
private_subnet_cidrs = ["10.0.0.0/19", "10.0.32.0/19", "10.0.64.0/19"]
public_subnet_cidrs  = ["10.0.96.0/19", "10.0.128.0/19", "10.0.160.0/19"]

# EKS Configuration
eks_node_group_desired_size = 3
eks_node_group_min_size     = 3
eks_node_group_max_size     = 5
eks_node_group_instance_types = ["t3.medium"]
```

### 4. Plan the Deployment
```bash
terraform plan -out=tfplan
```

### 5. Apply the Configuration
```bash
terraform apply tfplan
```

## Configuration

### Key Variables

#### General
| Variable | Default | Description |
|----------|---------|-------------|
| `region` | `us-east-1` | AWS region |
| `environment` | `dev` | Environment name (dev, staging, prod) |
| `default_tags` | `{Environment: Test, Owner: PlatformTeam}` | Default tags for all resources |

#### VPC
| Variable | Default | Description |
|----------|---------|-------------|
| `cidr_block` | `10.0.0.0/16` | VPC CIDR block |
| `private_subnet_cidrs` | `["10.0.0.0/19", "10.0.32.0/19", "10.0.64.0/19"]` | Private subnet CIDRs |
| `public_subnet_cidrs` | `["10.0.96.0/19", "10.0.128.0/19", "10.0.160.0/19"]` | Public subnet CIDRs |
| `vpc_endpoint_services` | `["com.amazonaws.us-east-1.s3", "com.amazonaws.us-east-1.dynamodb"]` | VPC Gateway Endpoints |

#### EKS Cluster
| Variable | Default | Description |
|----------|---------|-------------|
| `eks_cluster_name` | `my-eks-cluster` | EKS cluster name |
| `eks_cluster_version` | `1.34` | Kubernetes version |
| `eks_cluster_service_ipv4_cidr` | `172.20.0.0/16` | Service CIDR |
| `eks_cluster_endpoint_private_access` | `true` | Enable private API endpoint |
| `eks_cluster_endpoint_public_access` | `true` | Enable public API endpoint |
| `eks_cluster_endpoint_public_access_cidrs` | `["0.0.0.0/0"]` | Public endpoint access CIDRs |

#### Node Groups
| Variable | Default | Description |
|----------|---------|-------------|
| `eks_node_group_ami_type` | `BOTTLEROCKET_x86_64` | AMI type for nodes |
| `eks_node_group_instance_types` | `["t3.medium"]` | Instance types |
| `eks_node_group_desired_size` | `3` | Desired number of nodes |
| `eks_node_group_min_size` | `3` | Minimum number of nodes |
| `eks_node_group_max_size` | `5` | Maximum number of nodes |

#### Add-ons
| Variable | Default | Description |
|----------|---------|-------------|
| `addon_versions` | `{ ebs_csi = null }` | EKS add-on versions (null = latest) |

## Outputs

The following outputs are available after deployment:

| Output | Description |
|--------|-------------|
| `vpc_id` | VPC ID |
| `private_subnet_ids` | Private subnet IDs |
| `public_subnet_ids` | Public subnet IDs |
| `cluster_id` | EKS cluster ID |
| `cluster_endpoint` | EKS API endpoint |
| `cluster_certificate_authority_data` | Cluster CA certificate |
| `cluster_oidc_issuer_url` | OIDC provider URL |
| `irsa_role_arns` | IRSA role ARNs for various services |

## Post-Deployment

### 1. Configure kubectl
```bash
aws eks update-kubeconfig --region $(terraform output -raw region) --name $(terraform output -raw cluster_id)
```

### 2. Verify Cluster Access
```bash
kubectl get nodes
kubectl get pods -A
```

### 3. Deploy Applications
Use the provided outputs to configure Helm, applications, and other Kubernetes tools.

## Environment Directories

The `./envs` directory is reserved for environment-specific configurations and `.tfvars` files:
```
envs/
├── dev/
│   └── terraform.tfvars
├── staging/
│   └── terraform.tfvars
└── prod/
    └── terraform.tfvars
```

## Troubleshooting

### Common Issues

**1. VPC CIDR Conflicts**
Ensure the CIDR blocks don't conflict with your existing infrastructure.

**2. IAM Permissions**
Verify that your AWS credentials have the necessary permissions to create EKS, VPC, and IAM resources.

**3. Terraform State**
For production use, configure a remote state backend (S3 + DynamoDB):
```hcl
terraform {
  backend "s3" {
    bucket         = "your-state-bucket"
    key            = "eks-infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
  }
}
```

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

## Best Practices

1. **Use separate tfvars files** for different environments
2. **Enable state locking** with remote backends in production
3. **Restrict public endpoint access** by limiting `eks_cluster_endpoint_public_access_cidrs`
4. **Use private subnets** for node groups when possible
5. **Enable EKS control plane logging** for audit trails
6. **Regularly update** Kubernetes and add-on versions
7. **Test changes** in dev/staging before production

## Security Considerations

- The default configuration allows public access to the EKS API endpoint. Restrict this in production.
- Use private subnets for node groups whenever possible.
- Enable VPC Flow Logs for network monitoring.
- Implement network policies using Calico or Cilium.
- Use RBAC and IRSA for least-privilege access.
- Enable EBS encryption for persistent volumes.

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Commit changes (`git commit -am 'Add improvement'`)
4. Push to the branch (`git push origin feature/improvement`)
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues, questions, or contributions, please open an issue on GitHub.

---

**Last Updated**: 2026-05-23
