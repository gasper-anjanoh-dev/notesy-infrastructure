variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "scope" {
  description = "CLOUDFRONT or REGIONAL"
  type        = string
  default     = "REGIONAL"
}

variable "rate_limit" {
  description = "Max requests per IP per 5 minutes"
  type        = number
  default     = 2000
}
