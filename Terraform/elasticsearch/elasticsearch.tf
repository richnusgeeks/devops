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

variable "numclnt" {
  default = 2
}

variable "nummstr" {
  default = 2
}

variable "numdata" {
  default = 2
}

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.aws_region}"
}

resource "aws_key_pair" "elskp" {
  key_name = "aws-elskp"
  public_key = "${file(\"<KeyName>.pub\")}"
}

resource "aws_security_group" "elssg" {
  
  name = "aws-elssg"
  description = "Default security group for the Elasticsearch"
  vpc_id = "${lookup(var.vpc_id, var.aws_region)}"
  
  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 9200
    to_port   = 9200
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 9300
    to_port   = 9300
    protocol  = "tcp"
    self = true
  }

  egress {
    from_port = 9300
    to_port   = 9300
    protocol  = "tcp"
    self = true
  }

  tags {
    Name = "Elasticsearch"
  }

}

resource "aws_instance" "elsmstr" {
  ami = "${lookup(var.ami, var.aws_region)}"
  instance_type = "${var.size}"
  key_name = "${aws_key_pair.elskp.key_name}"
  vpc_security_group_ids = ["${aws_security_group.elssg.id}"]
  associate_public_ip_address = true
  count = "${var.nummstr}"

  tags {
    Name = "${format("ELSMstr-%02d", count.index + 1)}"
  }

  connection {
    user = "ubuntu"
    key_file = "<Private Key>"
    agent = false
  }


  provisioner "remote-exec" {
    inline = [
      "sudo sed -i '/^#node.master: true/s/^#//' /etc/elasticsearch/elasticsearch.yml",
      "sudo sed -i '/^#node.data: false/s/^#//' /etc/elasticsearch/elasticsearch.yml",
      "sudo sed -i '/^#http.enabled: false/s/^#//' /etc/elasticsearch/elasticsearch.yml",
      "sudo sed -i '/^discovery.zen.ping.unicast.hosts:/s/^/#/' /etc/elasticsearch/elasticsearch.yml",
      "sudo service elasticsearch restart",
      "grep -E '^(node.master|node.data|http.enabled|#discovery.zen.ping.unicast.hosts)' /etc/elasticsearch/elasticsearch.yml",
      "while true; do if ! nc -z localhost 9300 > /dev/null 2>&1; then sleep 5; else break; fi; done"
    ]
  }
}

resource "aws_instance" "elsclnt" {
  ami = "${lookup(var.ami, var.aws_region)}"
  instance_type = "${var.size}"
  key_name = "${aws_key_pair.elskp.key_name}"
  vpc_security_group_ids = ["${aws_security_group.elssg.id}"]
  associate_public_ip_address = true
  count = "${var.numclnt}"
  depends_on = ["aws_instance.elsdata"]

  tags {
    Name = "${format("ELSClnt-%02d", count.index + 1)}"
  }

  connection {
    user = "ubuntu"
    key_file = "<Private Key>"
    agent = false
  }

  provisioner "remote-exec" {
    inline = [
      "sudo sed -i '/^#node.master: false/s/^#//' /etc/elasticsearch/elasticsearch.yml",
      "sudo sed -i '/^#node.data: false/s/^#//' /etc/elasticsearch/elasticsearch.yml",
      "sudo sed -i '/^discovery.zen.ping.unicast.hosts:/s/127.0.0.1/${join(",", aws_instance.elsmstr.*.private_dns)}/' /etc/elasticsearch/elasticsearch.yml",
      "sudo sed -i '/^discovery.zen.ping.unicast.hosts:/s/\"//g' /etc/elasticsearch/elasticsearch.yml",
      "sudo service elasticsearch restart",
      "grep -E '^(node.master|node.data|http.enabled|discovery.zen.ping.unicast.hosts)' /etc/elasticsearch/elasticsearch.yml",
      "while true; do if ! curl localhost:9200/_nodes?pretty >/dev/null 2>&1; then sleep 5; else break; fi; done"
    ]
  }
}

resource "aws_instance" "elsdata" {
  ami = "${lookup(var.ami, var.aws_region)}"
  instance_type = "${var.size}"
  key_name = "${aws_key_pair.elskp.key_name}"
  vpc_security_group_ids = ["${aws_security_group.elssg.id}"]
  associate_public_ip_address = true
  count = "${var.numdata}"
  depends_on = ["aws_instance.elsmstr"]

  tags {
    Name = "${format("ELSData-%02d", count.index + 1)}"
  }

  connection {
    user = "ubuntu"
    key_file = "<Private Key>"
    agent = false
  }

  provisioner "remote-exec" {
    inline = [
      "sudo sed -i '/^#node.master: false/s/^#//' /etc/elasticsearch/elasticsearch.yml",
      "sudo sed -i '/^#node.data: true/s/^#//' /etc/elasticsearch/elasticsearch.yml",
      "sudo sed -i '/^#http.enabled: false/s/^#//' /etc/elasticsearch/elasticsearch.yml",
      "sudo sed -i '/^discovery.zen.ping.unicast.hosts:/s/127.0.0.1/${join(",", aws_instance.elsmstr.*.private_dns)}/' /etc/elasticsearch/elasticsearch.yml",
      "sudo sed -i '/^discovery.zen.ping.unicast.hosts:/s/\"//g' /etc/elasticsearch/elasticsearch.yml",
      "sudo service elasticsearch restart",
      "grep -E '^(node.master|node.data|http.enabled|discovery.zen.ping.unicast.hosts)' /etc/elasticsearch/elasticsearch.yml",
      "while true; do if ! nc -z localhost 9300 > /dev/null 2>&1; then sleep 5; else break; fi; done"
    ]
  }
}

resource "aws_route53_zone" "test" {
  name = "<Hosted Zone>"

  tags {
    Environment = "devops"
  }
}

resource "aws_route53_record" "esclnt" {
  count = "${var.numclnt}"
  zone_id = "${aws_route53_zone.test.zone_id}"
  name = "${format("ELSClnt-%02d", count.index + 1)}"
  type ="CNAME"
  ttl = "300"
  records = ["${element(aws_instance.elsclnt.*.public_dns, count.index)}"]
}

resource "aws_route53_record" "elsmstr" {
  count = "${var.nummstr}"
  zone_id = "${aws_route53_zone.test.zone_id}"
  name = "${format("ELSMstr-%02d", count.index + 1)}"
  type ="CNAME"
  ttl = "300"
  records = ["${element(aws_instance.elsmstr.*.public_dns, count.index)}"]
}

resource "aws_route53_record" "elsdata" {
  count = "${var.numdata}"
  zone_id = "${aws_route53_zone.test.zone_id}"
  name = "${format("ELSData-%02d", count.index + 1)}"
  type ="CNAME"
  ttl = "300"
  records = ["${element(aws_instance.elsdata.*.public_dns, count.index)}"]
}

output "elsclnt_id" {
  value = "${join(",", aws_instance.elsclnt.*.id)}"
}

output "elsclnt_ip" {
  value = "${join(",", aws_instance.elsclnt.*.public_ip)}"
}

output "elsclnt_dns" {
  value = "${join(",", aws_instance.elsclnt.*.public_dns)}"
}
