variable "aws_region" {
  description = "AWS region for the lab. Use a region with at least two Availability Zones."
  type        = string
  default     = "us-east-1"
}

variable "database_password" {
  description = "Lab database password. Do not reuse real passwords."
  type        = string
  sensitive   = true
}
