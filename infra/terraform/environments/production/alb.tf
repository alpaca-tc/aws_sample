resource "aws_alb" "main" {
  name            = "main"
  subnets         = ["${aws_subnet.public.*.id}"]
  security_groups = ["${aws_security_group.alb.id}"]
  internal        = false

  access_logs {
    enabled = true
    bucket  = "${aws_s3_bucket.alb-access-logs.bucket}"
    prefix  = "main-${terraform.env}"
  }

  tags = {
    Name    = "${var.application_name}-${terraform.env}"
    Env     = "${terraform.env}"
    AppName = "${var.application_name}"
  }
}

##
# Rails application
##
resource "aws_alb_target_group" "rails" {
  name                 = "rails"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = "${aws_vpc.main.id}"
  deregistration_delay = 30

  health_check {
    path     = "/"
    protocol = "HTTP"
    matcher  = "200"

    # TODO: 消す
    timeout             = 60
    interval            = 300
    unhealthy_threshold = 10
  }
}

resource "aws_alb_listener" "rails" {
  load_balancer_arn = "${aws_alb.main.id}"
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.rails.arn}"
    type             = "forward"
  }
}

resource "aws_alb_listener" "rails-https" {
  load_balancer_arn = "${aws_alb.main.id}"
  port              = 443
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.rails.arn}"
    type             = "forward"
  }
}

##
# - redirect http to https
# - www.domain -> domain
##
resource "aws_alb_target_group" "nginx-http2https" {
  name                 = "${var.application_name}-http2https-${terraform.env}"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = "${aws_vpc.main.id}"
  deregistration_delay = 30

  health_check {
    path     = "/"
    protocol = "HTTP"
    matcher  = "301"
  }
}

resource "aws_alb_listener" "nginx-http2https" {
  load_balancer_arn = "${aws_alb.main.id}"

  # TODO: 80にする
  port     = 8080
  protocol = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.nginx-http2https.arn}"
    type             = "forward"
  }
}
