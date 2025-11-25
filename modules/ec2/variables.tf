variable "name_prefix"          { type = string }
variable "ami_id"               { type = string }
variable "private_subnet_ids"   { type = list(string) } # ⭐️ 리스트로 변경
variable "security_group_ids"   { type = list(string) }
variable "iam_instance_profile" { type = string }

# ⭐️ 추가된 변수들
variable "user_tg_arn"          { type = string }
variable "board_tg_arn"         { type = string }
variable "monitoring_tg_arn"    { type = string }
variable "db_endpoint"          { type = string }
variable "redis_endpoint"       { type = string }
variable "s3_bucket_name"       { type = string }