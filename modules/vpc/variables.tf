# 이 모듈이 작동하기 위해 필요한 "입력값" 목록입니다.
variable "cidr_block" {
  description = "VPC에 사용될 CIDR 블록"
  type        = string
}

variable "name_prefix" {
  description = "VPC와 관련한 리소스에 사용할 Name 태그 - wealist-dev"
  type        = string
}

variable "az_1" {
  description = "첫 번째 가용 영역 (예: ap-northeast-2a)"
  type        = string
}
variable "az_2" {
  description = "두 번째 가용 영역 (예: ap-northeast-2c)"
  type        = string
}
variable "az_3" {
  description = "세 번째 가용 영역 (예: ap-northeast-2d)"
  type        = string
}

variable "public_subnet_1_cidr" { type = string }
variable "public_subnet_2_cidr" { type = string }
variable "public_subnet_3_cidr" { type = string }

variable "private_subnet_1_cidr" { type = string }
variable "private_subnet_2_cidr" { type = string }
variable "private_subnet_3_cidr" { type = string }