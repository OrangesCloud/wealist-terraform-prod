# Output
output "instance_profile_name" {
  description = "Name of the EC2 instance profile"
  value       = aws_iam_instance_profile.ec2_profile.name
}

output "ec2_role_arn" {
  description = "ARN of the EC2 IAM role"
  value       = aws_iam_role.ec2_role.arn
}

output "codedeploy_service_role_arn" {
  description = "ARN of the CodeDeploy Service Role"
  value       = aws_iam_role.codedeploy_service_role.arn
}

output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions OIDC role (use this in GitHub Actions workflow)"
  value       = aws_iam_role.github_actions.arn
}

output "github_actions_role_name" {
  description = "Name of the GitHub Actions OIDC role"
  value       = aws_iam_role.github_actions.name
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = aws_iam_openid_connect_provider.github_actions.arn
}