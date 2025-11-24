terraform {
  backend "s3" {
    bucket  = "wealist-tfstate-bucket"
    key     = "dev/network.tfstate"
    region  = "ap-northeast-2"
    encrypt = true
  }
}