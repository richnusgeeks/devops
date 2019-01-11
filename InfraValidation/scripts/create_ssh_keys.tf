resource "tls_private_key" "test" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "template_dir" "test" {
  source_dir      = "./keys/in"
  destination_dir = "./keys/out"

  vars {
    prvkey = "${tls_private_key.test.private_key_pem}"
    pubkey = "${tls_private_key.test.public_key_openssh}"
  }

  provisioner "local-exec" {
    command = "chmod 0400 keys/out/test"
  }
}
