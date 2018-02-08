terraform {
  backend "s3" {
    profile = "sample-production"
    bucket  = "application-backend"
    key     = "terraform/terraform.tfstate"
    region  = "ap-northeast-1"
    encrypt = true
  }
}
