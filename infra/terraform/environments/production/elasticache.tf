resource "aws_elasticache_subnet_group" "sidekiq" {
  name       = "sidekiq"
  subnet_ids = ["${aws_subnet.private.*.id}"]
}

# https://www.terraform.io/docs/providers/aws/r/elasticache_replication_group.html
resource "aws_elasticache_replication_group" "sidekiq" {
  replication_group_id          = "${var.application_name}-sidekiq"
  replication_group_description = "sidekiq"

  # TODO: not supported for T1 and T2 cache node types
  automatic_failover_enabled = false

  port                  = 6379
  node_type             = "${var.instance_types["elasticache_sidekiq"]}"
  security_group_ids    = ["${aws_security_group.elasticache.id}"]
  subnet_group_name     = "${aws_elasticache_subnet_group.sidekiq.name}"
  number_cache_clusters = "${var.sidekiq["number_cache_clusters"]}"

  tags = {
    Name    = "${var.application_name}-sidekiq-${terraform.env}"
    Env     = "${terraform.env}"
    AppName = "${var.application_name}"
  }
}

/* resource "aws_elasticache_replication_group" "sidekiq" { */
/*   replication_group_id          = "sidekiq" */
/*   replication_group_description = "Redis cluster for sidekiq" */
/*  */
/*   node_type            = "elasticache_sidekiq" */
/*   port                 = 6379 */
/*  */
/*   snapshot_retention_limit = 0 */
/*  */
/*   subnet_group_name          = "${aws_elasticache_subnet_group.sidekiq.name}" */
/*   automatic_failover_enabled = true */
/*  */
/*   cluster_mode { */
/*     replicas_per_node_group = 1 */
/*     num_node_groups         = "${var.node_groups}" */
/*   } */
/* } */

