variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "alb_dns_name" {
  description = "DNS name of the ALB as the origin"
  type        = string
}

variable "waf_acl_arn" {
  description = "ARN of the WAF Web ACL"
  type        = string
}
