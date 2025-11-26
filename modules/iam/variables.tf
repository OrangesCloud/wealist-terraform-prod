variable "name_prefix" {
  description = "Environment prefix (e.g., wealist-prod, wealist-dev)"
  type        = string
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
  description = "GitHub organization name"
  type        = string
  default     = "wealist-project"
}

variable "github_repo" {
  description = "GitHub repository name (without org)"
  type        = string
  default     = "*" # 모든 리포지토리 허용, 특정 리포를 지정하려면 "wealist-backend" 같은 값 사용
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