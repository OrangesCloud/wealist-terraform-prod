# 1. Board Service 리포지토리
resource "aws_ecr_repository" "board_service" {
  name                 = "wealist-dev-board-service"
  image_tag_mutability = "MUTABLE" # 태그 변경 가능

  # 이미지 스캔 설정
  image_scanning_configuration {
    scan_on_push = false
  }

  tags = {
    Name = "wealist-dev-board-service-ecr"
  }
}

# 2. User Service 리포지토리
resource "aws_ecr_repository" "user_service" {
  name                 = "wealist-dev-user-service"
  image_tag_mutability = "MUTABLE" # 태그 변경 가능

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = {
    Name = "wealist-dev-user-service-ecr"
  }
}
