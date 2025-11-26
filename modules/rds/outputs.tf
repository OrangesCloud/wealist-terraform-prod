output "db_subnet_group_name" {
  description = "DB Subnet Group 이름 (RDS 수동 생성 시 사용)"
  value       = aws_db_subnet_group.main.name
}

output "db_security_group_id" {
  description = "RDS Security Group ID (RDS 수동 생성 시 사용)"
  value       = aws_security_group.rds.id
}

# RDS 인스턴스는 수동으로 관리하므로 엔드포인트는 SSM Parameter Store에서 조회
# output "db_instance_endpoint" {
#   description = "RDS 접속 엔드포인트 (host:port)"
#   value       = aws_db_instance.main.endpoint
# }