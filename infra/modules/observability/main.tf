############################################
# aws-ha-webapp — Observability Module
# Purpose: CloudWatch alarms (and optional event subscriptions)
# NOTE: This file was named `mai.tf` — rename to `main.tf` to follow convention.
############################################

# ---- Locals: derive ALB/TG metric dimension suffixes from ARNs ----
# ALB CloudWatch metrics use the ARN *suffix* (e.g., "app/xyz/123") as the LoadBalancer dimension.
# TG metrics use the TargetGroup dimension as "targetgroup/xyz/123" plus the LoadBalancer dimension.
locals {
  # Defensive parsing: if ARNs are empty or incomplete, produce empty suffixes
  lb_parts  = var.alb_arn == "" ? [] : split("/", var.alb_arn)
  lb_suffix = length(local.lb_parts) >= 6 ? join("/", slice(local.lb_parts, 5, length(local.lb_parts))) : ""

  tg_parts  = var.tg_arn == "" ? [] : split("/", var.tg_arn)
  tg_suffix = length(local.tg_parts) >= 6 ? join("/", slice(local.tg_parts, 5, length(local.tg_parts))) : ""
}

# -----------------------------
# ALB 5xx rate alarm (metric math)
# -----------------------------
resource "aws_cloudwatch_metric_alarm" "alb_5xx_rate" {
  count               = (var.enable_alarms && local.lb_suffix != "") ? 1 : 0
  alarm_name          = "${var.project_name}-alb-5xx-rate"
  alarm_description   = "ALB 5xx percentage over requests exceeds threshold"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  threshold           = 5 # percent; adjust via variables.tf if desired
  treat_missing_data  = "missing"
  datapoints_to_alarm = 3

  metric_query {
    id          = "m5xx"
    return_data = false
    metric {
      metric_name = "HTTPCode_ELB_5XX_Count"
      namespace   = "AWS/ApplicationELB"
      period      = 60
      stat        = "Sum"
      dimensions = {
        LoadBalancer = local.lb_suffix
      }
    }
  }

  metric_query {
    id          = "mreq"
    return_data = false
    metric {
      metric_name = "RequestCount"
      namespace   = "AWS/ApplicationELB"
      period      = 60
      stat        = "Sum"
      dimensions = {
        LoadBalancer = local.lb_suffix
      }
    }
  }

  metric_query {
    id          = "rate"
    expression  = "100 * (m5xx / mreq)"
    label       = "ALB 5xx %"
    return_data = true
  }
}

# ----------------------------------------
# Target Group UnHealthyHostCount > 0
# ----------------------------------------
resource "aws_cloudwatch_metric_alarm" "tg_unhealthy" {
  count               = (var.enable_alarms && local.lb_suffix != "" && local.tg_suffix != "") ? 1 : 0
  alarm_name          = "${var.project_name}-tg-unhealthy-hosts"
  alarm_description   = "One or more targets in the ALB Target Group are unhealthy"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 0
  treat_missing_data  = "missing"

  metric_name = "UnHealthyHostCount"
  namespace   = "AWS/ApplicationELB"
  period      = 60
  statistic   = "Maximum"

  dimensions = {
    TargetGroup  = local.tg_suffix
    LoadBalancer = local.lb_suffix
  }
}

# ----------------------------------------
# ASG health: InService instances < 1
# (Note: requires ASG metrics enabled in the ASG module to be fully effective)
# ----------------------------------------
resource "aws_cloudwatch_metric_alarm" "asg_inservice_low" {
  count               = var.enable_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-asg-inservice-low"
  alarm_description   = "Auto Scaling Group has fewer than 1 InService instances"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  threshold           = 1
  treat_missing_data  = "breaching"

  metric_name = "GroupInServiceInstances"
  namespace   = "AWS/AutoScaling"
  period      = 60
  statistic   = "Average"

  dimensions = {
    AutoScalingGroupName = var.asg_name
  }
}

# ----------------------------------------
# RDS event subscription (failover/failure/availability)
# Only created when explicitly enabled and SNS topic provided.
# ----------------------------------------
resource "aws_db_event_subscription" "rds_events" {
  count            = var.enable_rds_events && var.sns_topic_arn != "" ? 1 : 0
  name             = "${var.project_name}-rds-events"
  sns_topic        = var.sns_topic_arn
  source_type      = "db-instance"
  event_categories = ["failover", "failure", "availability"]
  enabled          = true

  # Extract DB identifier from ARN (everything after "db:")
  source_ids = [
    replace(var.rds_arn, "^arn:aws:rds:[^:]+:[0-9]+:db:", "")
  ]

  tags = merge(var.tags, {
    Project = var.project_name
  })
}
