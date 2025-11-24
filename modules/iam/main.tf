# 1. IAM 역할 (Role)
resource "aws_iam_role" "ec2_role" {
  name = var.role_name

  description = "IAM role for wealist dev EC2 instance (SSM, ECR, S3, Parameter Store)"

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
    Name = var.role_name
    Environment = "dev"
    ManagedBy   = "terraform"
    Project     = "wealist"
  }
}

# 2. 인스턴스 프로파일
resource "aws_iam_instance_profile" "ec2_profile" {
  name = var.profile_name
  role = aws_iam_role.ec2_role.name

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
    Project     = "wealist"
  }
}

# --- [A] AWS 관리형 정책 연결 (2개) ---

# 1. AmazonEC2ContainerRegistryReadOnly
resource "aws_iam_role_policy_attachment" "ecr_read" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# 2. AmazonSSMManagedInstanceCore
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


# --- [B] 고객 인라인 정책 (4개) ---

# 3. custom-ssm-ec2-role
resource "aws_iam_role_policy" "custom_ssm" {
  name = "custom-ssm-ec2-role"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "SSMAgentPermissions"
        Effect   = "Allow"
        Resource = "*"
        Action = [
          "ssm:UpdateInstanceInformation",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
      },
      {
        Sid      = "EC2MessagesPermissions"
        Effect   = "Allow"
        Resource = "*"
        Action = [
          "ec2messages:AcknowledgeMessage",
          "ec2messages:DeleteMessage",
          "ec2messages:FailMessage",
          "ec2messages:GetEndpoint",
          "ec2messages:GetMessages",
          "ec2messages:SendReply"
        ]
      }
    ]
  })
}

# 4. wealist-dev-ecr-access
resource "aws_iam_role_policy" "ecr_access" {
  name = "wealist-dev-ecr-access"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ECRAccess"
        Effect   = "Allow"
        Resource = "*"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
      }
    ]
  })
}

# 5. wealist-dev-parameter-store-read
resource "aws_iam_role_policy" "parameter_read" {
  name = "wealist-dev-parameter-store-read"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadParameterStore"
        Effect   = "Allow"
        Resource = "arn:aws:ssm:ap-northeast-2:290008131187:parameter/wealist/dev/*"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
      },
      {
        Sid      = "DecryptSecureStrings"
        Effect   = "Allow"
        Resource = "*"
        Action   = "kms:Decrypt"
      }
    ]
  })
}

# 6. wealist-dev-s3-deploy-scripts
resource "aws_iam_role_policy" "s3_deploy" {
  name = "wealist-dev-s3-deploy-scripts"
  role = aws_iam_role.ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3DeployScripts"
        Effect = "Allow"
        Resource = [
          "arn:aws:s3:::wealist-deploy-scripts",
          "arn:aws:s3:::wealist-deploy-scripts/*"
        ]
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
      }
    ]
  })
}