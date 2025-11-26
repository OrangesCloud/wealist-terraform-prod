variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "codedeploy_service_role_arn" {
  description = "ARN of the CodeDeploy service role"
  type        = string
}

variable "backend_asg_name" {
  description = "Name of the backend Auto Scaling Group"
  type        = string
}

variable "user_target_group_name" {
  description = "Name of the User service target group"
  type        = string
}

variable "board_target_group_name" {
  description = "Name of the Board service target group"
  type        = string
}
