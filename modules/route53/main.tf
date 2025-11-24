# 1. 호스팅 영역
resource "aws_route53_zone" "main" {
  name = "wealist.co.kr" # (고정값 또는 변수로 관리 가능)

  comment = "wealist"
}

# 2. A 레코드 (CloudFront Alias)
resource "aws_route53_record" "frontend" {
  # create_record가 true일 때만 생성
  count = var.create_record ? 1 : 0

  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = var.cf_domain_name
    zone_id                = var.cf_hosted_zone_id
    evaluate_target_health = false
  }
}