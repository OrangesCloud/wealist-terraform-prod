variable "name_prefix" { type = string }
variable "vpc_id"      { type = string }
variable "subnet_ids"  { type = list(string) }
variable "ec2_sg_id"   { type = string }
variable "node_type"   { type = string }
variable "multi_az"    { type = bool }