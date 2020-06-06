variable "vpc_id" {
  default = "vpc-1234567890"
}

variable "cidr_block" {
  default = "10.0.0.0/24"
}

variable "create" {
  default = true
}

variable "use_name_prefix" {
  default = true
}

variable "name" {
  default = "AWSMockingSGTest"
}

variable "description" {
  default = "AWSMocking SG Test"
}

variable "tags" {
  default = {}
}

variable "ingress_rules" {
  default = [
              {
                description = "HTTP from VPC"
                from_port   = 80
                to_port     = 80
                protocol    = "tcp"
                cidr_blocks = "0.0.0.0/0"
              },
              {
                description = "TLS from VPC"
                from_port   = 443
                to_port     = 443
                protocol    = "tcp"
                cidr_blocks = "0.0.0.0/0"
              }
  ]
}

variable "egress_rules" {
  default = [
              {
                from_port   = 0
                to_port     = 0
                protocol    = "-1"
                cidr_blocks = ["0.0.0.0/0"]
              }
  ]
}

##################################
# Get ID of created Security Group
##################################
locals {
  this_sg_id = concat(
    aws_security_group.this.*.id,
    aws_security_group.this_name_prefix.*.id,
    [""],
  )[0]
}

##########################
# Security group with name
##########################
resource "aws_security_group" "this" {
  count = var.create && false == var.use_name_prefix ? 1 : 0

  name        = var.name
  description = var.description
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      "Name" = format("%s", var.name)
    },
  )
}

#################################
# Security group with name_prefix
#################################
resource "aws_security_group" "this_name_prefix" {
  count = var.create && var.use_name_prefix ? 1 : 0

  name_prefix = "${var.name}-"
  description = var.description
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      "Name" = format("%s", var.name)
    },
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "ingress_rules" {
  count = var.create ? length(var.ingress_rules) : 0

  security_group_id = local.this_sg_id
  type              = "ingress"

  cidr_blocks      = [var.cidr_block]

  from_port = var.ingress_rules[count.index]["from_port"]
  to_port   = var.ingress_rules[count.index]["to_port"]
  protocol  = var.ingress_rules[count.index]["protocol"]
}

resource "aws_security_group_rule" "egress_rules" {
  count = var.create ? length(var.egress_rules) : 0

  security_group_id = local.this_sg_id
  type              = "egress"

  cidr_blocks      = [var.cidr_block]

  from_port = var.egress_rules[count.index]["from_port"]
  to_port   = var.egress_rules[count.index]["to_port"]
  protocol  = var.egress_rules[count.index]["protocol"]
}
