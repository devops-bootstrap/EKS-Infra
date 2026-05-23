# NAT Gateways (one per AZ for HA)

resource "aws_eip" "nat" {
  tags = {
    Name = "${var.environment}-nat-eip"
  }
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.environment}-nat"
  }
  depends_on = [aws_internet_gateway.igw]
}
