# Output
output "instance_profile_name" {
  value = aws_iam_instance_profile.ec2_profile.name
}

output "ec2_role_arn" {
  description = "ARN of the EC2 IAM role"
  value       = aws_iam_role.ec2_role.arn
}

output "codedeploy_service_role_arn" {
  description = "ARN of the CodeDeploy Service Role"
  value       = aws_iam_role.codedeploy_service_role.arn
}