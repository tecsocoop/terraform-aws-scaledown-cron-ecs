# terraform-aws-scaledown-cron-ecs

Terraform module that scales down/up **ECS services** on a schedule, using native **Application Auto Scaling scheduled actions**. Typical use: turn off non-prod ECS environments overnight so no tasks — and, on EC2 capacity providers, no EC2 instances — stay running.

Schedules are always evaluated in **UTC**.

## Requirements

| Name      | Version   |
|-----------|-----------|
| terraform | >= 1.3.7  |
| aws       | >= 5.9.0  |

## How it works

- **Scale down:** sets `min_capacity`/`max_capacity` (default `0`/`0`) on `cron_stop`.
- **Scale up:** restores `min_capacity`/`max_capacity` (default `1`/`1`) on `cron_start`.
- Behavior: *"If current capacity is less than the minimum, Application Auto Scaling scales out... If current capacity is greater than the maximum, it scales in..."* — [How scheduled scaling works](https://docs.aws.amazon.com/autoscaling/application/userguide/scheduled-scaling-policy-overview.html)
- `lifecycle.ignore_changes` on the target's `min_capacity`/`max_capacity` prevents `terraform apply` from fighting the values the schedule sets on AWS.

## Important

- List **every** ECS service that shares the target capacity provider's ASG in `services`; otherwise `CapacityProviderReservation` never reaches 0 and instances are never terminated.
- `DAEMON` services are unaffected by `desired_count` scaling but don't block scale-in either — ECS ignores them.
- Set `create_scalable_target = false` if the service already has a scalable target elsewhere (only one is allowed per service).
- Instance termination lags a few minutes behind the service reaching 0 (managed-scaling evaluation).

## Usage

Example: turn off from **20:00 to 08:00 Argentina time (UTC-3)**, i.e. **23:00 to 11:00 UTC**:

```hcl
module "scaledown_ecs_dev" {
  source  = "tecsocoop/scaledown-cron-ecs/aws"
#  version = "X.X.X" # see the latest available tag

  name         = "${var.environment}-${var.name}"
  cluster_name = "dev-cluster"

  services = [
    "api",
    "worker",
    "scheduler",
  ]

  cron_stop  = "cron(0 23 * * ? *)" # 20:00 ART = 23:00 UTC
  cron_start = "cron(0 11 * * ? *)" # 08:00 ART = 11:00 UTC

  stop_min_capacity  = 0
  stop_max_capacity  = 0

  start_min_capacity = 1
  start_max_capacity = 1
}
```

## Variables

| Variable | Description | Default |
|---|---|---|
| `name` | Prefix used to name the scheduled actions | required |
| `cluster_name` | Name of the ECS cluster | required |
| `services` | List of ECS service names to control | required |
| `create_scalable_target` | Register the scalable target for each service | `true` |
| `cron_stop` | Cron expression to scale down (UTC, 6-field format) | required |
| `cron_start` | Cron expression to scale back up (UTC, 6-field format) | required |
| `stop_min_capacity` | Minimum desired count when scaling down | `0` |
| `stop_max_capacity` | Maximum desired count when scaling down | `0` |
| `start_min_capacity` | Minimum desired count when scaling up | `1` |
| `start_max_capacity` | Maximum desired count when scaling up | `1` |

## Outputs

| Output | Description |
|---|---|
| `scalable_target_resource_ids` | Resource IDs registered as scalable targets, keyed by service name |
| `scheduled_action_stop_arns` | ARNs of the scale-down scheduled actions, keyed by service name |
| `scheduled_action_start_arns` | ARNs of the scale-up scheduled actions, keyed by service name |

## Why the ECS service, not the Auto Scaling Group

AWS recommends not touching the ASG's desired capacity directly when it's used by an ECS capacity provider with Managed Scaling:

> "Don't change or manage the desired capacity for the Auto Scaling group that's associated with a capacity provider with any scaling policies other than the one Amazon ECS manages."
> — [Automatically manage Amazon ECS capacity with cluster auto scaling](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/cluster-auto-scaling.html)

Instead, this module scales the ECS **service's `desired_count`**. `CapacityProviderReservation` drops accordingly and ECS's own managed scaling scales the ASG down/up automatically. Reference: [Scheduled scaling for Application Auto Scaling](https://docs.aws.amazon.com/autoscaling/application/userguide/application-auto-scaling-scheduled-scaling.html). Works unchanged on Fargate too (no ASG involved).


## License

Licensed under the [Apache License 2.0](LICENSE).
