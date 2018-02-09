resource "aws_instance" "bastion" {
  instance_type = "${var.instance_types["ec2_bastion"]}"

  subnet_id              = "${element(aws_subnet.public.*.id, 0)}"
  vpc_security_group_ids = ["${aws_security_group.bastion.id}"]
  key_name               = "${aws_key_pair.bastion.key_name}"

  # Amazon Linux AMI 2017.09.1 (HVM), SSD Volume Type
  ami = "ami-ceafcba8"

  tags = {
    Name    = "${var.application_name}-bastion-${terraform.env}"
    Env     = "${terraform.env}"
    AppName = "${var.application_name}"
    Role    = "bastion"
  }
}
