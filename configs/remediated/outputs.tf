output "private_bucket_name" {
  description = "Name of the private S3 bucket."
  value       = aws_s3_bucket.private_data.bucket
}

output "restricted_admin_security_group_id" {
  description = "Security group with restricted administrator access."
  value       = aws_security_group.admin_restricted.id
}

output "private_database_security_group_id" {
  description = "Security group allowing database access from restricted security groups only."
  value       = aws_security_group.database_private.id
}

output "private_rds_endpoint" {
  description = "Private endpoint of the remediated database."
  value       = aws_db_instance.private_postgres.endpoint
}
