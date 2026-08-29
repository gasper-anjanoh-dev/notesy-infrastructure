variable "app_image" {
  description = "Docker image for the application"
  type        = string
  default     = "ghcr.io/gasper-anjanoh-dev/notesy-app:latest"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "notesy"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "notesy"
}

variable "db_instance_class" {
  description = "RDS instance class for dev"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "RDS allocated storage (GB)"
  type        = number
  default     = 20
}

variable "backup_retention" {
  description = "RDS backup retention days"
  type        = number
  default     = 1
}

variable "kms_key_id" {
  description = "KMS key id for RDS encryption (optional)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags map"
  type        = map(any)
  default     = {}
}

variable "redis_node_type" {
  description = "ElastiCache node type for dev"
  type        = string
  default     = "cache.t3.micro"
}

variable "redis_engine_version" {
  description = "ElastiCache engine version"
  type        = string
  default     = "6.x"
}

variable "redis_auth_token" {
  description = "Auth token for Redis (optional for dev)"
  type        = string
  default     = ""
}

variable "alarm_email" {
  description = "Email for CloudWatch alarm notifications"
  type        = string
  default     = ""
}
