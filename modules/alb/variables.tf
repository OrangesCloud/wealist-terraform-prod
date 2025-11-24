variable "name_prefix" { type = string }
variable "vpc_id"      { type = string }
variable "subnet_ids"  { type = list(string) }
variable "security_group_ids" { type = list(string) }
variable "alb_cert_arn" { type = string } # 서울 리전 인증서
variable "target_id"    { type = string } # EC2 인스턴스 ID