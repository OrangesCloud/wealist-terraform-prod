# =============================================================================
# S3 버킷 및 보안 설정 (wealist-app-artifacts / wealist-codedeploy-artifacts)
# =============================================================================

# -----------------------------------------------------------------------------
# 1. 애플리케이션 데이터 버킷 (wealist-app-artifacts)
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "app_data_bucket" {
  bucket = "wealist-app-artifacts" # 💡 사용자 지정 이름 사용

  tags = {
    # 💡 태그 정책 반영 및 소문자 통일
    Name                = "wealist-app-artifacts"
    Environment         = "production"
    Project             = "wealist-prod"
    CostCenter          = "DevOps-001"
    DataClassification  = "Internal"
    RetentionPolicy     = "90Days"
    ManagedBy           = "Application" # CI/CD가 아닌 애플리케이션 런타임이 관리
  }
}

# 💡 퍼블릭 액세스 차단 활성화 (필수)
resource "aws_s3_bucket_public_access_block" "app_data_public_access" {
  bucket                  = aws_s3_bucket.app_data_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 💡 객체 소유권 강제 및 버전 관리 활성화 (보안 및 데이터 무결성)
resource "aws_s3_bucket_ownership_controls" "app_data_ownership" {
  bucket = aws_s3_bucket.app_data_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "app_data_versioning" {
  bucket = aws_s3_bucket.app_data_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}


# -----------------------------------------------------------------------------
# 2. CodeDeploy 아티팩트 버킷 (wealist-codedeploy-artifacts)
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "cd_artifact_bucket" {
  bucket = "wealist-codedeploy-artifacts" # 💡 사용자 지정 이름 사용

  # ❌ Deprecated 경고를 유발했던 server_side_encryption_configuration 블록을 제거했습니다. 
  #    -> 이제 이 역할은 아래의 aws_s3_bucket_server_side_encryption_configuration 리소스가 담당합니다.

  tags = {
    # 💡 태그 정책 반영 및 CI/CD 전용 태그 추가
    Name                = "wealist-codedeploy-artifacts"
    Environment         = "production"
    Project             = "wealist-prod"
    CostCenter          = "DevOps-001"
    DataClassification  = "Internal"
    RetentionPolicy     = "90Days"
    ManagedBy           = "CodeDeploy"
  }
}

# 💡 퍼블릭 액세스 차단 활성화 (매우 중요)
resource "aws_s3_bucket_public_access_block" "cd_artifact_public_access" {
  bucket                  = aws_s3_bucket.cd_artifact_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 💡 객체 소유권 강제 및 버전 관리 활성화 (롤백 무결성 보장)
resource "aws_s3_bucket_ownership_controls" "cd_artifact_ownership" {
  bucket = aws_s3_bucket.cd_artifact_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "cd_artifact_versioning" {
  bucket = aws_s3_bucket.cd_artifact_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}


# -----------------------------------------------------------------------------
# 3. S3 버킷 서버 측 암호화 설정 (모범 사례 - 독립 리소스)
# -----------------------------------------------------------------------------

# wealist-codedeploy-artifacts 버킷의 암호화 설정
resource "aws_s3_bucket_server_side_encryption_configuration" "cd_artifact_encryption" {
  # aws_s3_bucket.cd_artifact_bucket 리소스와 연결
  bucket = aws_s3_bucket.cd_artifact_bucket.id

  rule {
    # 기본 암호화 규칙: AES256을 사용
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# wealist-app-artifacts 버킷의 암호화 설정 (이 버킷에도 명시적으로 추가)
resource "aws_s3_bucket_server_side_encryption_configuration" "app_data_encryption" {
  # aws_s3_bucket.app_data_bucket 리소스와 연결
  bucket = aws_s3_bucket.app_data_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


# -----------------------------------------------------------------------------
# 4. SSM Parameter 업데이트 (버킷 이름 참조 - main.tf에서 옮겨온 경우)
# -----------------------------------------------------------------------------
# 이 파라미터들은 S3 리소스의 ID (버킷 이름)를 참조합니다.
# NOTE: 이 블록은 main.tf에 있었을 수도 있습니다. 일관성을 위해 s3.tf에 그대로 두는 것도 좋습니다.

resource "aws_ssm_parameter" "app_data_s3_bucket" {
  name      = "/wealist/prod/s3/app_artifacts_bucket_name"
  type      = "String"
  value     = aws_s3_bucket.app_data_bucket.id
  overwrite = true
}

resource "aws_ssm_parameter" "cd_artifact_s3_bucket" {
  name      = "/wealist/prod/cd/codedeploy_artifact_bucket_name"
  type      = "String"
  value     = aws_s3_bucket.cd_artifact_bucket.id
  overwrite = true
}