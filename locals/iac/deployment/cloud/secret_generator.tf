resource "tls_private_key" "argocd_ssh" {
  algorithm = "RSA"
  rsa_bits  = 2048
}