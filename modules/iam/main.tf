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
          "arn:aws:s3:::wealist-frontend",       # 프론트엔드 버킷
          "arn:aws:s3:::wealist-app-resources"   # 이미지 업로드 버킷
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
          "arn:aws:s3:::wealist-frontend/*",
          "arn:aws:s3:::wealist-app-resources/*"  # 이미지 업로드 버킷
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

# AWS 관리형 정책 연결: AWSCodeDeployDeployerAccess
# CodeDeploy 배포 생성 및 관리 권한
resource "aws_iam_role_policy_attachment" "codedeploy_deployer" {
  role       = aws_iam_role.codedeploy_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployDeployerAccess"
}

# 인라인 정책: EC2 및 ELB 추가 권한 (콘솔과 동일)
resource "aws_iam_role_policy" "codedeploy_ec2_elb" {
  name = "added-ec2-and-elasticloadbalancing"
  role = aws_iam_role.codedeploy_service_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "autoscaling:*"
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "cloudwatch:PutMetricAlarm"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeImages",
          "ec2:DescribeInstanceAttribute",
          "ec2:DescribeInstances",
          "ec2:DescribeKeyPairs",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:DescribePlacementGroups",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSpotInstanceRequests",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcClassicLink",
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "ec2:CreateLaunchTemplateVersion"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "iam:CreateServiceLinkedRole"
        Resource = "*"
        Condition = {
          StringEquals = {
            "iam:AWSServiceName" = "autoscaling.amazonaws.com"
          }
        }
      }
    ]
  })
}

# =============================================================================
# [D] GitHub Actions OIDC Provider 및 Role (CI/CD 파이프라인용)
# =============================================================================

# 1. GitHub OIDC Provider
# GitHub Actions가 AWS 리소스에 접근할 수 있도록 신뢰 관계를 설정합니다.
resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  # GitHub의 공개 Thumbprint (2024년 업데이트)
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
    "1b511abead59c6ce207077c0bf0e0043b1382612"
  ]

  # GitHub Actions에서 발급하는 토큰의 audience
  client_id_list = ["sts.amazonaws.com"]

  tags = {
    Name      = "${var.name_prefix}-github-oidc-provider"
    ManagedBy = "terraform"
    Project   = "wealist"
  }
}

# 2. GitHub Actions IAM Role
# GitHub Actions 워크플로우가 이 역할을 Assume하여 AWS 작업을 수행합니다.
resource "aws_iam_role" "github_actions" {
  name        = "${var.name_prefix}-github-actions-role"
  description = "Role for GitHub Actions CI/CD pipeline (OIDC)"

  # 신뢰 정책: 특정 GitHub Organization의 모든 리포지토리 허용
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # GitHub Organization의 모든 리포지토리와 브랜치 허용
            "token.actions.githubusercontent.com:sub" = [
              "repo:OrangesCloud/*",
              "repo:orangescloud/*"  # 소문자 버전도 추가
            ]
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.name_prefix}-github-actions-role"
    ManagedBy   = "terraform"
    Project     = "wealist"
    Environment = var.name_prefix
  }
}

# 3. GitHub Actions 권한 정책 (통합 - 중복 제거)
resource "aws_iam_role_policy" "github_actions_policy" {
  name = "${var.name_prefix}-github-actions-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # =========================================================================
      # [A] SSM Parameter Store 읽기/쓰기 (환경 변수, DB 자격 증명 등)
      # =========================================================================
      {
        Sid    = "SSMParameterReadWrite"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
          "ssm:PutParameter"
        ]
        Resource = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/wealist/${var.environment}/*"
      },
      {
        Sid      = "KMSDecrypt"
        Effect   = "Allow"
        Action   = "kms:Decrypt"
        Resource = "*"
      },
      {
        Sid    = "SSMSendCommand"
        Effect = "Allow"
        Action = [
          "ssm:SendCommand",
          "ssm:GetCommandInvocation",
          "ssm:ListCommandInvocations"
        ]
        Resource = [
          "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/*",
          "arn:aws:ssm:${data.aws_region.current.name}::document/AWS-RunShellScript"
        ]
      },

      # =========================================================================
      # [B] ECR - 도커 이미지 Push (CI 단계)
      # =========================================================================
      {
        Sid    = "ECRGetAuthToken"
        Effect = "Allow"
        Action = "ecr:GetAuthorizationToken"
        # GetAuthorizationToken은 리소스 레벨 권한이 없음
        Resource = "*"
      },
      {
        Sid    = "ECRImagePush"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:DescribeRepositories",
          "ecr:DescribeImages",
          "ecr:ListImages"
        ]
        Resource = "arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/${var.name_prefix}-*"
      },

      # =========================================================================
      # [C] S3 - CodeDeploy 아티팩트 업로드 및 애플리케이션 데이터
      # =========================================================================
      {
        Sid    = "S3CodeDeployArtifacts"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:DeleteObject"
        ]
        Resource = [
          "arn:aws:s3:::${var.codedeploy_s3_bucket}",
          "arn:aws:s3:::${var.codedeploy_s3_bucket}/*",
          "arn:aws:s3:::${var.app_data_s3_bucket}",
          "arn:aws:s3:::${var.app_data_s3_bucket}/*"
        ]
      },

      # =========================================================================
      # [D] CodeDeploy - 배포 생성 및 모니터링 (CD 단계)
      # =========================================================================
      {
        Sid    = "CodeDeployCreateDeployment"
        Effect = "Allow"
        Action = [
          "codedeploy:CreateDeployment",
          "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentConfig",
          "codedeploy:RegisterApplicationRevision",
          "codedeploy:GetApplicationRevision"
        ]
        Resource = [
          "arn:aws:codedeploy:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:application:wealist-user-app-codeDeploy",
          "arn:aws:codedeploy:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:application:wealist-board-app-codeDeploy",
          "arn:aws:codedeploy:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:deploymentgroup:wealist-user-app-codeDeploy/${var.name_prefix}-deploy-group",
          "arn:aws:codedeploy:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:deploymentgroup:wealist-board-app-codeDeploy/${var.name_prefix}-deploy-group",
          "arn:aws:codedeploy:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:deploymentgroup:wealist-user-app-codeDeploy/wealist-user-app-codeDeploy-tg",
          "arn:aws:codedeploy:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:deploymentgroup:wealist-board-app-codeDeploy/wealist-board-app-codeDeploy-tg",
          "arn:aws:codedeploy:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:deploymentconfig:*"
        ]
      },
      {
        Sid    = "CodeDeployDescribe"
        Effect = "Allow"
        Action = [
          "codedeploy:ListApplications",
          "codedeploy:ListDeploymentGroups",
          "codedeploy:GetApplication"
        ]
        Resource = "*"
      },

      # =========================================================================
      # [E] EC2 및 Auto Scaling 정보 조회 (배포 상태 확인용)
      # =========================================================================
      {
        Sid    = "EC2Describe"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeRouteTables",
          "ec2:DescribeVpcEndpoints"
        ]
        Resource = "*"
      },
      {
        Sid    = "AutoScalingDescribe"
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeLifecycleHooks"
        ]
        Resource = "*"
      },

      # =========================================================================
      # [F] CloudFront 캐시 무효화 (프론트엔드 배포 시)
      # =========================================================================
      {
        Sid      = "CloudFrontInvalidation"
        Effect   = "Allow"
        Action   = "cloudfront:CreateInvalidation"
        Resource = "*"
      }
    ]
  })
}