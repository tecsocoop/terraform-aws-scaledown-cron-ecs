locals {
  services = toset(var.services)
}

##########################################
#### Application Auto Scaling: target ####
##########################################

# Registers the ECS service as an Application Auto Scaling scalable target.
# Skip (create_scalable_target = false) if the service is already registered
# elsewhere, since AWS allows only one scalable target per service+dimension.
resource "aws_appautoscaling_target" "this" {
  for_each = var.create_scalable_target ? local.services : []

  max_capacity       = var.start_max_capacity
  min_capacity       = var.start_min_capacity
  resource_id        = "service/${var.cluster_name}/${each.value}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  # The scheduled actions below change min/max capacity directly on AWS at
  # runtime (outside Terraform). Ignore drift here so a later `terraform
  # apply` doesn't fight the schedule depending on when it happens to run.
  lifecycle {
    ignore_changes = [min_capacity, max_capacity]
  }
}

######################################################
#### Application Auto Scaling: scheduled actions ####
######################################################

# Scale down: force min=max (defaults to 0/0) so the service's desired count
# drops to 0. For EC2 capacity providers, this in turn lets ECS's own managed
# scaling terminate the underlying EC2 instances (see README).
resource "aws_appautoscaling_scheduled_action" "stop" {
  for_each = local.services

  name               = "${var.name}-scaledown-cron-ecs-${each.value}-stop"
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${each.value}"
  scalable_dimension = "ecs:service:DesiredCount"
  schedule           = var.cron_stop

  scalable_target_action {
    min_capacity = var.stop_min_capacity
    max_capacity = var.stop_max_capacity
  }

  depends_on = [aws_appautoscaling_target.this]
}

# Scale up: restore min/max capacity so Application Auto Scaling brings the
# service (and, for EC2 capacity providers, the underlying instances) back up.
resource "aws_appautoscaling_scheduled_action" "start" {
  for_each = local.services

  name               = "${var.name}-scaledown-cron-ecs-${each.value}-start"
  service_namespace  = "ecs"
  resource_id        = "service/${var.cluster_name}/${each.value}"
  scalable_dimension = "ecs:service:DesiredCount"
  schedule           = var.cron_start

  scalable_target_action {
    min_capacity = var.start_min_capacity
    max_capacity = var.start_max_capacity
  }

  depends_on = [aws_appautoscaling_target.this]
}
