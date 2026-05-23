# VPC Endpoints: ECR, S3, STS, SSM

resource "aws_vpc_endpoint" "gateway" {
  count        = length(var.vpc_endpoint_services)
  vpc_id       = aws_vpc.main.id
  service_name = var.vpc_endpoint_services[count.index]

  route_table_ids = [
    aws_route_table.private.id,
    aws_route_table.public.id,
  ]

  tags = {
    Name = "${var.environment}-vpce-${count.index}"
  }
}
