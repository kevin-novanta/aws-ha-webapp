

variable "project_name" {
  description = "Project name used for tagging and naming observability resources."
  type        = string
}

variable "tags" {
  description = "Common tags applied to CloudWatch alarms and subscriptions."
  type        = map(string)
  default     = {}
}

variable "enable_alarms" {
  description = "Toggle to enable or disable CloudWatch alarms."
  type        = bool
  default     = true
}

variable "alb_arn" {
  description = "ARN of the Application Load Balancer for 5xx rate monitoring."
  type        = string
}

variable "tg_arn" {
  description = "ARN of the Target Group for UnHealthyHostCount monitoring."
  type        = string
}

variable "asg_name" {
  description = "Auto Scaling Group name for instance health monitoring."
  type        = string
}

variable "rds_arn" {
  description = "ARN of the RDS instance for event subscriptions."
  type        = string
  default     = ""
}

variable "enable_rds_events" {
  description = "Enable RDS event subscription alarms."
  type        = bool
  default     = false
}

variable "sns_topic_arn" {
  description = "SNS topic ARN to send notifications for alarms and RDS events."
  type        = string
  default     = ""
}

# ---- Tunable thresholds ----
variable "alb_5xx_rate_threshold" {
  description = "Threshold percentage for ALB 5xx error rate alarm."
  type        = number
  default     = 5
}

variable "alb_5xx_eval_periods" {
  description = "Number of 1-minute periods evaluated for ALB 5xx alarm."
  type        = number
  default     = 5
}

variable "tg_unhealthy_eval_periods" {
  description = "Number of evaluation periods for Target Group UnHealthyHostCount alarm."
  type        = number
  default     = 2
}

variable "asg_inservice_threshold" {
  description = "Minimum number of InService instances expected in the ASG."
  type        = number
  default     = 1
}

variable "asg_inservice_eval_periods" {
  description = "Number of evaluation periods for ASG InService alarm."
  type        = number
  default     = 2
}

variable "engine_version" {
  type        = string
  default     = "15" # or "16"
  description = "PostgreSQL engine version"
}