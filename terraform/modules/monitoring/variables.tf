variable "instance_id" {
  type        = string
  description = "EC2 instance ID to monitor"
}

variable "cpu_threshold" {
  type    = number
  default = 70
  description = "CPU utilisation % that triggers the high-CPU alarm"
}

variable "alert_email" {
  type    = string
  default = "itairose2121@gmail.com"
  description = "Email address for SNS alert notifications"
}
