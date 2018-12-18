resource "tls_private_key" "test" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "test" {
  key_algorithm   = "ECDSA"
  private_key_pem = "${tls_private_key.test.private_key_pem}"

  subject {
    common_name  = "richnusgeeks.com"
    organization = "richnusgeeks, Inc"
  }

  validity_period_hours = 8760

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "template_dir" "test" {
  source_dir      = "./certs/in"
  destination_dir = "./certs/out"

  vars {
    prvkey = "${tls_private_key.test.private_key_pem}"
    cert   = "${tls_self_signed_cert.test.cert_pem}"
  }
}

#output "test_pubkey" {
#  value = "${tls_private_key.test.public_key_pem}"
#}
#
#output "test_pvtkey" {
#  value = "${tls_private_key.test.private_key_pem}"
#}
#
#output "test_certpem" {
#  value = "${tls_self_signed_cert.test.cert_pem}"
#}
#
#output "test_certpem_start" {
#  value = "${tls_self_signed_cert.test.validity_start_time}"
#}
#
#output "test_certpem_end" {
#  value = "${tls_self_signed_cert.test.validity_end_time}"
#}
