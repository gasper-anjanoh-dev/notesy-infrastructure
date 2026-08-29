output "scalable_resource_id" {
  description = "Resource id used for app autoscaling (service/<cluster>/<service>)"
  value       = aws_appautoscaling_target.ecs.resource_id
}

output "cpu_policy_arn" {
  description = "ARN of the CPU target tracking policy"
  value       = aws_appautoscaling_policy.cpu.arn
}

output "memory_policy_arn" {
  description = "ARN of the Memory target tracking policy"
  value       = aws_appautoscaling_policy.memory.arn
}
