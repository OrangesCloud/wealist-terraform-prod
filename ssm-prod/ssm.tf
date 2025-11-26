# =============================================================================
# SSM Parameter Store (Secrets & Configuration)
# =============================================================================

# -----------------------------------------------------------------------------
# 1. 데이터 소스 및 KMS 키 (SecureString 암호화용)
# -----------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

resource "aws_kms_key" "ssm_kms" {
  description             = "${var.project_name}-SSM-SecureString-Key"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  tags = { Name = "${var.project_name}-SSM-KMS" }
}

# -----------------------------------------------------------------------------
# 2. SecureString (민감 정보 저장)
# -----------------------------------------------------------------------------
resource "aws_ssm_parameter" "rds_master_password" {
  name  = "/wealist/prod/db/rds_master_password"
  type  = "SecureString"
  value = var.db_password
  key_id = aws_kms_key.ssm_kms.arn
  overwrite = true
}

resource "aws_ssm_parameter" "redis_auth_token" {
  name  = "/wealist/prod/cache/redis_auth_token"
  type  = "SecureString"
  value = var.redis_auth_token
  key_id = aws_kms_key.ssm_kms.arn
  overwrite = true
}

resource "aws_ssm_parameter" "jwt_secret" {
  name  = "/wealist/prod/jwt/jwt_secret"
  type  = "SecureString"
  value = var.jwt_secret
  key_id = aws_kms_key.ssm_kms.arn
  overwrite = true
}

resource "aws_ssm_parameter" "google_client_secret" {
  name  = "/wealist/prod/oauth/google-client-secret"
  type  = "SecureString"
  value = var.google_client_secret
  key_id = aws_kms_key.ssm_kms.arn
  overwrite = true
}

resource "aws_ssm_parameter" "user_db_password" {
  name  = "/wealist/prod/db/user_db_password"
  type  = "SecureString"
  value = var.user_db_password
  key_id = aws_kms_key.ssm_kms.arn
  overwrite = true
}

resource "aws_ssm_parameter" "board_db_password" {
  name  = "/wealist/prod/db/board_db_password"
  type  = "SecureString"
  value = var.board_db_password
  key_id = aws_kms_key.ssm_kms.arn
  overwrite = true
}


# -----------------------------------------------------------------------------
# 3. String (엔드포인트 및 기타 설정 정보 저장)
# -----------------------------------------------------------------------------

# RDS 및 ElastiCache 엔드포인트
resource "aws_ssm_parameter" "rds_endpoint" {
  name  = "/wealist/prod/db/rds_host"
  type  = "String"
  value = var.rds_cluster_endpoint
  overwrite = true
}

resource "aws_ssm_parameter" "redis_endpoint" {
  name  = "/wealist/prod/cache/redis_host"
  type  = "String"
  value = var.redis_primary_endpoint
  overwrite = true
}

# RDS 마스터 사용자 이름
resource "aws_ssm_parameter" "rds_master_username" {
  name  = "/wealist/prod/db/rds_master_username"
  type  = "String"
  value = var.rds_master_username
  overwrite = true
}

# DB 이름
resource "aws_ssm_parameter" "user_db_name" {
  name  = "/wealist/prod/db/user_db_name"
  type  = "String"
  value = var.user_db_name_var
  overwrite = true
}

resource "aws_ssm_parameter" "board_db_name" {
  name  = "/wealist/prod/db/board_db_name"
  type  = "String"
  value = var.board_db_name_var
  overwrite = true
}


# OAuth 공개 설정
resource "aws_ssm_parameter" "google_client_id" {
  name  = "/wealist/prod/oauth/google_client_id"
  type  = "String"
  value = var.google_client_id
  overwrite = true
}

resource "aws_ssm_parameter" "oauth_redirect_url_base" {
  name  = "/wealist/prod/url/oauth2_client_redirect_base"
  type  = "String"
  value = var.oauth_redirect_url_base_var
  overwrite = true
}

resource "aws_ssm_parameter" "oauth_redirect_url_env" {
  name  = "/wealist/prod/url/oauth2_redirect_url"
  type  = "String"
  value = var.oauth_redirect_url_env_var
  overwrite = true
}