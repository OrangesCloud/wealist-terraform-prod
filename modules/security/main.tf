# 1. ALB용 보안 그룹
resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-alb-sg"
  description = "Allow all inbound traffic from internet (80/443)"
  vpc_id      = var.vpc_id

  # (Inbound) HTTP 80
  ingress {
    description = "internet https access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # (Inbound) HTTPS 443
  ingress {
    description = "http - https redirection"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # (Outbound) ALL
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-alb-sg"
  }
}

# 2. EC2용 보안 그룹
resource "aws_security_group" "ec2" {
  name        = "${var.name_prefix}-ec2-sg"
  description = "Allow traffic from ALB only"
  vpc_id      = var.vpc_id

  # (Inbound) HTTPS 443 from 10.0.2.0/24
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.2.0/24"]
  }

  # (Inbound) TCP 3001 from ALB SG
  ingress {
    from_port       = 3001
    to_port         = 3001
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id] # ALB SG 참조
  }

  # (Inbound) TCP 443 from Self (EC2 SG 자체)
  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "tcp"
    self      = true # 자기 자신 참조
  }

  # (Inbound) TCP 8000 from ALB SG
  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # (Inbound) TCP 8080 from ALB SG
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # (Inbound) TCP 8000 from Self (모니터링 서버가 백엔드 메트릭 수집용)
  ingress {
    from_port = 8000
    to_port   = 8000
    protocol  = "tcp"
    self      = true
  }

  # (Inbound) TCP 8080 from Self (모니터링 서버가 백엔드 메트릭 수집용)
  ingress {
    from_port = 8080
    to_port   = 8080
    protocol  = "tcp"
    self      = true
  }

  # (Inbound) TCP 9090 from ALB SG (Prometheus UI 접근)
  ingress {
    from_port       = 9090
    to_port         = 9090
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # (Inbound) TCP 9090 from Self (Prometheus 메트릭 수집)
  ingress {
    from_port = 9090
    to_port   = 9090
    protocol  = "tcp"
    self      = true
  }

  # (Inbound) ICMP from Self (Ping 허용 - 네트워크 테스트용)
  ingress {
    from_port = -1
    to_port   = -1
    protocol  = "icmp"
    self      = true
  }

  # (Outbound) ALL
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.name_prefix}-ec2-sg"
  }
}