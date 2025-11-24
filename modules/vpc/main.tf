# "VPC 레고 블록"을 정의합니다.
resource "aws_vpc" "main" {
  cidr_block = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

# "인터넷 게이트웨이 레고 블록"을 정의합니다.
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-igw"
  }
}

# --- Subnets 1 (AZ: var.az_1) ---
resource "aws_subnet" "public_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_1_cidr
  availability_zone = var.az_1 # 1번 AZ 사용
  map_public_ip_on_launch = true # ⚠️ 실제 설정 확인!
  tags = {
    Name = "${var.name_prefix}-public-subnet-1" # ⚠️ 실제 태그 이름!
  }
}
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_1_cidr
  availability_zone = var.az_1 # 1번 AZ 사용
  map_public_ip_on_launch = false # ⚠️ 실제 설정 확인!
  tags = {
    Name = "${var.name_prefix}-private-subnet-1" # ⚠️ 실제 태그 이름!
  }
}

# --- Subnets 2 (AZ: var.az_2) ---
resource "aws_subnet" "public_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_2_cidr
  availability_zone = var.az_2 # 2번 AZ 사용
  map_public_ip_on_launch = true # ⚠️ 실제 설정 확인!
  tags = {
    Name = "${var.name_prefix}-public-subnet-2" # ⚠️ 실제 태그 이름!
  }
}
resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_2_cidr
  availability_zone = var.az_2 # 2번 AZ 사용
  map_public_ip_on_launch = false # ⚠️ 실제 설정 확인!
  tags = {
    Name = "${var.name_prefix}-private-subnet-2" # ⚠️ 실제 태그 이름!
  }
}

# --- Subnets 3 (AZ: var.az_3) ---
resource "aws_subnet" "public_3" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_3_cidr
  availability_zone = var.az_3 # 3번 AZ 사용
  map_public_ip_on_launch = false # ⚠️ 실제 설정 확인!
  tags = {
    Name = "${var.name_prefix}-public-subnet-3" # ⚠️ 실제 태그 이름!
  }
}
resource "aws_subnet" "private_3" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_3_cidr
  availability_zone = var.az_3 # 3번 AZ 사용
  map_public_ip_on_launch = false # ⚠️ 실제 설정 확인!
  tags = {
    Name = "${var.name_prefix}-private-subnet-3" # ⚠️ 실제 태그 이름!
  }
}

resource "aws_eip" "nat_1" {
  domain = "vpc" # 'domain = "vpc"'와 동일
  tags = {
    # ⚠️ (중요!) AWS 콘솔에서 실제 EIP의 'Name' 태그를 확인하세요.
    # (예: wealist-dev-nat-eip-1)
    Name = "${var.name_prefix}-nat-eip-1"
  }
}

resource "aws_nat_gateway" "nat_1" {
  # (가정: 1번 Public Subnet에 NGW가 위치함)
  allocation_id = aws_eip.nat_1.id
  subnet_id     = aws_subnet.public_1.id # 2단계에서 import한 public-1 서브넷

  tags = {
    # ⚠️ (중요!) AWS 콘솔에서 실제 NGW의 'Name' 태그를 확인하세요.
    # (예: wealist-dev-nat-gw-1)
    Name = "${var.name_prefix}-nat-gw-1"
  }
}

# --- B. Public Route Table (1개) 및 관련 리소스 ---

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    # ⚠️ (중요!) 님이 알려주신 실제 이름과 일치시킵니다.
    Name = "${var.name_prefix}-public-rt"
  }
}

resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id # 1단계에서 import한 IGW
}

# 3개의 Public Subnet을 Public RT에 연결
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public_3" {
  subnet_id      = aws_subnet.public_3.id
  route_table_id = aws_route_table.public.id
}


# --- C. Private Route Table (1개) 및 관련 리소스 ---

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = {
    # ⚠️ (중요!) 님이 알려주신 실제 이름과 일치시킵니다.
    Name = "${var.name_prefix}-private-rt"
  }
}

resource "aws_route" "private_nat_access" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_1.id # 위에서 정의한 NGW 참조
}

# 3개의 Private Subnet을 Private RT에 연결
resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "private_3" {
  subnet_id      = aws_subnet.private_3.id
  route_table_id = aws_route_table.private.id
}