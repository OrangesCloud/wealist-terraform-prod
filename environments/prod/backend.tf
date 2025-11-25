terraform {
  backend "s3" {
    bucket  = "wealist-tfstate-bucket"
    key     = "prod/network.tfstate" # 🚨 dev -> prod 로 반드시 변경!
    region  = "ap-northeast-2"
    encrypt = true
  }
}