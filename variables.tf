variable "name" {
  description = "Prefix used to name the scheduled actions created by this module. E.g. 'dev-tecso'"
  type        = string
}

variable "cluster_name" {
  description = "Name of the ECS cluster that hosts the services to control."
  type        = string
}

variable "services" {
  description = "Names of the ECS services to scale down/up on schedule. Include every service that shares the target EC2 capacity provider's Auto Scaling group, otherwise the group will never reach 0 running instances (see README)."
  type        = list(string)

  validation {
    condition     = length(var.services) > 0
    error_message = "At least one service name must be provided."
  }
}

variable "create_scalable_target" {
  description = "Whether to register each ECS service as an Application Auto Scaling scalable target. Set to false if the service already has a scalable target registered elsewhere (e.g. a CPU/memory target-tracking policy) -- only one scalable target can exist per service + dimension."
  type        = bool
  default     = true
}

variable "cron_stop" {
  description = "Cron expression (Application Auto Scaling 6-field format: Minutes Hours Day-of-Month Month Day-of-Week Year), always evaluated in UTC. E.g. 'cron(0 23 * * ? *)'."
  type        = string
}

variable "cron_start" {
  description = "Cron expression (Application Auto Scaling 6-field format), always evaluated in UTC. E.g. 'cron(0 11 * * ? *)'."
  type        = string
}

variable "stop_min_capacity" {
  description = "Minimum desired count to force when scaling down. Normally 0."
  type        = number
  default     = 0
}

variable "stop_max_capacity" {
  description = "Maximum desired count to force when scaling down. Normally 0."
  type        = number
  default     = 0
}

variable "start_min_capacity" {
  description = "Minimum desired count to restore when scaling back up."
  type        = number
  default     = 1
}

variable "start_max_capacity" {
  description = "Maximum desired count to restore when scaling back up."
  type        = number
  default     = 1
}
