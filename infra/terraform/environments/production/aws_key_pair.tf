resource "aws_key_pair" "bastion" {
  key_name   = "bastion-${terraform.env}"
  public_key = "${var.public_key}"
}
