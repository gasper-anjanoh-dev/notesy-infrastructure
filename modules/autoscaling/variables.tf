variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cluster_name" {
  description = "ECS cluster name"
  type        = string
}

variable "service_name" {
  description = "ECS service name"
  type        = string
}

variable "min_capacity" {
  description = "Minimum number of tasks"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of tasks"
  type        = number
  default     = 10
}

variable "cpu_target" {
  description = "Target CPU utilization percentage for scaling (target tracking)"
  type        = number
  default     = 70
}

variable "memory_target" {
  description = "Target Memory utilization percentage for scaling (target tracking)"
  type        = number
  default     = 70
}

variable "scale_in_cooldown" {
  description = "Cooldown in seconds after a scale-in event"
  type        = number
  default     = 300
}

variable "scale_out_cooldown" {
  description = "Cooldown in seconds after a scale-out event"
  type        = number
  default     = 300
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
