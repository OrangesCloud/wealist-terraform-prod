# modules/elasticache/main.tf

resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.name_prefix}-redis-sb-grp"
  subnet_ids = var.subnet_ids
}

resource "aws_security_group" "redis" {
  name        = "${var.name_prefix}-redis-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [var.ec2_sg_id]
  }
}

resource "aws_elasticache_replication_group" "main" {
  replication_group_id = "${var.name_prefix}-redis"
  description          = "Wealist Redis"
  node_type            = var.node_type
  port                 = 6379

  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [aws_security_group.redis.id]
  parameter_group_name = "default.redis7"
  engine_version       = "7.0"

  # ⭐️ Multi-AZ 제어 (true면 노드 2개 자동 생성)
  automatic_failover_enabled = var.multi_az
  num_cache_clusters         = var.multi_az ? 2 : 1
}