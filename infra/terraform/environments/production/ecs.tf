resource "aws_launch_configuration" "ecs" {
  key_name             = "${aws_key_pair.bastion.key_name}"
  image_id             = "ami-872c4ae1"
  instance_type        = "${var.instance_types["aws_launch_configuration"]}"
  iam_instance_profile = "${aws_iam_instance_profile.ecs.name}"

  security_groups = [
    "${aws_security_group.ecs-instance.id}",
    "${aws_security_group.to-nat-gateway.id}",
  ]

  associate_public_ip_address = false

  user_data = <<EOF
#!/bin/bash

echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
EOF

  lifecycle {
    create_before_destroy = true
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
    image_url        = "${var.image_urls["rack_application"]}"
    container_name   = "sample"
    log_group_region = "${var.region}"
    log_group_name   = "${aws_cloudwatch_log_group.app.name}"
  }
}

# Autoscaling
resource "aws_autoscaling_group" "main" {
  name                 = "main"
  vpc_zone_identifier  = ["${aws_subnet.private-nat.*.id}"]
  min_size             = 1
  max_size             = 1
  desired_capacity     = 1
  launch_configuration = "${aws_launch_configuration.ecs.name}"
}
