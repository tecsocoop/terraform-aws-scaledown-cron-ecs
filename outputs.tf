output "scalable_target_resource_ids" {
  description = "Resource IDs registered as Application Auto Scaling scalable targets, keyed by service name."
  value       = { for k, v in aws_appautoscaling_target.this : k => v.resource_id }
}

output "scheduled_action_stop_arns" {
  description = "ARNs of the scale-down scheduled actions, keyed by service name."
  value       = { for k, v in aws_appautoscaling_scheduled_action.stop : k => v.arn }
}

output "scheduled_action_start_arns" {
  description = "ARNs of the scale-up scheduled actions, keyed by service name."
  value       = { for k, v in aws_appautoscaling_scheduled_action.start : k => v.arn }
}
