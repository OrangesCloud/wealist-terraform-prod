# 1. Board Service 리포지토리
resource "aws_ecr_repository" "board_service" {
  name                 = "${var.name_prefix}-board-service"
  image_tag_mutability = var.image_tag_mutability

  # 이미지 스캔 설정
  image_scanning_configuration {
    scan_on_push = var.enable_image_scanning
  }

  tags = {
    Name        = "${var.name_prefix}-board-service-ecr"
    Project     = "wealist"
    ManagedBy   = "terraform"
    Environment = var.name_prefix
  }
}

# 2. User Service 리포지토리
resource "aws_ecr_repository" "user_service" {
  name                 = "${var.name_prefix}-user-service"
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.enable_image_scanning
  }

  tags = {
    Name        = "${var.name_prefix}-user-service-ecr"
    Project     = "wealist"
    ManagedBy   = "terraform"
    Environment = var.name_prefix
  }
}
