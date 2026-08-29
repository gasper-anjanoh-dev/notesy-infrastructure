output "db_endpoint" {
  description = "RDS endpoint address"
  value       = aws_db_instance.db.address
}

output "db_port" {
  description = "RDS endpoint port"
  value       = aws_db_instance.db.port
}

output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret containing DB creds"
  value       = aws_secretsmanager_secret.db_secret.arn
}

output "db_security_group_id" {
  description = "Security group ID used by RDS"
  value       = aws_security_group.rds.id
}
