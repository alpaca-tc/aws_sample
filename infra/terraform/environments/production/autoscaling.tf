resource "aws_autoscaling_group" "main" {
  name                 = "main"
  availability_zones   = ["${data.aws_availability_zones.available.names}"]
  vpc_zone_identifier  = ["${aws_subnet.private-nat.*.id}"]
  min_size             = 1
  max_size             = 10
  desired_capacity     = 3
  launch_configuration = "${aws_launch_configuration.ecs.name}"
}

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
