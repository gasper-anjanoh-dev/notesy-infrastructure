resource "aws_security_group" "rds" {
  name        = "${var.project_name}-${var.environment}-rds-sg"
  description = "Security group for RDS; ingress controlled externally to avoid cycles"
  vpc_id      = try(var.vpc_id, null)

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({
    Name        = "${var.project_name}-${var.environment}-rds-sg"
    Environment = var.environment
    ManagedBy   = "terraform"
  }, var.tags)
}

resource "aws_db_subnet_group" "rds" {
  name       = "${var.project_name}-${var.environment}-rds-subnets"
  subnet_ids = var.private_subnet_ids

  tags = merge({
    Name        = "${var.project_name}-${var.environment}-rds-subnets"
    Environment = var.environment
  }, var.tags)
}

resource "random_password" "rds_master" {
  length           = 16
  special          = true
}

resource "aws_db_instance" "db" {
  identifier              = "${var.project_name}-${var.environment}-db"
  allocated_storage      = var.allocated_storage
  engine                  = "postgres"
  engine_version          = var.engine_version
  instance_class          = var.db_instance_class
  db_name                 = var.db_name
  username                = var.db_username
  password                = random_password.rds_master.result
  db_subnet_group_name    = aws_db_subnet_group.rds.name
  vpc_security_group_ids  = [aws_security_group.rds.id]
  multi_az                = var.multi_az
  storage_encrypted       = true
  backup_retention_period = var.backup_retention
  publicly_accessible     = false
  skip_final_snapshot     = true

  kms_key_id = var.kms_key_id != "" ? var.kms_key_id : null

  tags = merge({
    Name        = "${var.project_name}-${var.environment}-db"
    Environment = var.environment
    ManagedBy   = "terraform"
  }, var.tags)
}

resource "aws_secretsmanager_secret" "db_secret" {
  name = "${var.project_name}-${var.environment}-db-credentials"

  tags = merge({
    Environment = var.environment
    ManagedBy   = "terraform"
  }, var.tags)
}

resource "aws_secretsmanager_secret_version" "db_secret_value" {
  secret_id     = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.rds_master.result
    host     = aws_db_instance.db.address
    port     = aws_db_instance.db.port
    dbname   = var.db_name
    uri      = "postgres://${var.db_username}:${random_password.rds_master.result}@${aws_db_instance.db.address}:${aws_db_instance.db.port}/${var.db_name}"
  })

  depends_on = [aws_db_instance.db]
}
