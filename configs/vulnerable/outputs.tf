output "public_bucket_name" {
  description = "Name of the intentionally public S3 bucket."
  value       = aws_s3_bucket.public_data.bucket
}

output "open_security_group_id" {
  description = "Security group with public ingress exposure."
  value       = aws_security_group.open_admin.id
}

output "public_rds_endpoint" {
  description = "Public endpoint of the intentionally exposed database."
  value       = aws_db_instance.public_postgres.endpoint
}

output "overprivileged_iam_user" {
  description = "IAM user with wildcard permissions."
  value       = aws_iam_user.overprivileged_user.name
}
