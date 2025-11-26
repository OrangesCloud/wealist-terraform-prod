variable "name_prefix" {
  description = "Environment prefix (e.g., wealist-prod, wealist-dev)"
  type        = string
}

variable "enable_image_scanning" {
  description = "Enable image scanning on push"
  type        = bool
  default     = false
}

variable "image_tag_mutability" {
  description = "Image tag mutability setting (MUTABLE or IMMUTABLE)"
  type        = string
  default     = "MUTABLE"
}
