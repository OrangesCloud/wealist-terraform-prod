# ⭐️ (가장 중요) 실제 값을 입력하는 파일
# AWS 콘솔에서 현재 운영 중인 VPC의 "실제 값"을 확인하고 입력하세요.
# 이 값과 AWS 설정이 다르면 'plan' 시에 변경 사항이 뜹니다.
# enviroments/dev/terraform.tfvars
vpc_cidr    = "10.0.0.0/16" # (예시) 실제 CIDR로 변경
name_prefix = "wealist-dev" # (예시) 실제 Name 태그로 변경

# 가용 영역 (a, c, d)
az_1 = "ap-northeast-2a"
az_2 = "ap-northeast-2c"
az_3 = "ap-northeast-2d"

# Public Subnet CIDR (1, 2, 3)
public_subnet_1_cidr = "10.0.0.0/24"
public_subnet_2_cidr = "10.0.1.0/24"
public_subnet_3_cidr = "10.0.14.0/24"

# Private Subnet CIDR (1, 2, 3)
private_subnet_1_cidr = "10.0.2.0/24"
private_subnet_2_cidr = "10.0.3.0/24"
private_subnet_3_cidr = "10.0.4.0/24"
