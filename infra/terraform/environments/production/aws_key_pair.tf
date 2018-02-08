resource "aws_key_pair" "application" {
  key_name   = "application-${terraform.env}"
  public_key = "${var.public_key}"
}
