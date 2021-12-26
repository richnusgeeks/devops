vpc_id = "vpc-1234567890"

create = true

use_name_prefix = true

name = "AWSMockingSGTest"

description  = "AWSMocking SG Test"

tags = {
  team = "automation"
  component = "security group"
  automation = "terraform"
}

ingress_cidr_blocks = ["10.0.0.0/24"]
ingress_rules = [
  {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    self        = false
    description = "HTTP from VPC"
  },
  {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    self        = false
    description = "TLS from VPC"
  }
]

egress_rules = [
  {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    description = "ALL from SG"
  }
]
