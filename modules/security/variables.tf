variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type        = string
  description = "보안 그룹이 생성될 VPC ID"
}