resource "tls_private_key" "test" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "test" {
  key_algorithm   = "ECDSA"
  private_key_pem = tls_private_key.test.private_key_pem

  subject {
    common_name  = var.cmnme
    organization = var.orgnme
  }

  validity_period_hours = var.vldthrs

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "template_dir" "test" {
  source_dir      = "./certs/in"
  destination_dir = "./certs/out"

  vars = {
    prvkey = tls_private_key.test.private_key_pem
    cert   = tls_self_signed_cert.test.cert_pem
  }
}

