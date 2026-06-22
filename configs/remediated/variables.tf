variable "aws_region" {
  description = "AWS region for the lab. Use a region with at least two Availability Zones."
  type        = string
  default     = "us-east-1"
}

variable "admin_cidr" {
  description = "Approved administrator public IP CIDR, for example 203.0.113.10/32."
  type        = string
  default     = "203.0.113.10/32"
}

variable "database_password" {
  description = "Lab database password. Do not reuse real passwords."
  type        = string
  sensitive   = true
}
