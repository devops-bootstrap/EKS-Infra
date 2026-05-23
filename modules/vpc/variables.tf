variable "cidr_block" {
  type = string
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "environment" {
  type = string
}

variable "vpc_endpoint_services" {
  type    = list(string)
  default = []
}

variable "vpc_flow_log_traffic_type" {
  type    = string
  default = "REJECT"
  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.vpc_flow_log_traffic_type)
    error_message = "Traffic type must be one of ACCEPT / REJECT / ALL"
  }
}

variable "private_nacl" {
  type = map(object({
    rule_no     = number
    protocol    = string
    cidr_block  = string
    from_port   = number
    to_port     = number
    rule_action = string
    egress      = bool
  }))
  default = {
    "allow_https_ingress" = {
      rule_no     = 100
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
      from_port   = 443
      to_port     = 443
      rule_action = "allow"
      egress      = false
    }
    "allow_http_ingress" = {
      rule_no     = 120
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
      from_port   = 80
      to_port     = 80
      rule_action = "allow"
      egress      = false
    }
    "allow_egress" = {
      rule_no     = 140
      protocol    = "all"
      cidr_block  = "0.0.0.0/0"
      from_port   = -1
      to_port     = -1
      rule_action = "allow"
      egress      = true
    }
  }
}

variable "public_nacl" {
  type = map(object({
    rule_no     = number
    protocol    = string
    cidr_block  = string
    from_port   = number
    to_port     = number
    rule_action = string
    egress      = bool
  }))
  default = {
    "allow_all_ingress" = {
      rule_no     = 100
      protocol    = "all"
      cidr_block  = "0.0.0.0/0"
      from_port   = -1
      to_port     = -1
      rule_action = "allow"
      egress      = false
    }
    "allow_egress" = {
      rule_no     = 140
      protocol    = "all"
      cidr_block  = "0.0.0.0/0"
      from_port   = -1
      to_port     = -1
      rule_action = "allow"
      egress      = true
    }
  }
}

variable "alb_sg_rules" {
  type = list(object({
    port        = number
    protocol    = string
    cidr_blocks = list(string)
    description = optional(string)
  }))
  default = [
    {
      port        = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP access"
    },
    {
      port        = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS access"
    }
  ]
}
