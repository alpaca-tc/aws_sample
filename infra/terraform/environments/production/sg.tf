resource "aws_security_group" "alb" {
  name        = "alb"
  description = "Controls access to the application ELB"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 3000
    to_port     = 3000
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  tags = {
    Name    = "${var.application_name}-alb-${terraform.env}"
    Env     = "${terraform.env}"
    AppName = "${var.application_name}"
  }
}

resource "aws_security_group" "ecs-instance" {
  description = "Controls direct access to ecs instances"
  vpc_id      = "${aws_vpc.main.id}"
  name        = "ecs-instance"

  ingress {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22

    security_groups = [
      "${aws_security_group.bastion.id}",
    ]
  }

  ingress {
    description = "HTTP"
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol  = "tcp"
    from_port = 3000
    to_port   = 3000

    security_groups = [
      "${aws_security_group.alb.id}",
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.application_name}-ecs-instance-${terraform.env}"
    Env     = "${terraform.env}"
    Role    = "ecs"
    AppName = "${var.application_name}"
  }
}

##
# bastion
##
resource "aws_security_group" "bastion" {
  name        = "${var.application_name}-bastion-${terraform.env}"
  description = "Bastion"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22

    cidr_blocks = [
      "${var.admin_cidr_ingress}",
    ]
  }

  egress {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22

    cidr_blocks = ["${aws_vpc.main.cidr_block}"]
  }

  tags = {
    Name    = "${var.application_name}-bastion-${terraform.env}"
    Role    = "bastion"
    Env     = "${terraform.env}"
    AppName = "${var.application_name}"
  }
}

##
# NAT Gateway
##
resource "aws_security_group" "nat-gateway" {
  name        = "${var.application_name}-nat-gateway-${terraform.env}"
  description = "NAT Gateway"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    description = "HTTP"
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80

    security_groups = [
      "${aws_security_group.ecs-instance.id}",
    ]
  }

  ingress {
    description = "HTTP"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443

    security_groups = [
      "${aws_security_group.ecs-instance.id}",
    ]
  }

  egress {
    description = "HTTP"
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "NTP"
    protocol    = "udp"
    from_port   = 123
    to_port     = 123
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTPS"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "SMTP"
    protocol    = "tcp"
    from_port   = 587
    to_port     = 587
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.application_name}-nat-gateway-${terraform.env}"
    Role    = "ecs"
    Env     = "${terraform.env}"
    AppName = "${var.application_name}"
  }
}
