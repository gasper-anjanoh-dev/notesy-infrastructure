variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ALB will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs for the ALB"
  type        = list(string)
}

variable "app_port" {
  description = "Port the application listens on"
  type        = number
  default     = 8000
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate to use for HTTPS listener (optional)"
  type        = string
  default     = ""
}
