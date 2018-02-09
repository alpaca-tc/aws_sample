resource "aws_instance" "bastion" {
  count         = "${length(data.aws_availability_zones.available.names)}"
  instance_type = "${var.instance_types["ec2_bastion"]}"

  # TODO: eipでIPを固定する
  subnet_id                   = "${element(aws_subnet.public.*.id, count.index)}"
  vpc_security_group_ids      = ["${aws_security_group.bastion.id}"]
  associate_public_ip_address = true
  key_name                    = "${aws_key_pair.bastion.key_name}"

  # Amazon Linux AMI 2017.09.1 (HVM), SSD Volume Type
  ami = "ami-ceafcba8"

  tags = {
    Name    = "${var.application_name}-bastion-${terraform.env}-${count.index}"
    Env     = "${terraform.env}"
    AppName = "${var.application_name}"
    Role    = "bastion"
  }
}
