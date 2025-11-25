output "replication_group_primary_endpoint_address" {
  description = "Redis Primary 노드 접속 주소"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}