# Hosted zone 
/*
resource "aws_route53_zone" "preview" {
  name    = "preview.${var.environment}.test.io"
  comment = "Ephemeral environment DNS for ${var.eks_cluster_name}"

  tags = {
    Name = "${var.eks_cluster_name}-preview-zone"
  }
}
*/
