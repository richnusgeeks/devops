resource "aws_instance" "awsvm" {
  ami = "${var.ami_id}"
  instance_type = "${var.inst_type}"
  key_name = "${var.key_name}"
  subnet_id = "${var.subnet_id}"
  vpc_security_group_ids = ["${split(",", var.sg_id)}"]
  associate_public_ip_address = true
  count = "${var.num_nds}"

  tags {
    Name = "${format("%s-%02d", var.hst_nme, count.index + 1)}"
    Environment = "${format("%s", var.hst_env)}"
    Application = "${format("%s", var.apps_pckd)}"
    Role = "${format("%s", var.hst_rle)}"
  }

  root_block_device {
    volume_size = "${var.root_size}"
  }

  ebs_block_device {
    device_name = "/dev/xvde"
    volume_type = "standard"
    volume_size = "${var.swap_size}"
    encrypted = true
  }
  
  ebs_block_device {
    device_name = "/dev/xvdf"
    volume_type = "standard"
    volume_size = "${var.vol_size}"
    encrypted = true
  }
  ebs_block_device {
    device_name = "/dev/xvdg"
    volume_type = "standard"
    volume_size = "${var.vol_size}"
    encrypted = true
  }
  ebs_block_device {
    device_name = "/dev/xvdh"
    volume_type = "standard"
    volume_size = "${var.vol_size}"
    encrypted = true
  }
  ebs_block_device {
    device_name = "/dev/xvdi"
    volume_type = "standard"
    volume_size = "${var.vol_size}"
    encrypted = true
  }

  connection {
    user = "ubuntu"
    key_file = "ssh/awsdemo"
    agent = false
  }

  provisioner "file" {
    source = "../scripts/${var.prov_scrpt}"
    destination = "/tmp/${var.prov_scrpt}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo hostnamectl set-hostname ${format("%s-%02d", var.hst_nme, count.index + 1)}",
      "if ! grep -E \"^ *127.0.0.1 +${format("%s-%02d.%s", var.hst_nme, count.index + 1, var.sub_dmn)} +$(hostname)\" /etc/hosts > /dev/null 2>&1; then   echo \"127.0.0.1 ${format("%s-%02d.%s", var.hst_nme, count.index + 1, var.sub_dmn)} $(hostname)\"|sudo tee -a /etc/hosts; fi",
      "if ! grep -E \"^ *${self.private_ip} +${format("%s-%02d.%s", var.hst_nme, count.index + 1, var.sub_dmn)} +$(hostname)\" /etc/hosts > /dev/null 2>&1; then   echo \"${self.private_ip} ${format("%s-%02d.%s", var.hst_nme, count.index + 1, var.sub_dmn)} $(hostname)\"|sudo tee -a /etc/hosts; fi",
      "bash /tmp/${var.prov_scrpt}",
      "rm -fv /tmp/terraform*.sh"
    ]
  }

}

resource "aws_route53_record" "awsvm" {
  count = "${var.num_nds}"
  zone_id = "${var.zone_id}"
  name = "${format("%s-%02d", var.hst_nme, count.index + 1)}"
  type ="CNAME"
  ttl = "300"
  records = ["${element(aws_instance.awsvm.*.public_dns, count.index)}"]
}


output "awsvm_id" {
  value = "${join(",", aws_instance.awsvm.*.id)}"
}

output "awsvm_public_ip" {
  value = "${join(",", aws_instance.awsvm.*.public_ip)}"
}

output "awsvm_private_ip" {
  value = "${join(",", aws_instance.awsvm.*.private_ip)}"
}

output "awsvm_public_dns" {
  value = "${join(",", aws_instance.awsvm.*.public_dns)}"
}
