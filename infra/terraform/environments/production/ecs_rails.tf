resource "aws_ecs_cluster" "main" {
  name = "rails-application"
}

resource "aws_ecs_service" "rails" {
  name            = "rails"
  cluster         = "${aws_ecs_cluster.main.id}"
  task_definition = "${aws_ecs_task_definition.rails.arn}"
  desired_count   = 1
  iam_role        = "${aws_iam_role.ecs_service_role.name}"

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.rails.arn}"
    container_name   = "sample"
    container_port   = 3000
  }

  depends_on = [
    "aws_alb_listener.rails",
  ]
}

resource "aws_ecs_task_definition" "rails" {
  family                = "rails-application"
  network_mode          = "bridge"
  container_definitions = "${data.template_file.rails.rendered}"
}

data "template_file" "rails" {
  template = "${file("${path.module}/task-definition.json")}"

  vars {
    image_url        = "${var.image_urls["rack_application"]}"
    container_name   = "sample"
    log_group_region = "${var.region}"
    log_group_name   = "${aws_cloudwatch_log_group.app.name}"

    # NOTE: task-definitionに埋め込まれるので、IAMで閲覧権限を絞るとよい
    # config/credentials.yml.enc を復号する
    rails_master_key = "${replace(data.aws_kms_secret.rails-credentials.master-key, "\n", "")}"
  }
}
