variable "aws_access_key" {}
variable "aws_secret_key" {}
  
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
    us-east-1 = "ami-2676404c"
  } 
}

variable "size" {
  default = "c4.2xlarge"
}   
  
variable "vpc_id" {
  default = {
    us-east-1 = "<VPC ID>"
  }
}

variable "subnet_id" {
  default = {
    us-east-1 = "<SUBNET ID>"
  }
}

variable "numseed" {
  default = 1
}

variable "numextra" {
  default = 1
}

variable "dtadsksze" {
  default = 1000
}

variable "dtadsktpe" {
  default = "gp2"
}

variable "stackname" {
  default = "eblk"
}

variable "topbeat" {
  default = "1.1.0"
}

variable "dashboards" {
  default = "1.1.0"
}

variable "hstnmeenv" {
  default = "tst-01"
}

variable "hstnmeprfx" {
  default = "elk"
}

variable "appspckd" {
  default = "Elasticsearch,Logstash,Kibana"
}

variable "vpcsgs" {
  default = "<SG ID>"
}

variable "zone_id" {
  default = "<ZONE ID>"
}

provider "aws" {
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
  region = "${var.aws_region}"
}

resource "aws_key_pair" "awsdemo" {
  key_name = "aws-eblk-demo"
  public_key = "${file("ssh/awsdemo.pub")}"
}

resource "aws_instance" "eblk-seed" {
  ami = "${lookup(var.ami, var.aws_region)}"
  instance_type = "${var.size}"
  key_name = "${aws_key_pair.awsdemo.key_name}"
  subnet_id = "${lookup(var.subnet_id, var.aws_region)}"
  vpc_security_group_ids = ["${split(",", var.vpcsgs)}"]
  associate_public_ip_address = true
  count = "${var.numseed}"

  root_block_device {
    volume_size = 20
    volume_type = "${var.dtadsktpe}"
  }

  ebs_block_device {
    device_name = "/dev/xvdb"
    volume_type = "${var.dtadsktpe}"
    volume_size = "${var.dtadsksze}"
  }

  tags {
    Name = "${format("%s-%s%02d", var.hstnmeenv, var.hstnmeprfx, count.index + 1)}"
    Environment = "${format("%s", var.hstnmeenv)}"
    Application = "${format("%s", var.appspckd)}"
    Role = "${format("%s", var.hstnmeprfx)}"
  }

  connection {
    user = "ubuntu"
    key_file = "ssh/awsdemo"
    agent = false
  }

  provisioner "remote-exec" {
    inline = [
      "sudo bash /opt/create_lvm_ebs.sh",
      "sudo sed -i '/^cluster.name: stackname-es/s/stackname/${var.stackname}/' /etc/elasticsearch/elasticsearch.yml",
      "sudo sed -i '/^discovery.zen.ping.unicast.hosts:/s/^/#/' /etc/elasticsearch/elasticsearch.yml",
      "sudo sed -i '/^#path.data: \\/raid0/s/^#//' /etc/elasticsearch/elasticsearch.yml",
      "sudo sed -i '/^#path.work: \\/raid0/s/^#//' /etc/elasticsearch/elasticsearch.yml",
      "sudo sed -i '/^#path.logs: \\/raid0/s/^#//' /etc/elasticsearch/elasticsearch.yml",
      "sudo mkdir -p /raid0/elasticsearch/{index,work,logs}",
      "sudo chown -R elasticsearch:elasticsearch /raid0/elasticsearch",
      "sudo service elasticsearch start",
      "while true; do if ! nc -z localhost 9200 > /dev/null 2>&1; then sleep 5; else break; fi; done",
      "curl -XPUT 'http://localhost:9200/_template/topbeat' -d@/etc/topbeat/topbeat.template.json",
      "sudo sh -c 'cd /opt/beats-dashboards-${var.dashboards} && ./load.sh'",
      "while sudo service logstash status|grep 'not running' > /dev/null 2>&1; do sudo service logstash start; sleep 5; done",
      "while sudo service topbeat status|grep 'not running' > /dev/null 2>&1; do sudo service topbeat start; sleep 5; done",
      "sudo start kibana"
    ]
  }
}

