variable "region" {
  default = "ap-northeast-1" # TOKYO
}

variable "application_name" {
  description = "Your application name"
  default     = "sample"                # only lowercase alphanumeric characters and hyphens
}

variable "az_count" {
  description = "Number of AZs to cover in a given AWS region"
  default     = "2"
}

variable "instance_types" {
  type = "map"

  default = {
    "rds"                      = "db.t2.small"
    "aws_launch_configuration" = "t2.micro"
    "ec2_bastion"              = "t2.micro"
  }
}

variable "root_domain" {
  description = "Your application domain"
  default     = "terraform-example.net"
}

variable "admin_cidr_ingress" {
  description = "Your private ip address"
  default     = "60.65.70.21/32"
}

variable "rds_instance_count" {
  default = 1
}

variable "image_urls" {
  type = "map"

  default = {
    "rack_application" = "016559158979.dkr.ecr.ap-northeast-1.amazonaws.com/sample:latest"
  }
}

variable "public_key" {
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDCfMhYLjdeV1e8nGB6cuezYOcHULByKd0D2a2UQHRYrJfS1wddPEd7+DTnZpaiNZ56klyLx3oh/QEtmBzufJWm8yKD/gZYaAhpFiPvdcHK5ogX7Ti8SlEFyl6fLnVWK5wBTpL3idKTaMvqFp+12eV9pELNULOyOwPVJSTs/2LLG3CYdd2A4FhS8yw5Qio/k57a6Z1kKCAKQXw/GAyt7NdPQBv3qVuq1YzJzdPg58VM9JjFKrRHd82tU+O7K5evoCAg2t0fUWJD3E5f84i8uGCIEmFAr/vwyKEcPgl/wgXbp++jSiL9XU7Hesv4fNc85VLf/R5WUu0W62UwFv3WXLMt alprhcp666@gmail.com"
}
