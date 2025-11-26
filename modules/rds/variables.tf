# RDS Subnet Group & Security Group을 위한 필수 변수
variable "name_prefix" {
  description = "Environment prefix (e.g., wealist-prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where RDS resources will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs for DB subnet group (minimum 2 AZs)"
  type        = list(string)
}

variable "ec2_sg_id" {
  description = "EC2 security group ID to allow PostgreSQL access from"
  type        = string
}

# RDS 인스턴스는 수동 관리하므로 아래 변수들은 주석 처리
# variable "instance_class" { type = string }
# variable "db_username"    { type = string }
# variable "db_password"    { type = string }
# variable "multi_az"       { type = bool }
# variable "initial_db_name"{ type = string }