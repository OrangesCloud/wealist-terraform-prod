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

# 2. DB 슈퍼유저 (SSM Parameter Store)
# 🚨 'db_username' 대신 'db_superuser' 키를 사용합니다.
data "aws_ssm_parameter" "db_superuser" {
  name = "/wealist/prod/db/postgres_superuser"
}

# 3. DB 비밀번호
data "aws_ssm_parameter" "db_password" {
  name            = "/wealist/prod/db/postgres_superuser_password"
  with_decryption = true
}

# 4. 초기 DB 이름 (선택사항, 없으면 postgres 기본 DB 사용)
data "aws_ssm_parameter" "db_initial_name" {
  name = "/wealist/prod/db/postgres_db"
}

# 5. AMI (최신 Amazon Linux 2)
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
  role_name    = "${var.name_prefix}-ec2-role"
  profile_name = "${var.name_prefix}-ec2-profile"
}

# 4. EC2
module "ec2" {
  source = "../../modules/ec2"

  name_prefix          = var.name_prefix
  ami_id               = data.aws_ami.backend.id
  subnet_id            = module.vpc.private_subnet_1_id
  security_group_ids   = [module.security.ec2_sg_id]
  iam_instance_profile = module.iam.instance_profile_name
}

# 5. ECR
module "ecr" {
  source = "../../modules/ecr"
}

# 6. ALB
module "alb" {
  source = "../../modules/alb"

  name_prefix        = var.name_prefix
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.security.alb_sg_id]
  target_id          = module.ec2.instance_id
  alb_cert_arn       = data.aws_acm_certificate.alb.arn
}

# 7. RDS (PostgreSQL)
module "rds" {
  source = "../../modules/rds"

  name_prefix    = var.name_prefix
  vpc_id         = module.vpc.vpc_id

  # ⭐️ [수정됨] 이제 private_subnet_2_id를 찾을 수 있습니다.
  subnet_ids     = [module.vpc.private_subnet_1_id, module.vpc.private_subnet_2_id]
  ec2_sg_id      = module.security.ec2_sg_id

  instance_class = "db.t3.micro"

  # ⭐️ SSM에서 가져온 슈퍼유저 정보 주입
  db_username    = data.aws_ssm_parameter.db_superuser.value
  db_password    = data.aws_ssm_parameter.db_password.value
  initial_db_name= data.aws_ssm_parameter.db_initial_name.value

  multi_az       = var.enable_multi_az
}

# 8. ElastiCache (Redis)
module "elasticache" {
  source = "../../modules/elasticache"

  name_prefix = var.name_prefix
  vpc_id      = module.vpc.vpc_id

  # ⭐️ 여기도 서브넷 2개가 필요합니다.
  subnet_ids  = [module.vpc.private_subnet_1_id, module.vpc.private_subnet_2_id]
  ec2_sg_id   = module.security.ec2_sg_id

  node_type   = "cache.t3.micro"
  multi_az    = var.enable_multi_az
}