variable "domain_name"       { type = string }
variable "cf_domain_name"    { type = string }
variable "cf_hosted_zone_id" { type = string }

# DNS 레코드 생성 여부 스위치. true=생성, false=생성안함.
# 추후 Prod 환경이 도메인을 가져갈 때 Dev에서는 false로 설정하여 충돌 방지.
variable "create_record" {
  type    = bool
  default = true
}