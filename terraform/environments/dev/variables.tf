variable "ssh_public_key" {
  type        = string
  description = "OpenSSH-formatted public key for the EC2 key pair. Set via TF_VAR_ssh_public_key or terraform.tfvars."
}
