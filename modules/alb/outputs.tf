output "user_tg_arn" {
  value = aws_lb_target_group.user_tg.arn
}

output "board_tg_arn" {
  value = aws_lb_target_group.board_tg.arn
}

output "monitoring_tg_arn" {
  value = aws_lb_target_group.monitoring_tg.arn
}