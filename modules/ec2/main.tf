# 현재 AWS 계정 ID 가져오기 (ECR 로그인 및 S3 경로용)
data "aws_caller_identity" "current" {}

# ============================================================================
# 1. Backend Server (Spring + Go) - Multi-AZ ASG
# ============================================================================

resource "aws_launch_template" "backend" {
  name_prefix   = "${var.name_prefix}-backend-template"
  image_id      = var.ami_id
  instance_type = "t3.small"

  iam_instance_profile {
    name = var.iam_instance_profile
  }

  # IMDSv2 필수 설정 (보안 강화)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # IMDSv2 필수
    http_put_response_hop_limit = 1
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = var.security_group_ids
  }

  # ⭐️ [Backend] 스크립트 파일 참조 (docker compose v2 지원)
  user_data = base64encode(templatefile("${path.module}/../../scripts/backend_user_data.sh", {
    region         = "ap-northeast-2"
    account_id     = data.aws_caller_identity.current.account_id
    s3_bucket_name = var.s3_bucket_name
    db_endpoint    = var.db_endpoint
    redis_endpoint = var.redis_endpoint
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.name_prefix}-backend-server"
    }
  }
}

resource "aws_autoscaling_group" "backend" {
  name                = "${var.name_prefix}-backend-asg"
  vpc_zone_identifier = var.private_subnet_ids # Multi-AZ (리스트)

  desired_capacity    = 2
  min_size            = 2
  max_size            = 6

  launch_template {
    id      = aws_launch_template.backend.id
    version = "$Latest"
  }

  # ⭐️ 두 개의 타겟 그룹(8080, 8000)에 동시 연결
  target_group_arns = [
    var.user_tg_arn,
    var.board_tg_arn
  ]

  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-backend-asg"
    propagate_at_launch = true
  }
}

# ============================================================================
# 2. Monitoring Server (Prometheus + Grafana) - Single ASG (Self-Healing)
# ============================================================================

resource "aws_launch_template" "monitoring" {
  name_prefix   = "${var.name_prefix}-monitoring-template"
  image_id      = var.ami_id
  instance_type = "t3.small"

  iam_instance_profile {
    name = var.iam_instance_profile
  }

  # IMDSv2 필수 설정 (보안 강화)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # IMDSv2 필수
    http_put_response_hop_limit = 1
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = var.security_group_ids
  }

  # ⭐️ [Monitoring] 스크립트 파일 참조로 변경 (기존 인라인 코드 대체)
  # backend와 동일하게 templatefile을 사용하여 깔끔하게 관리합니다.
  user_data = base64encode(templatefile("${path.module}/../../scripts/monitoring_user_data.sh", {
    s3_bucket_name = var.s3_bucket_name
    region         = "ap-northeast-2"
  }))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.name_prefix}-monitoring-server"
    }
  }
}

resource "aws_autoscaling_group" "monitoring" {
  name                = "${var.name_prefix}-monitoring-asg"
  vpc_zone_identifier = var.private_subnet_ids # 가용영역 분산 배치 (죽으면 다른 곳에서 부활)

  desired_capacity    = 1
  min_size            = 1
  max_size            = 1

  launch_template {
    id      = aws_launch_template.monitoring.id
    version = "$Latest"
  }

  target_group_arns = [var.monitoring_tg_arn]

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-monitoring-asg"
    propagate_at_launch = true
  }
}