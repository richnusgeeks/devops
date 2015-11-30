variable "aws_access_key" {}
variable "aws_secret_key" {}
#variable "aws_key_path" {}
#variable "aws_key_name" {}
  
variable "aws_region" {
  default = "us-east-1"
}   
    
variable "zone" {
  default = {
    us-east-1 = "b"
    us-west-2 = "a"
  }
}   
    
variable "arch" {
  default = 64
} 

variable "ami" {
  default = { 
    us-east-1 = "ami-"
  } 
}   
  
variable "vpc_id" {
  default = {
    us-east-1 = "vpc-"
    us-west-2 = "vpc-"
  }
}

variable "subnet_id" {
  default = {
    us-east-1b = "subnet-"
    us-east-1c = "subnet-"
    us-east-1d = "subnet-"
    us-east-1e = "subnet-"
    us-west-2a = "subnet-"
    us-west-2b = "subnet-"
    us-west-2c = "subnet-"
  }
}

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.aws_region}"
}

resource "aws_key_pair" "awsdemo" {
  key_name = "aws-devops-tools"
  public_key = "${file(\"ssh/awsdemo.pub\")}"
}

resource "aws_security_group" "default" {
  
  name = "default-devops-tools"
  description = "Default security group for the DevOps tools"
  vpc_id = "${lookup(var.vpc_id, var.aws_region)}"
  
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "DevOps Tools Test"
  }

}

resource "aws_instance" "dvopstlstst" {
  ami = "${lookup(var.ami, var.aws_region)}"
  instance_type = "t2.medium"
  key_name = "${aws_key_pair.awsdemo.key_name}"
  vpc_security_group_ids = ["${aws_security_group.default.id}"]
  associate_public_ip_address = true

  tags {
    Name = "DevOps Tools Test"
  }

  connection {
    user = "ubuntu"
    key_file = "ssh/awsdemo"
    agent = false
  }

  provisioner "remote-exec" {
    inline = [
      "for t in consul nomad otto packer terraform vault; do ls -lhrtd /opt/$t*; done",
      "for t in consul nomad otto packer terraform vault; do $t version; done",
      "ls -lhrt /tmp"
    ]
  }
}

output "id" {
  value = "${aws_instance.dvopstlstst.id}"
} 

output "ip" {
  value = "${aws_instance.dvopstlstst.public_ip}"
}

output "sgid" {
  value = "${aws_security_group.default.id}"
}
