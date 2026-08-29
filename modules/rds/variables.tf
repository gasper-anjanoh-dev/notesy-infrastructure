variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the RDS subnet group"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group ID of ECS tasks allowed to access RDS"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "notesy"
}

variable "db_username" {
  description = "Master username for the DB"
  type        = string
  default     = "notesy"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t4g.medium"
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 20
}

variable "backup_retention" {
  description = "Automated backup retention days"
  type        = number
  default     = 7
}

variable "kms_key_id" {
  description = "KMS key id to use for encryption (optional)"
  type        = string
  default     = ""
}

variable "multi_az" {
  description = "Enable Multi-AZ for high availability"
  type        = bool
  default     = true
}

variable "engine_version" {
  description = "Postgres engine version"
  type        = string
  default     = "15"
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
