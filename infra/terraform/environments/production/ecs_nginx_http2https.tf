resource "aws_ecs_service" "nginx-http2https" {
  name            = "nginx-http2https"
  cluster         = "${aws_ecs_cluster.main.id}"
  task_definition = "${aws_ecs_task_definition.nginx-http2https.arn}"
  iam_role        = "${aws_iam_role.ecs_service_role.name}"
  desired_count   = 1

  deployment_minimum_healthy_percent = 50

  placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  placement_strategy {
    type  = "binpack"
    field = "cpu"
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.nginx-http2https.arn}"
    container_name   = "nginx-http2https"
    container_port   = 80
  }

  depends_on = ["aws_alb_listener.nginx-http2https"]
}

resource "aws_ecs_task_definition" "nginx-http2https" {
  family                = "nginx-http2https-application"
  network_mode          = "bridge"
  container_definitions = "${data.template_file.nginx-http2https.rendered}"
}

data "template_file" "nginx-http2https" {
  template = "${file("${path.module}/nginx-http2https-task-definition.json")}"

  vars {
    image_url        = "${var.image_urls["nginx-http2https"]}"
    container_name   = "nginx-http2https"
    log_group_region = "${var.region}"
    log_group_name   = "${aws_cloudwatch_log_group.app.name}"
  }
}
