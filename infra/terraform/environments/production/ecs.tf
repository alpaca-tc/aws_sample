resource "aws_launch_configuration" "ecs" {
  security_groups = [
    "${aws_security_group.ecs_instance.id}",
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

resource "aws_security_group" "alb" {
  description = "Controls access to the application ELB"

  vpc_id = "${aws_vpc.main.id}"
  name   = "alb"

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

resource "aws_security_group" "ecs_instance" {
  description = "Controls direct access to ecs instances"
  vpc_id      = "${aws_vpc.main.id}"
  name        = "ecs_instance"

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
      "${aws_security_group.alb.id}",
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

##
# ECS
##
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
    "aws_alb_listener.rails",
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
  vpc_zone_identifier  = ["${aws_subnet.public.*.id}"]
  min_size             = 1
  max_size             = 2
  desired_capacity     = 2
  launch_configuration = "${aws_launch_configuration.ecs.name}"
}
