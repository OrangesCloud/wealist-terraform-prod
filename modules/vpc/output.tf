output "vpc_id" {
  description = "생성된 VPC ID"
  value       = aws_vpc.main.id
}
# EC2 모듈에서 사용
output "private_subnet_1_id" {
  value = aws_subnet.private_1.id
}
output "private_subnet_2_id" {
  value = aws_subnet.private_2.id
}

output "private_subnet_3_id" {
  value = aws_subnet.private_3.id
}
# ALB 모듈에서 사용 (리스트 형태)
output "public_subnet_ids" {
  value = [
    aws_subnet.public_1.id,
    aws_subnet.public_2.id,
    aws_subnet.public_3.id
  ]
}