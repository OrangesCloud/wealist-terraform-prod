output "backend_asg_name" {
  description = "Name of the backend Auto Scaling Group"
  value       = aws_autoscaling_group.backend.name
}

output "backend_asg_arn" {
  description = "ARN of the backend Auto Scaling Group"
  value       = aws_autoscaling_group.backend.arn
}

output "monitoring_asg_name" {
  description = "Name of the monitoring Auto Scaling Group"
  value       = aws_autoscaling_group.monitoring.name
}
