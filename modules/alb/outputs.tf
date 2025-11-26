output "user_tg_arn" {
  description = "ARN of User service target group"
  value       = aws_lb_target_group.user_tg.arn
}

output "board_tg_arn" {
  description = "ARN of Board service target group"
  value       = aws_lb_target_group.board_tg.arn
}

output "monitoring_tg_arn" {
  description = "ARN of Monitoring service target group"
  value       = aws_lb_target_group.monitoring_tg.arn
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Hosted zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "user_tg_name" {
  description = "Name of User service target group"
  value       = aws_lb_target_group.user_tg.name
}

output "board_tg_name" {
  description = "Name of Board service target group"
  value       = aws_lb_target_group.board_tg.name
}