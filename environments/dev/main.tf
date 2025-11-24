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

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
# ---------------
# 데이터 블록
# ---------------
data "aws_acm_certificate" "frontend" {
  domain   = "wealist.co.kr"
  statuses = ["ISSUED"]
  provider = aws.us_east_1
}

data "aws_acm_certificate" "alb" {
  domain   = "wealist.co.kr"
  statuses = ["ISSUED"]
}

data "aws_ssm_parameter" "backend_ami" {
  name = "/wealist/dev/ami_id"
}

data "aws_ami" "backend" {
  filter {
    name = "image-id"
    # 위의 aws_ssm_parameter 에서 가져오는중
    values = [data.aws_ssm_parameter.backend_ami.value]
  }
}


# ---------------
# VPC 모듈
# ---------------
module "vpc" {
  source = "../../modules/vpc"

  # 2. 실제 변수 전달 (terraform.tfvars 에서 주입)
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

module "security" {
  source = "../../modules/security"

  name_prefix = var.name_prefix

  # modules/vpc/outputs.tf 덕분에 vpc_id를 이렇게 꺼내 쓸 수 있습니다.
  vpc_id = module.vpc.vpc_id
}

# ---------------
# IAM 모듈
# ---------------
module "iam" {
  source = "../../modules/iam"

  name_prefix  = var.name_prefix
  role_name    = "wealist-dev-ec2-role" # 님의 실제 Role 이름
  profile_name = "wealist-dev-ec2-profile"
}

# ---------------
# EC2 모듈
# ---------------
module "ec2" {
  source = "../../modules/ec2"

  name_prefix = var.name_prefix
  ami_id      = data.aws_ami.backend.id

  # VPC 모듈에서 가져온 subnet_1 (wealist-dev-private-subnet-1)
  subnet_id = module.vpc.private_subnet_1_id

  # Security 모듈에서 가져온 EC2 SG ID
  security_group_ids = [module.security.ec2_sg_id]

  # IAM 모듈에서 가져온 프로파일
  iam_instance_profile = module.iam.instance_profile_name
}

# ---------------
# ECR 모듈
# ---------------
module "ecr" {
  source = "../../modules/ecr"
}

# ---------------
# Frontend(CDN, S3) 모듈
# ---------------


module "frontend" {
  source = "../../modules/frontend"

  bucket_name         = "wealist-frontend"
  cf_name_tag         = "wealist-dev-front-cdn"
  acm_certificate_arn = data.aws_acm_certificate.frontend.arn

  # -------------------------------------------------------------------------
  # [FUTURE: PROD 배포 시 도메인 스위칭 가이드]
  # 현재 상태: Dev 환경이 메인 도메인(wealist.co.kr)을 임시로 점유 중.
  # 변경 시점: Prod 환경이 배포되어 메인 도메인을 가져가야 할 때.
  # 변경 방법:
  #   1. Prod 환경 배포 시 그쪽에서 aliases = ["wealist.co.kr"] 설정.
  #   2. Dev 환경(여기)은 아래 aliases를 빈 리스트 [] 로 변경하거나
  #      ["dev.wealist.co.kr"] 같은 서브 도메인으로 변경.
  # -------------------------------------------------------------------------
  aliases = ["wealist.co.kr"]
  # 도메인 변경 시 아래 domain_name 변수도 같이 수정 필요 (OAC 이름용)
  domain_name = "wealist.co.kr"
}

# ---------------
# Route 53 모듈
# ---------------
module "route53" {
  source = "../../modules/route53"

  # -------------------------------------------------------------------------
  # [FUTURE: PROD 배포 시 DNS 스위칭 가이드]
  # 현재 상태: Dev CloudFront를 가리키는 A 레코드를 생성 중.
  # 변경 시점: Prod 환경이 메인 도메인 A 레코드를 관리하게 될 때.
  # 변경 방법:
  #   1. 충돌 방지를 위해 아래 create_record 값을 false로 변경.
  #   2. 또는 domain_name을 "dev.wealist.co.kr"로 변경하여 별도 레코드 생성.
  # -------------------------------------------------------------------------
  create_record = true
  domain_name   = "wealist.co.kr"

  # Frontend 모듈에서 값 받아오기
  cf_domain_name    = module.frontend.cf_domain_name
  cf_hosted_zone_id = module.frontend.cf_hosted_zone_id
}

# ---------------
# ALB 모듈
# ---------------
module "alb" {
  source = "../../modules/alb"

  name_prefix        = var.name_prefix
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnet_ids
  security_group_ids = [module.security.alb_sg_id]
  alb_cert_arn       = data.aws_acm_certificate.alb.arn
  target_id          = module.ec2.instance_id
}