# 현재 AWS 계정 ID와 리전 정보를 가져오기 위한 Data Source (ARN 생성용)
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# 1. IAM 역할 (Role)
resource "aws_iam_role" "ec2_role" {
  name = "${var.name_prefix}-ec2-role"

  description = "IAM role for ${var.name_prefix} EC2 (SSM, ECR, S3, CodeDeploy)"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.name_prefix}-ec2-role"
    ManagedBy   = "terraform"
    Project     = "wealist"
  }
}

# 2. 인스턴스 프로파일
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.name_prefix}-ec2-profile"
  role = aws_iam_role.ec2_role.name

  tags = {
    Name = "${var.name_prefix}-ec2-profile"
  }
}

# =============================================================================
# [A] AWS 관리형 정책 연결 (기본 인프라 관리용)
# =============================================================================

# 1. SSM Managed Instance Core (SSM Agent 통신 및 Session Manager 접속용)
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# 2. CodeDeploy Agent 권한 (배포 자동화용 - 요청사항 4번)
# CodeDeploy Agent가 S3에서 번들을 받고 배포 상태를 보고하는데 필요한 표준 권한
resource "aws_iam_role_policy_attachment" "codedeploy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
}

# 3. CloudWatch Agent (선택 사항 - 로그/메트릭 수집이 필요하다면 추가 권장)
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}


# =============================================================================
# [B] 커스텀 인라인 정책 (애플리케이션 및 배포 로직용)
# =============================================================================

# 3. 시크릿 및 설정 접근 권한 (SSM/KMS) - 요청사항 1번
resource "aws_iam_role_policy" "ssm_kms_access" {
  name = "${var.name_prefix}-ssm-kms-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "SSMParameterRead"
        Effect   = "Allow"
        Action   = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        # ⭐️ 해당 환경(name_prefix) 경로 하위의 파라미터만 읽도록 제한
        # 예: arn:aws:ssm:ap-northeast-2:123456789:parameter/wealist/prod/*
        Resource = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/wealist/*"
      },
      {
        Sid      = "KMSDecrypt"
        Effect   = "Allow"
        Action   = "kms:Decrypt"
        # ⭐️ SecureString 복호화를 위해 KMS 키 사용 허용 (모든 키 또는 특정 키 ARN 지정)
        Resource = "*"
      }
    ]
  })
}

# 4. ECR 도커 이미지 접근 권한 (ECR) - 요청사항 2번
resource "aws_iam_role_policy" "ecr_access" {
  name = "${var.name_prefix}-ecr-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ECRLogin"
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Sid      = "ECRPull"
        Effect   = "Allow"
        Action   = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        # ⭐️ 해당 프로젝트 리포지토리만 접근 허용
        Resource = "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/${var.name_prefix}-*"
      }
    ]
  })
}

# 5. 애플리케이션 S3 파일 접근 권한 (S3) - 요청사항 3번 & 4번(배포 스크립트)
# User/Board 서비스의 파일 업로드/다운로드 및 CodeDeploy의 스크립트 다운로드 통합
resource "aws_iam_role_policy" "s3_access" {
  name = "${var.name_prefix}-s3-policy"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "S3ListBucket"
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = [
          "arn:aws:s3:::wealist-deploy-scripts", # 배포 스크립트 버킷
          "arn:aws:s3:::wealist-frontend"        # (필요시) 프론트엔드/업로드 버킷
        ]
      },
      {
        Sid      = "S3ObjectAccess"
        Effect   = "Allow"
        Action   = [
          "s3:GetObject",       # 읽기 (배포 스크립트, 이미지 다운로드)
          "s3:PutObject",       # 쓰기 (프로필 이미지 업로드)
          "s3:DeleteObject"     # 삭제 (파일 삭제)
        ]
        Resource = [
          "arn:aws:s3:::wealist-deploy-scripts/*",
          "arn:aws:s3:::wealist-frontend/*"
        ]
      }
    ]
  })
}

# =============================================================================
# [C] CodeDeploy Service Role (배포 오케스트레이션용)
# =============================================================================

# CodeDeploy Service Role
# CodeDeploy 서비스가 Auto Scaling Group, Load Balancer, EC2를 제어하기 위한 Role
resource "aws_iam_role" "codedeploy_service_role" {
  name        = "${var.name_prefix}-codedeploy-role"
  description = "Service role for CodeDeploy to manage Auto Scaling Groups and Load Balancers"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name      = "${var.name_prefix}-codedeploy-role"
    ManagedBy = "terraform"
    Project   = "wealist"
  }
}

# AWS 관리형 정책 연결: AWSCodeDeployRole
# ASG, ELB, EC2 제어 권한 포함
resource "aws_iam_role_policy_attachment" "codedeploy_service" {
  role       = aws_iam_role.codedeploy_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}