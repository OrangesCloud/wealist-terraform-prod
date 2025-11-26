output "user_app_name" {
  description = "CodeDeploy application name for User service"
  value       = aws_codedeploy_app.user_app.name
}

output "board_app_name" {
  description = "CodeDeploy application name for Board service"
  value       = aws_codedeploy_app.board_app.name
}

output "user_deployment_group_primary" {
  description = "CodeDeploy deployment group name for User service (primary)"
  value       = aws_codedeploy_deployment_group.user_dg_primary.deployment_group_name
}

output "user_deployment_group_tg" {
  description = "CodeDeploy deployment group name for User service (target group)"
  value       = aws_codedeploy_deployment_group.user_dg_tg.deployment_group_name
}

output "board_deployment_group_primary" {
  description = "CodeDeploy deployment group name for Board service (primary)"
  value       = aws_codedeploy_deployment_group.board_dg_primary.deployment_group_name
}

output "board_deployment_group_tg" {
  description = "CodeDeploy deployment group name for Board service (target group)"
  value       = aws_codedeploy_deployment_group.board_dg_tg.deployment_group_name
}
