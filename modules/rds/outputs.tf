output "db_instance_endpoint" {
  description = "RDS 접속 엔드포인트 (host:port)"
  value       = aws_db_instance.main.endpoint
}