variable "bucket_name" {
  type        = string
  description = "S3 버킷 이름"
}

variable "domain_name" {
  type = string
}

variable "cf_name_tag" {
  type        = string
  description = "CloudFront 이름 태그"
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM 인증서 ARN (us-east-1)"
}

# "CloudFront에 연결할 도메인 리스트 (CNAME).
# Prod 배포 후 Dev에서는 빈 리스트([])로 변경하여 도메인 연결을 해제할 수 있음."

variable "aliases" {
  type        = list(string)
  description = "연결할 도메인 리스트 (없으면 빈 리스트 [])"
  default     = []
}