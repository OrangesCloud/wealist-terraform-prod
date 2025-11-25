name_prefix = "wealist-prod"
vpc_cidr    = "10.1.0.0/16" # Dev(10.0.x.x)와 겹치지 않게

az_1 = "ap-northeast-2a"
az_2 = "ap-northeast-2c"
az_3 = "ap-northeast-2d"

# 서브넷 (Dev와 다른 대역)
public_subnet_1_cidr = "10.1.0.0/24"
public_subnet_2_cidr = "10.1.1.0/24"
public_subnet_3_cidr = "10.1.2.0/24"

private_subnet_1_cidr = "10.1.10.0/24"
private_subnet_2_cidr = "10.1.11.0/24"
private_subnet_3_cidr = "10.1.12.0/24"

# ⭐️ Multi-AZ 설정 (일단 false로 시작, 필요시 true 변경)
enable_multi_az = false