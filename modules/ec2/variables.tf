variable "name_prefix"          { type = string }
variable "ami_id"               { type = string } # ⚠️ 변수로 받음
variable "subnet_id"            { type = string }
variable "security_group_ids"   { type = list(string) }
variable "iam_instance_profile" { type = string }
