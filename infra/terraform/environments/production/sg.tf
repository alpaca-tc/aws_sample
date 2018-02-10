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

    security_groups = [
      "${aws_security_group.alb.id}",
    ]
  }

  ingress {
    description = "HTTP"
    protocol    = "tcp"
    from_port   = 3000
    to_port     = 3000

    security_groups = [
      "${aws_security_group.alb.id}",
    ]
  }

  tags = {
    Name    = "${var.application_name}-ecs-instance-${terraform.env}"
    Env     = "${terraform.env}"
    Role    = "ecs"
    AppName = "${var.application_name}"
  }
}

# FIXME: Fixes Circle error.
# https://github.com/hashicorp/terraform/issues/539
resource "aws_security_group_rule" "ecs-instance-to-rds" {
  description              = "RDS"
  type                     = "egress"
  security_group_id        = "${aws_security_group.ecs-instance.id}"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.rds.id}"
}

# FIXME: Fixes Circle error.
# https://github.com/hashicorp/terraform/issues/539
resource "aws_security_group_rule" "ecs-instance-to-elasticache" {
  description              = "ElastiCache"
  type                     = "egress"
  security_group_id        = "${aws_security_group.ecs-instance.id}"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.elasticache.id}"
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
resource "aws_security_group" "to-nat-gateway" {
  name        = "${var.application_name}-to-nat-gateway-${terraform.env}"
  description = "To NAT Gateway"
  vpc_id      = "${aws_vpc.main.id}"

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
    Name    = "${var.application_name}-to-nat-gateway-${terraform.env}"
    Role    = "ecs"
    Env     = "${terraform.env}"
    AppName = "${var.application_name}"
  }
}

##
# RDS
##
resource "aws_security_group" "rds" {
  name        = "${var.application_name}-rds-${terraform.env}"
  description = "RDS"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    description = "MySQL"
    protocol    = "tcp"
    from_port   = 3306
    to_port     = 3306

    # NOTE: ECSからのみアクセスできる
    security_groups = ["${aws_security_group.ecs-instance.id}"]
  }

  egress {
    description = "NTP"
    protocol    = "udp"
    from_port   = 123
    to_port     = 123
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.application_name}-rds-${terraform.env}"
    Role    = "rds"
    Env     = "${terraform.env}"
    AppName = "${var.application_name}"
  }
}

##
# ElastiCache - Redis
##
resource "aws_security_group" "elasticache" {
  name        = "${var.application_name}-elasticache-${terraform.env}"
  description = "ElastiCache"
  vpc_id      = "${aws_vpc.main.id}"

  ingress {
    description = "Redis"
    protocol    = "tcp"
    from_port   = 6379
    to_port     = 6379

    # NOTE: ECSからのみアクセスできる
    security_groups = ["${aws_security_group.ecs-instance.id}"]
  }

  egress {
    description = "NTP"
    protocol    = "udp"
    from_port   = 123
    to_port     = 123
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.application_name}-elasticache-${terraform.env}"
    Role    = "elasticache"
    Env     = "${terraform.env}"
    AppName = "${var.application_name}"
  }
}
