# main.tf

# -----------------------------------------------------------------------------
# 1. Terraform 설정 및 Provider 요구사항 정의
# -----------------------------------------------------------------------------
terraform {
  # 💡 Backend 설정: 기존 wealist-tfstate-bucket을 사용하여 State 파일 원격 관리
  backend "s3" {
    bucket = "wealist-tfstate-bucket" 
    key    = "prod/ssm-prod-cd.tfstate" 
    region = "ap-northeast-2"
    # 💡 필수: State 파일 충돌 방지 및 잠금(Locking)을 위한 DynamoDB 테이블 이름
    dynamodb_table = "wealist-terraform-locks" 
    encrypt = true # State 파일 암호화 활성화 (모범 사례)
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      # CodeDeploy, SSM, S3 등의 리소스를 안정적으로 지원하는 최신 버전 사용
      version = "~> 5.0" 
    }
  }
}
