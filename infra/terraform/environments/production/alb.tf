## ALB
resource "aws_alb" "main" {
  name            = "main"
  subnets         = ["${aws_subnet.public.*.id}"]
  security_groups = ["${aws_security_group.alb.id}"]
  internal        = false

  tags = {
    Name    = "${var.application_name}-${terraform.env}"
    Env     = "${terraform.env}"
    AppName = "${var.application_name}"
  }
}

resource "aws_alb_target_group" "rails" {
  name     = "rails"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = "${aws_vpc.main.id}"

  health_check {
    path     = "/"
    protocol = "HTTP"
    matcher  = "200"
  }
}

resource "aws_alb_listener" "rails" {
  load_balancer_arn = "${aws_alb.main.id}"
  port              = "3000"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.rails.id}"
    type             = "forward"
  }
}
