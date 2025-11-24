output "board_repo_url" {
  value = aws_ecr_repository.board_service.repository_url
}

output "user_repo_url" {
  value = aws_ecr_repository.user_service.repository_url
}