variable "name_prefix" {
  description = "Environment prefix (e.g., wealist-prod, wealist-dev)"
  type        = string
}

variable "environment" {
  description = "Environment name for SSM paths (e.g., prod, dev)"
  type        = string
  default     = "prod"
}

variable "role_name" {
  description = "EC2 IAM role name"
  type        = string
}

variable "profile_name" {
  description = "EC2 instance profile name"
  type        = string
}

# GitHub Actions OIDC 관련 변수
variable "github_org" {
  description = "GitHub organization name (case-sensitive!)"
  type        = string
  default     = "orangescloud"
}

variable "github_repo" {
  description = "GitHub repository name (without org)"
  type        = string
  default     = "wealist-project"
}

variable "github_branch" {
  description = "GitHub branch allowed to assume role"
  type        = string
  default     = "deploy-prod"
}

# S3 버킷 이름 (CodeDeploy artifacts)
variable "codedeploy_s3_bucket" {
  description = "S3 bucket name for CodeDeploy artifacts"
  type        = string
  default     = "wealist-codedeploy-artifacts"
}

variable "app_data_s3_bucket" {
  description = "S3 bucket name for application data"
  type        = string
  default     = "wealist-app-artifacts"
}