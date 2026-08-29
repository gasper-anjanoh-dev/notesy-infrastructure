resource "aws_security_group" "redis" {
  name        = "${var.project_name}-${var.environment}-redis-sg"
  description = "Security group for ElastiCache Redis; ingress controlled externally to avoid cycles"
  vpc_id      = try(var.vpc_id, null)

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({
    Name        = "${var.project_name}-${var.environment}-redis-sg"
    Environment = var.environment
    ManagedBy   = "terraform"
  }, var.tags)
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.project_name}-${var.environment}-redis-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = merge({
    Name        = "${var.project_name}-${var.environment}-redis-subnet-group"
    Environment = var.environment
  }, var.tags)
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id          = "${var.project_name}-${var.environment}-redis-rg"
  replication_group_description = "Redis replication group for ${var.project_name}-${var.environment}"
  engine                        = "redis"
  engine_version                = var.engine_version
  node_type                     = var.node_type
  number_cache_clusters         = var.num_cache_clusters
  automatic_failover_enabled    = false
  subnet_group_name             = aws_elasticache_subnet_group.redis.name
  security_group_ids            = [aws_security_group.redis.id]
  port                          = var.port
  transit_encryption_enabled    = var.transit_encryption_enabled
  at_rest_encryption_enabled    = var.at_rest_encryption_enabled

  dynamic "auth_token" {
    for_each = var.auth_token != "" ? [1] : []
    content {
      auth_token = var.auth_token
    }
  }

  tags = merge({
    Name        = "${var.project_name}-${var.environment}-redis"
    Environment = var.environment
    ManagedBy   = "terraform"
  }, var.tags)
}

resource "aws_secretsmanager_secret" "redis_secret" {
  name = "${var.project_name}-${var.environment}-redis-credentials"

  tags = merge({
    Environment = var.environment
    ManagedBy   = "terraform"
  }, var.tags)
}

resource "aws_secretsmanager_secret_version" "redis_secret_value" {
  secret_id     = aws_secretsmanager_secret.redis_secret.id
  secret_string = jsonencode({
    host = aws_elasticache_replication_group.redis.primary_endpoint_address
    port = aws_elasticache_replication_group.redis.port
    uri  = var.auth_token != "" ? "redis://:${var.auth_token}@${aws_elasticache_replication_group.redis.primary_endpoint_address}:${aws_elasticache_replication_group.redis.port}" : "redis://${aws_elasticache_replication_group.redis.primary_endpoint_address}:${aws_elasticache_replication_group.redis.port}"
  })

  depends_on = [aws_elasticache_replication_group.redis]
}
