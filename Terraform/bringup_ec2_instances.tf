variable "access_key" {
    description = "AWS access key id"
}

variable "secret_key" {
    description = "AWS secret key id"
}

variable "region" {
    default = "us-east-1"
    description = "Region to bringup instance(s) in"
}

variable "ami" {
    default = "ami-408c7f28"
    description = "AMI to launch instance(s)"
}

variable "type" {
    default = "t1.micro"
    description = "Instance type to launch"
}

variable "keypair" {
    default = "ankur-ec2-test"
    description = "Key name to use for the instance(s)"

}

provider "aws" {
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
    region = "${var.region}"
}

resource "aws_instance" "bringup_ec2_instances" {
    ami = "${var.ami}"
    instance_type = "${var.type}"
    key_name = "${var.keypair}"
    count = 2
}
