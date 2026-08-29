variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ElastiCache subnet group"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group ID of ECS tasks allowed to access Redis"
  type        = string
}

variable "node_type" {
  description = "ElastiCache node type"
  type        = string
  default     = "cache.t4g.small"
}

variable "engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7"
}

variable "num_cache_clusters" {
  description = "Number of cache clusters (single node for dev)"
  type        = number
  default     = 1
}

variable "port" {
  description = "Redis port"
  type        = number
  default     = 6379
}

variable "transit_encryption_enabled" {
  description = "Enable in-transit encryption"
  type        = bool
  default     = true
}

variable "at_rest_encryption_enabled" {
  description = "Enable at-rest encryption"
  type        = bool
  default     = true
}

variable "auth_token" {
  description = "Optional AUTH token for Redis (if empty, no AUTH)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
