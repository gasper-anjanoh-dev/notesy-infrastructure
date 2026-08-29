variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "alb_security_group_id" {
  type = string
}

variable "target_group_arn" {
  type = string
}

variable "app_image" {
  description = "Docker image for the application"
  type        = string
}

variable "app_port" {
  type    = number
  default = 8000
}

variable "cpu" {
  description = "Fargate CPU units"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Fargate memory in MB"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Number of ECS tasks to run"
  type        = number
  default     = 1
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "alb_listener_arn" {
  description = "ARN of the ALB listener to depend on"
  type        = string
  default     = ""
}

variable "db_secret_arn" {
  description = "ARN of the Secrets Manager secret containing DB credentials"
  type        = string
  default     = ""
}

variable "redis_secret_arn" {
  description = "ARN of the Secrets Manager secret containing Redis connection info"
  type        = string
  default     = ""
}

variable "cloudfront_domain" {
  description = "CloudFront distribution domain name (e.g. dxxxxx.cloudfront.net)"
  type        = string
  default     = ""
}

variable "django_secret_arn" {
  description = "ARN of the Secrets Manager secret containing Django SECRET_KEY"
  type        = string
  default     = ""
}

variable "alb_dns_name" {
  description = "DNS name of the ALB (used to populate allowed hosts)"
  type        = string
  default     = ""
}
