resource "aws_security_group_rule" "egress_rules" {
  count = var.create ? length(var.egress_rules) : 0

  security_group_id = local.this_sg_id
  type              = "egress"

  cidr_blocks      = [var.cidr_block]

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

###################################
# Ingress - List of rules (simple)
###################################
# Security group rules with "cidr_blocks" and it uses list of rules names
resource "aws_security_group_rule" "ingress_rules" {
  count = var.create ? length(var.ingress_rules) : 0

  security_group_id = local.this_sg_id
  type              = "ingress"

  cidr_blocks = var.ingress_cidr_blocks

  from_port   = var.ingress_rules[count.index]["from_port"]
  to_port     = var.ingress_rules[count.index]["to_port"]
  protocol    = var.ingress_rules[count.index]["protocol"]
  self        = var.ingress_rules[count.index]["self"]
  description = var.ingress_rules[count.index]["description"]
}

##################################
# Egress - List of rules (simple)
##################################
# Security group rules with "cidr_blocks" and it uses list of rules names
resource "aws_security_group_rule" "egress_rules" {
  count = var.create ? length(var.egress_rules) : 0

  security_group_id = local.this_sg_id
  type              = "egress"

  cidr_blocks = var.egress_cidr_blocks

  from_port   = var.egress_rules[count.index]["from_port"]
  to_port     = var.egress_rules[count.index]["to_port"]
  protocol    = var.egress_rules[count.index]["protocol"]
  description = var.egress_rules[count.index]["description"]
}
