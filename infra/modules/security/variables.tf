

variable "project_name" {
  description = "Project name used for tagging and naming security groups."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the security groups will be created."
  type        = string
}

variable "allowed_cidrs" {
  description = "CIDR blocks allowed to reach the ALB. Defaults to 0.0.0.0/0; restrict in non-prod as needed."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "app_port" {
  description = "Port that the application listens on (ALB -> App)."
  type        = number
  default     = 8080
}

variable "db_port" {
  description = "Database port exposed by the DB to the app tier (e.g., 5432 for Postgres or 3306 for MySQL)."
  type        = number
  default     = 5432
}

variable "tags" {
  description = "Common tags to apply to all security groups."
  type        = map(string)
  default     = {}
}

# Optional peer security group references if you want to plug in existing SGs
# Instead of creating all SGs here, you could pass external ones. Leave null to create within the module.
variable "external_alb_sg_id" {
  description = "If provided, use an existing ALB security group instead of creating one."
  type        = string
  default     = null
}

variable "external_app_sg_id" {
  description = "If provided, use an existing App security group instead of creating one."
  type        = string
  default     = null
}

variable "external_db_sg_id" {
  description = "If provided, use an existing DB security group instead of creating one."
  type        = string
  default     = null
}