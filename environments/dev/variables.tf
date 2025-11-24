variable "vpc_cidr" {
  description = "dev 환경 VPC CIDR"
  type        = string
}

variable "name_prefix" {
  description = "dev 환경 리소스 접두"
  type        = string
}

variable "az_1" { type = string }
variable "az_2" { type = string }
variable "az_3" { type = string }

variable "public_subnet_1_cidr" { type = string }
variable "public_subnet_2_cidr" { type = string }
variable "public_subnet_3_cidr" { type = string }

variable "private_subnet_1_cidr" { type = string }
variable "private_subnet_2_cidr" { type = string }
variable "private_subnet_3_cidr" { type = string }