resource "aws_instance" "eblk-extra" {
  ami = "${lookup(var.ami, var.aws_region)}"
  instance_type = "${var.size}"
  key_name = "${aws_key_pair.awsdemo.key_name}"
  subnet_id = "${lookup(var.subnet_id, var.aws_region)}"
  vpc_security_group_ids = ["${split(",", var.vpcsgs)}"]
  associate_public_ip_address = true
  count = "${var.numextra}"

  root_block_device {
    volume_size = 20
    volume_type = "${var.dtadsktpe}"
  }

  ebs_block_device {
    device_name = "/dev/xvdb"
    volume_type = "${var.dtadsktpe}"
    volume_size = "${var.dtadsksze}"
  }

  tags {
    Name = "${format("%s-%s%02d", var.hstnmeenv, var.hstnmeprfx, count.index + var.numseed + 1)}"
    Environment = "${format("%s", var.hstnmeenv)}"
    Application = "${format("%s", var.appspckd)}"
    Role = "${format("%s", var.hstnmeprfx)}"
  }

  connection {
    user = "ubuntu"
    key_file = "ssh/awsdemo"
    agent = false
  }

  provisioner "remote-exec" {
    inline = [
      "sudo bash /opt/create_lvm_ebs.sh",
      "sudo sed -i '/^cluster.name: stackname-es/s/stackname/${var.stackname}/' /etc/elasticsearch/elasticsearch.yml",
      "sudo sed -i '/^discovery.zen.ping.unicast.hosts:/s/127.0.0.1/${join(",", aws_instance.eblk-seed.*.private_dns)}/' /etc/elasticsearch/elasticsearch.yml",
      "sudo sed -i '/^discovery.zen.ping.unicast.hosts:/s/\"//g' /etc/elasticsearch/elasticsearch.yml",
      "sudo sed -i '/^#path.data: \\/raid0/s/^#//' /etc/elasticsearch/elasticsearch.yml",
      "sudo sed -i '/^#path.work: \\/raid0/s/^#//' /etc/elasticsearch/elasticsearch.yml",
      "sudo sed -i '/^#path.logs: \\/raid0/s/^#//' /etc/elasticsearch/elasticsearch.yml",
      "sudo mkdir -p /raid0/elasticsearch/{index,work,logs}",
      "sudo chown -R elasticsearch:elasticsearch /raid0/elasticsearch",
      "sudo service elasticsearch start",
      "while true; do if ! nc -z localhost 9200 > /dev/null 2>&1; then sleep 5; else break; fi; done",
      "while sudo service logstash status|grep 'not running' > /dev/null 2>&1; do sudo service logstash start; sleep 5; done",
      "while sudo service topbeat status|grep 'not running' > /dev/null 2>&1; do sudo service topbeat start; sleep 5; done",
      "sudo start kibana"
    ]
  }
}

resource "aws_route53_record" "eblk-seed" {
  count = "${var.numseed}"
  zone_id = "${var.zone_id}"
  name = "${format("%s-%s%02d", var.hstnmeenv, var.hstnmeprfx, count.index + 1)}"
  type ="CNAME"
  ttl = "300"
  records = ["${element(aws_instance.eblk-seed.*.public_dns, count.index)}"]
}

resource "aws_route53_record" "eblk-extra" {
  count = "${var.numextra}"
  zone_id = "${var.zone_id}"
  name = "${format("%s-%s%02d", var.hstnmeenv, var.hstnmeprfx, count.index + var.numseed + 1)}"
  type ="CNAME"
  ttl = "300"
  records = ["${element(aws_instance.eblk-extra.*.public_dns, count.index)}"]
}

output "eblkseed_id" {
  value = "${join(",", aws_instance.eblk-seed.*.id)}"
}

output "eblkextra_id" {
  value = "${join(",", aws_instance.eblk-extra.*.id)}"
}

output "eblkseed_ip" {
  value = "${join(",", aws_instance.eblk-seed.*.public_ip)}"
}

output "eblkextra_ip" {
  value = "${join(",", aws_instance.eblk-extra.*.public_ip)}"
}

output "eblkseed_dns" {
  value = "${join(",", aws_instance.eblk-seed.*.public_dns)}"
}

output "eblkextra_dns" {
  value = "${join(",", aws_instance.eblk-extra.*.public_dns)}"
}
