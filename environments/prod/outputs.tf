# =============================================================================
# Output Values for Production Environment
# =============================================================================

# ---------------
# Network Outputs
# ---------------
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value = [
    module.vpc.private_subnet_1_id,
    module.vpc.private_subnet_2_id,
    module.vpc.private_subnet_3_id
  ]
}

# ---------------
# IAM Outputs
# ---------------
output "ec2_instance_profile_name" {
  description = "EC2 instance profile name"
  value       = module.iam.instance_profile_name
}

output "codedeploy_service_role_arn" {
  description = "CodeDeploy service role ARN (use this when creating CodeDeploy applications)"
  value       = module.iam.codedeploy_service_role_arn
}

output "github_actions_role_arn" {
  description = "GitHub Actions OIDC role ARN (add this to GitHub Actions workflow)"
  value       = module.iam.github_actions_role_arn
}

output "github_actions_role_name" {
  description = "GitHub Actions OIDC role name"
  value       = module.iam.github_actions_role_name
}

# ---------------
# ECR Outputs
# ---------------
output "ecr_board_service_url" {
  description = "ECR repository URL for board service"
  value       = module.ecr.board_repo_url
}

output "ecr_user_service_url" {
  description = "ECR repository URL for user service"
  value       = module.ecr.user_repo_url
}

# ---------------
# ALB Outputs
# ---------------
output "alb_dns_name" {
  description = "ALB DNS name"
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "ALB hosted zone ID"
  value       = module.alb.alb_zone_id
}

# ---------------
# ElastiCache Outputs
# ---------------
output "redis_endpoint" {
  description = "Redis primary endpoint address"
  value       = module.elasticache.replication_group_primary_endpoint_address
}

# ---------------
# Database Outputs (SSM Parameter)
# ---------------
output "db_endpoint_ssm_parameter" {
  description = "SSM parameter name for RDS endpoint"
  value       = "/wealist/prod/db/endpoint"
}
