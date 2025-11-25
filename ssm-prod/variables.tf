# variables.tf

# =============================================================================
# 1. 환경 및 일반 설정
# =============================================================================
variable "aws_region" {
  description = "AWS 리전. 모든 인프라가 배포될 리전을 지정합니다."
  type        = string
  default     = "ap-northeast-2"
}

variable "project_name" {
  description = "AWS 리소스 태그 및 이름 접두사에 사용되는 프로젝트 이름입니다."
  type        = string
  default     = "wealist-prod"
}

# =============================================================================
# 2. SecureString (민감 정보 - SSM에 암호화되어 저장됨)
# =============================================================================
variable "db_password" {
  description = "RDS 클러스터 마스터 사용자 비밀번호 (Postgres Exporter 접속용 포함)."
  type        = string
  sensitive   = true
}

variable "redis_auth_token" {
  description = "ElastiCache Redis 인증 토큰."
  type        = string
  sensitive   = true
}

variable "jwt_secret" {
  description = "애플리케이션 JWT 토큰 서명 키 (최소 64바이트 권장)."
  type        = string
  sensitive   = true
}

variable "google_client_secret" {
  description = "Google OAuth 클라이언트 시크릿."
  type        = string
  sensitive   = true
}

variable "user_db_password" {
  description = "User Service가 사용하는 DB 계정의 비밀번호."
  type        = string
  sensitive   = true
}

variable "board_db_password" {
  description = "Board Service가 사용하는 DB 계정의 비밀번호."
  type        = string
  sensitive   = true
}

# =============================================================================
# 3. 인프라 Output 및 참조 값 (다른 Terraform 스택의 결과물)
# =============================================================================
variable "rds_cluster_endpoint" {
  description = "RDS 클러스터의 엔드포인트 주소 (host)."
  type        = string
}

variable "redis_primary_endpoint" {
  description = "ElastiCache Redis 클러스터의 주 엔드포인트 주소."
  type        = string
}

variable "rds_master_username" {
  description = "RDS 클러스터 마스터 사용자 이름 (Postgres Exporter 접속용)."
  type        = string
  default     = "dbmaster"
}

variable "user_service_target_group_name" {
  description = "User Service를 위한 ALB Target Group 이름 (CodeDeploy 연결용)."
  type        = string
}

variable "board_service_target_group_name" {
  description = "Board Service를 위한 ALB Target Group 이름 (CodeDeploy 연결용)."
  type        = string
}

# =============================================================================
# 4. 설정 값 및 S3 버킷 이름 (String)
# =============================================================================
variable "google_client_id" {
  description = "Google OAuth 클라이언트 ID."
  type        = string
}

variable "user_db_name_var" {
  description = "User Service가 사용할 PostgreSQL 데이터베이스 이름."
  type        = string
  default     = "wealist_user_db"
}

variable "board_db_name_var" {
  description = "Board Service가 사용할 PostgreSQL 데이터베이스 이름."
  type        = string
  default     = "wealist_board_db"
}

variable "oauth_redirect_url_base_var" {
  description = "Spring Security OAuth2 Client Redirect Base URL."
  type        = string
  default     = "https://api.wealist.co.kr"
}

variable "oauth_redirect_url_env_var" {
  description = "OAuth Success Handler 최종 Redirect URL."
  type        = string
  default     = "https://wealist.co.kr/oauth/callback"
}

variable "app_data_s3_bucket_name_var" {
  description = "애플리케이션 데이터(이미지 등)를 저장하는 S3 버킷 이름."
  type        = string
  default     = "wealist-app-artifacts"
}

variable "cd_artifact_s3_bucket_name_var" {
  description = "CodeDeploy 아티팩트(ZIP 파일)를 저장하는 S3 버킷 이름."
  type        = string
  default     = "wealist-codedeploy-artifacts"
}