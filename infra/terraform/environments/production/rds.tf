resource "aws_db_subnet_group" "main" {
  name       = "main"
  subnet_ids = ["${aws_subnet.private.*.id}"]
}

resource "aws_rds_cluster_instance" "cluster_instances" {
  count               = "${var.rds_instance_count}"
  identifier          = "${var.application_name}-${count.index}-${terraform.env}"
  cluster_identifier  = "${aws_rds_cluster.main.id}"
  instance_class      = "${var.instance_types["rds"]}"
  engine              = "aurora-mysql"
  engine_version      = "5.7.12"
  publicly_accessible = false

  db_parameter_group_name = "${aws_db_parameter_group.main.name}"
  db_subnet_group_name    = "${aws_db_subnet_group.main.name}"

  tags = {
    Name    = "${var.application_name}-rds-${terraform.env}"
    Role    = "rds"
    Env     = "${terraform.env}"
    AppName = "${var.application_name}"
  }

  depends_on = [
    "aws_rds_cluster.main",
  ]
}

resource "aws_rds_cluster" "main" {
  availability_zones   = ["${data.aws_availability_zones.available.names}"]
  cluster_identifier   = "${var.application_name}-${terraform.env}"
  port                 = 3306
  database_name        = "${var.application_name}_production"
  db_subnet_group_name = "${aws_db_subnet_group.main.name}"
  engine               = "aurora-mysql"
  engine_version       = "5.7.12"

  db_cluster_parameter_group_name = "${aws_rds_cluster_parameter_group.main.name}"

  vpc_security_group_ids = [
    "${aws_security_group.rds.id}",
  ]

  master_username         = "root"
  master_password         = "${data.aws_kms_secret.rds.master_password}"
  backup_retention_period = 7                                            # days

  storage_encrypted = true
  kms_key_id        = "${aws_kms_key.rds-encryption.arn}"

  final_snapshot_identifier = "${var.application_name}-${terraform.env}"
  skip_final_snapshot       = false

  preferred_backup_window      = "01:00-02:00"
  preferred_maintenance_window = "Mon:02:30-Mon:04:30"
}

resource "aws_db_parameter_group" "main" {
  name        = "${var.application_name}-${terraform.env}"
  family      = "aurora-mysql5.7"
  description = "main parameter group"

  # for barracuda
  parameter {
    name  = "innodb_large_prefix"
    value = 1
  }

  # for barracuda
  parameter {
    name  = "innodb_file_format"
    value = "Barracuda"
  }

  # TODO: Optimize: https://dba.stackexchange.com/questions/1229/how-do-you-calculate-mysql-max-connections-variable
  parameter {
    name  = "max_connections"
    value = 4096
  }

  tags = {
    Name    = "${var.application_name}-main-${terraform.env}"
    Role    = "rds"
    Env     = "${terraform.env}"
    AppName = "${var.application_name}"
  }
}

resource "aws_rds_cluster_parameter_group" "main" {
  name        = "${var.application_name}-${terraform.env}"
  description = "main cluster parameter group"
  family      = "aurora-mysql5.7"

  parameter {
    name  = "character_set_client"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_connection"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_database"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_results"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }

  parameter {
    name  = "collation_connection"
    value = "utf8mb4_bin"
  }

  parameter {
    name  = "collation_server"
    value = "utf8mb4_bin"
  }

  # for barracuda
  parameter {
    name         = "innodb_file_per_table"
    value        = 1
    apply_method = "pending-reboot"
  }

  tags = {
    Name    = "${var.application_name}-main-${terraform.env}"
    Role    = "rds"
    Env     = "${terraform.env}"
    AppName = "${var.application_name}"
  }
}
