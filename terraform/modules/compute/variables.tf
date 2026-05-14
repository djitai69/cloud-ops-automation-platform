variable "vpc_id" {
  type        = string
  description = "VPC to deploy compute resources into"
}

variable "subnet_id" {
  type        = string
  description = "Public subnet for the EC2 instance"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  default     = []
  description = "CIDR blocks permitted to reach port 22; empty disables SSH ingress"
}
