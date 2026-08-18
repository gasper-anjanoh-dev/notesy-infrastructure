output "cloudfront_url" {
  description = "CloudFront URL to access the application"
  value       = "https://${module.cdn.cloudfront_domain_name}"
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.alb.alb_dns_name
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}
