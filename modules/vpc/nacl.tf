# Network ACLs

resource "aws_network_acl" "private" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.environment}-private-nacl"
  }
}

resource "aws_network_acl" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.environment}-public-nacl"
  }
}

resource "aws_network_acl_rule" "private" {
  for_each       = var.private_nacl
  network_acl_id = aws_network_acl.private.id
  rule_number    = each.value.rule_no
  protocol       = each.value.protocol
  cidr_block     = each.value.cidr_block
  from_port      = each.value.from_port
  to_port        = each.value.to_port
  rule_action    = each.value.rule_action
  egress         = each.value.egress
}

resource "aws_network_acl_rule" "public" {
  for_each       = var.public_nacl
  network_acl_id = aws_network_acl.public.id
  rule_number    = each.value.rule_no
  protocol       = each.value.protocol
  cidr_block     = each.value.cidr_block
  from_port      = each.value.from_port
  to_port        = each.value.to_port
  rule_action    = each.value.rule_action
  egress         = each.value.egress
}

resource "aws_network_acl_association" "private" {
  count          = length(aws_subnet.private[*].id)
  network_acl_id = aws_network_acl.private.id
  subnet_id      = aws_subnet.private[count.index].id
}

resource "aws_network_acl_association" "public" {
  count          = length(aws_subnet.public[*].id)
  network_acl_id = aws_network_acl.public.id
  subnet_id      = aws_subnet.public[count.index].id
}
