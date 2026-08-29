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

resource "aws_elasticache_cluster" "redis" {
  cluster_id    = "${var.project_name}-${var.environment}-redis"
  engine        = "redis"
  engine_version = var.engine_version
  node_type     = var.node_type
  num_cache_nodes = 1
  subnet_group_name   = aws_elasticache_subnet_group.redis.name
  security_group_ids  = [aws_security_group.redis.id]
  port                = var.port
  parameter_group_name = null

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
    host = aws_elasticache_cluster.redis.cache_nodes[0].address
    port = aws_elasticache_cluster.redis.port
    uri  = var.auth_token != "" ? "redis://:${var.auth_token}@${aws_elasticache_cluster.redis.cache_nodes[0].address}:${aws_elasticache_cluster.redis.port}" : "redis://${aws_elasticache_cluster.redis.cache_nodes[0].address}:${aws_elasticache_cluster.redis.port}"
  })

  depends_on = [aws_elasticache_cluster.redis]
}
