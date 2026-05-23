# VPC Flow Logs

data "aws_iam_policy_document" "vpc_flow_log" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "vpc_flow_log_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name = "VPC-Flow-logs-${aws_vpc.main.id}"
}

resource "aws_iam_role" "vpc_flow_log" {
  name               = "VPC-Flow-logs-IAM-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.vpc_flow_log_assume_role.json
}

resource "aws_iam_role_policy" "vpc_flow_log" {
  name   = "VPC-Flow-logs-IAM-policy-${var.environment}"
  role   = aws_iam_role.vpc_flow_log.id
  policy = data.aws_iam_policy_document.vpc_flow_log.json
}

resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.vpc_flow_log.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
  traffic_type    = var.vpc_flow_log_traffic_type
  vpc_id          = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-flow-logs"
  }
}
