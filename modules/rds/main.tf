# modules/rds/main.tf

# 1. 서브넷 그룹
resource "aws_db_subnet_group" "main" {
  name       = "${var.name_prefix}-db-sb-grp"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.name_prefix}-db-sb-grp"
  }
}

# 2. 보안 그룹 (Postgres 5432 포트 허용)
resource "aws_security_group" "rds" {
  name        = "${var.name_prefix}-rds-sg"
  description = "Allow PostgreSQL access from EC2"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.ec2_sg_id]
  }

  tags = {
    Name = "${var.name_prefix}-rds-sg"
  }
}

# 3. RDS 인스턴스 (PostgreSQL)
resource "aws_db_instance" "main" {
  identifier        = "${var.name_prefix}-db"

  # ⭐️ Postgres 설정
  engine            = "postgres"
  engine_version    = "17.6"       # (또는 원하시는 버전 예: 15.5)
  instance_class    = var.instance_class
  allocated_storage = 20
  storage_type      = "gp3"
  port              = 5432

  db_name  = var.initial_db_name
  username = var.db_username
  password = var.db_password

  # ⭐️ Multi-AZ 제어
  multi_az               = var.multi_az
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = true

  tags = {
    Name = "${var.name_prefix}-db"
  }
}