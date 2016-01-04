variable "aws_access_key" {}
variable "aws_secret_key" {}
    
variable "aws_region" {
  default = <Region>
}

variable "ami" {
  default = {
    <Region> = "<Packer created AMI>"
  }
}

variable "size" {
  default = "t2.medium"
}

variable "vpc_id" {
  default = {
    <Region> = "<VPC ID>"
  }
}

variable "subnet_id" {
  default = {
    <Region><Availability Zone> = "<Subnet ID>"
  }
}

variable "numnds" {
  default = 2
}

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.aws_region}"
}

resource "aws_key_pair" "caskp" {
  key_name = "aws-caskp"
  public_key = "${file(\"<KeyName>.pub\")}"
}

resource "aws_security_group" "cassg" {

  name = "aws-cassg"
  description = "Default security group for Vnodes based Cassandra cluster"
  vpc_id = "${lookup(var.vpc_id, var.aws_region)}"
  
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 7000
    to_port   = 7001
    protocol  = "tcp"
    self      = true
  }

  egress {
    from_port = 7000
    to_port   = 7001
    protocol  = "tcp"
    self      = true
  }

  ingress {
    from_port = 9042
    to_port   = 9042
    protocol  = "tcp"
    self      = true
  }

  ingress {
    from_port = 9160
    to_port   = 9160
    protocol  = "tcp"
    self      = true
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 9042
    to_port   = 9042
    protocol  = "tcp"
    self      = true
  }

  egress {
    from_port = 9160
    to_port   = 9160
    protocol  = "tcp"
    self      = true
  }

  tags {
    Name = "VndsClstrCas"
  }
}

resource "aws_instance" "vnccas" {
  ami = "${lookup(var.ami, var.aws_region)}"
  instance_type = "${var.size}"
  key_name = "${aws_key_pair.caskp.key_name}"
  vpc_security_group_ids = ["${aws_security_group.cassg.id}"]
  associate_public_ip_address = true
  count = "${var.numnds}"

  tags {
    Name = "${format("CAS-%02d", count.index + 1)}"
  }

  connection {
    user = "ubuntu"
    key_file = "<Private Key>"
    agent = false
  }

  provisioner "remote-exec" {
    inline = [
      "sudo rm -rfv /var/lib/cassandra",
      "sudo mkdir -p /var/lib/cassandra",
      "sudo chmod 0750 /var/lib/cassandra",
      "sudo chown cassandra:cassandra /var/lib/cassandra",
      "sudo rm -rfv /var/log/cassandra",
      "sudo mkdir -p /var/log/cassandra",
      "sudo chmod 0755 /var/lib/cassandra",
      "sudo chown cassandra:cassandra /var/log/cassandra",
      "sudo sed -i '/^ *# *num_tokens/s/^ *# *//' /etc/dse/cassandra/cassandra.yaml",
      "sudo sed -i '/^ *- *seeds/s/127.0.0.1/${aws_instance.vnccas.0.private_ip}/' /etc/dse/cassandra/cassandra.yaml",
      "sudo sed -i '/^ *listen_address/s/localhost/${self.private_ip}/' /etc/dse/cassandra/cassandra.yaml",
      "sudo sed -i '/^ *# *broadcast_address/s/^ *# *//' /etc/dse/cassandra/cassandra.yaml",
      "sudo sed -i '/^ *broadcast_address/s/1.2.3.4/${self.private_ip}/' /etc/dse/cassandra/cassandra.yaml",
      "sudo sed -i '/^ *rpc_address/s/localhost/${self.private_ip}/' /etc/dse/cassandra/cassandra.yaml",
      "sudo sed -i '/^ *# *broadcast_rpc_address/s/^ *# *//' /etc/dse/cassandra/cassandra.yaml",
      "sudo sed -i '/^ *broadcast_rpc_address/s/1.2.3.4/${self.private_ip}/' /etc/dse/cassandra/cassandra.yaml",
      "grep '^ *- *seeds' /etc/dse/cassandra/cassandra.yaml",
      "grep -E '^ *(num_tokens|listen_address|broadcast_address|rpc_address|broadcast_rpc_address)' /etc/dse/cassandra/cassandra.yaml",
      "sudo chown cassandra:cassandra /etc/dse/cassandra/cassandra.yaml",
    ]
  }
}

resource "null_resource" "pstprcs" {
  triggers {
    cluster_instance_ids = "${join(",",aws_instance.vnccas.*.id)}"
  }

  provisioner "local-exec" {
    command = "fab -f scripts/cas.py postCAS -H ${join(",",aws_instance.vnccas.*.public_dns)}"
  }
}

resource "aws_route53_zone" "test" {
  name = "<Hosted Zone>"

  tags {
    Environment = "devops"
  }
}

resource "aws_route53_record" "vnccas" {
  count = "${var.numnds}"
  zone_id = "${aws_route53_zone.test.zone_id}"
  name = "${format("CAS-%02d", count.index + 1)}"
  type ="CNAME"
  ttl = "300"
  records = ["${element(aws_instance.vnccas.*.public_dns, count.index)}"]
}

output "vnccas_id" {
  value = "${join(",", aws_instance.vnccas.*.id)}"
}

output "vnccas_public_ip" {
  value = "${join(",", aws_instance.vnccas.*.public_ip)}"
}

output "vnccas_private_ip" {
  value = "${join(",", aws_instance.vnccas.*.private_ip)}"
}

output "vnccas_public_dns" {
  value = "${join(",", aws_instance.vnccas.*.public_dns)}"
}
