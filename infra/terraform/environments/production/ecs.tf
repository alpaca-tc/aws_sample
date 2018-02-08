resource "aws_launch_configuration" "app" {
  security_groups = [
    "${aws_security_group.instance_sg.id}",
  ]

  key_name                    = "${aws_key_pair.application.key_name}"
  image_id                    = "ami-872c4ae1"
  instance_type               = "${var.instance_types["aws_launch_configuration"]}"
  iam_instance_profile        = "${aws_iam_instance_profile.ecs.name}"
  associate_public_ip_address = true

  user_data = <<EOF
#!/bin/bash

echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "lb_sg" {
  description = "controls access to the application ELB"

  vpc_id = "${aws_vpc.main.id}"
  name   = "tf-ecs-lbsg"

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
}

resource "aws_security_group" "instance_sg" {
  description = "controls direct access to application instances"
  vpc_id      = "${aws_vpc.main.id}"
  name        = "tf-ecs-instsg"

  ingress {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22

    cidr_blocks = [
      "${var.admin_cidr_ingress}",
    ]
  }

  ingress {
    protocol  = "tcp"
    from_port = 3000
    to_port   = 3000

    security_groups = [
      "${aws_security_group.lb_sg.id}",
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

## ECS

resource "aws_ecs_cluster" "main" {
  name = "terraform_example_ecs_cluster"
}

resource "aws_ecs_service" "rails" {
  name            = "rails"
  cluster         = "${aws_ecs_cluster.main.id}"
  task_definition = "${aws_ecs_task_definition.sample.arn}"
  desired_count   = 1
  iam_role        = "${aws_iam_role.ecs_service_role.name}"

  load_balancer {
    target_group_arn = "${aws_alb_target_group.rails.id}"
    container_name   = "sample"
    container_port   = "3000"
  }

  depends_on = [
    "aws_alb_listener.front_end",
  ]
}

resource "aws_ecs_task_definition" "sample" {
  family                = "sample_ecs_task_definition"
  container_definitions = "${data.template_file.task_definition.rendered}"
}

data "template_file" "task_definition" {
  template = "${file("${path.module}/task-definition.json")}"

  vars {
    image_url        = "016559158979.dkr.ecr.ap-northeast-1.amazonaws.com/sample:latest"
    container_name   = "sample"
    log_group_region = "${var.region}"
    log_group_name   = "${aws_cloudwatch_log_group.app.name}"
  }
}

# Autoscaling
resource "aws_autoscaling_group" "main" {
  name                 = "main"
  vpc_zone_identifier  = ["${aws_subnet.main.*.id}"]
  min_size             = 2
  max_size             = 2
  desired_capacity     = 2
  launch_configuration = "${aws_launch_configuration.app.name}"
}

## ALB
resource "aws_alb" "main" {
  name            = "tf-example-alb-ecs"
  subnets         = ["${aws_subnet.main.*.id}"]
  security_groups = ["${aws_security_group.lb_sg.id}"]
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

resource "aws_alb_listener" "front_end" {
  load_balancer_arn = "${aws_alb.main.id}"
  port              = "3000"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.rails.id}"
    type             = "forward"
  }
}
