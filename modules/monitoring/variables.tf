variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "alb_name" {
  description = "ALB name (load balancer)"
  type        = string
}

variable "target_group_arn" {
  description = "Target group ARN for ALB"
  type        = string
}

variable "ecs_cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "ecs_service_name" {
  description = "ECS service name"
  type        = string
}

variable "rds_db_instance_identifier" {
  description = "RDS DB instance identifier"
  type        = string
}

variable "redis_replication_group_id" {
  description = "ElastiCache Replication Group ID"
  type        = string
}

variable "waf_web_acl_arn" {
  description = "WAF WebACL ARN"
  type        = string
  default     = ""
}

variable "alarm_email" {
  description = "Email address to subscribe to SNS alarms"
  type        = string
  default     = "ninogasper@gmail.com"
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

variable "aws_region" {
  description = "AWS region for dashboard widgets"
  type        = string
  default     = "us-east-1"
}
