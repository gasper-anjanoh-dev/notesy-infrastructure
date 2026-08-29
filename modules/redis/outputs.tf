output "redis_endpoint" {
  description = "Primary endpoint address for Redis"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "redis_port" {
  description = "Redis port"
  value       = aws_elasticache_replication_group.redis.port
}

output "redis_security_group_id" {
  description = "Security group id used by Redis"
  value       = aws_security_group.redis.id
}

output "redis_secret_arn" {
  description = "ARN of the Secrets Manager secret containing Redis connection info"
  value       = aws_secretsmanager_secret.redis_secret.arn
}
