provider "aws" {
  version = "1.9.0"
  region  = "${var.region}"
  profile = "sample-production"
}

provider "template" {
  version = "0.1.0"
}

data "aws_availability_zones" "available" {}
