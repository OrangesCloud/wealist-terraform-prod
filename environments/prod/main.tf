terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2"
}

# ---------------
# ⭐️ Data Blocks (정보 조회)
# ---------------

# 1. 인증서 (ACM)
data "aws_acm_certificate" "alb" {
  domain   = "wealist.co.kr"
  statuses = ["ISSUED"]
}

# 2. RDS 엔드포인트 (SSM Parameter Store에서 조회)
# RDS를 수동으로 생성한 후 SSM에 저장된 엔드포인트를 조회합니다.
data "aws_ssm_parameter" "db_endpoint" {
  name = "/wealist/prod/db/endpoint"

  # RDS를 아직 생성하지 않았을 경우를 대비한 처리는 variables.tf에서 default 값으로 처리
}

# 3. AMI (최신 Amazon Linux 2)
data "aws_ami" "backend" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# ---------------
# Modules (인프라 조립)
# ---------------

# 1. VPC
module "vpc" {
  source = "../../modules/vpc"

  cidr_block  = var.vpc_cidr
  name_prefix = var.name_prefix
  az_1        = var.az_1
  az_2        = var.az_2
  az_3        = var.az_3

  public_subnet_1_cidr = var.public_subnet_1_cidr
  public_subnet_2_cidr = var.public_subnet_2_cidr
  public_subnet_3_cidr = var.public_subnet_3_cidr

  private_subnet_1_cidr = var.private_subnet_1_cidr
  private_subnet_2_cidr = var.private_subnet_2_cidr
  private_subnet_3_cidr = var.private_subnet_3_cidr
}

# 2. Security
module "security" {
  source      = "../../modules/security"
  name_prefix = var.name_prefix
  vpc_id      = module.vpc.vpc_id
}

# 3. IAM
module "iam" {
  source       = "../../modules/iam"
  name_prefix  = var.name_prefix
  environment  = "prod" # SSM Parameter 경로용 (wealist/prod/*)
  role_name    = "${var.name_prefix}-ec2-role"
  profile_name = "${var.name_prefix}-ec2-profile"
}

# 4. EC2
module "ec2" {

  source = "../../modules/ec2"

  name_prefix = var.name_prefix
  ami_id      = data.aws_ami.backend.id

  # ⭐️ [변경] 리스트 형태로 전달 (Multi-AZ)
  private_subnet_ids = [
    module.vpc.private_subnet_1_id,
    module.vpc.private_subnet_2_id,
    module.vpc.private_subnet_3_id
  ]

  security_group_ids   = [module.security.ec2_sg_id]
  iam_instance_profile = module.iam.instance_profile_name

  # ⭐️ [추가] 연결할 정보들
  user_tg_arn       = module.alb.user_tg_arn
  board_tg_arn      = module.alb.board_tg_arn
  monitoring_tg_arn = module.alb.monitoring_tg_arn

  # RDS는 수동 관리: SSM Parameter Store에서 엔드포인트 조회
  # RDS 생성 전에는 빈 문자열이 전달되며, 생성 후 SSM에 저장하면 자동으로 조회됨
  db_endpoint    = try(data.aws_ssm_parameter.db_endpoint.value, "")
  redis_endpoint = module.elasticache.replication_group_primary_endpoint_address
  s3_bucket_name = "wealist-deploy-scripts" # 실제 버킷 이름
}

# 5. ECR
module "ecr" {
  source      = "../../modules/ecr"
  name_prefix = var.name_prefix
}

# 6. ALB
module "alb" {
  source = "../../modules/alb"

  name_prefix        = var.name_prefix
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.security.alb_sg_id]
  alb_cert_arn       = data.aws_acm_certificate.alb.arn
}

# 7. RDS (PostgreSQL) - Terraform 관리에서 제외됨
# RDS는 AWS 콘솔에서 직접 관리합니다.
# DB Subnet Group과 Security Group도 수동으로 관리합니다.
#
# module "rds" {
#   source = "../../modules/rds"
#
#   name_prefix = var.name_prefix
#   vpc_id      = module.vpc.vpc_id
#   subnet_ids  = [module.vpc.private_subnet_1_id, module.vpc.private_subnet_2_id]
#   ec2_sg_id   = module.security.ec2_sg_id
# }

# 8. ElastiCache (Redis)
module "elasticache" {
  source = "../../modules/elasticache"

  name_prefix = var.name_prefix
  vpc_id      = module.vpc.vpc_id

  # ⭐️ 여기도 서브넷 2개가 필요합니다.
  subnet_ids = [module.vpc.private_subnet_1_id, module.vpc.private_subnet_2_id]
  ec2_sg_id  = module.security.ec2_sg_id

  node_type = "cache.t3.micro"
  multi_az  = var.enable_multi_az
}

# 9. CodeDeploy
module "codedeploy" {
  source = "../../modules/codedeploy"

  name_prefix                 = var.name_prefix
  codedeploy_service_role_arn = module.iam.codedeploy_service_role_arn
  backend_asg_name            = module.ec2.backend_asg_name
  user_target_group_name      = module.alb.user_tg_name
  board_target_group_name     = module.alb.board_tg_name
}