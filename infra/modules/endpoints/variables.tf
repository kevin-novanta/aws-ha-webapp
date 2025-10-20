

variable "project_name" {
  description = "Project name used for tagging and naming VPC endpoints."
  type        = string
}

variable "region" {
  description = "AWS region (used to build endpoint service names)."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the endpoints will be created."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for Interface endpoints (SSM, SSMMessages, Secrets Manager)."
  type        = list(string)
}

variable "private_route_table_ids" {
  description = "Private route table IDs for the S3 Gateway endpoint."
  type        = list(string)
}

variable "endpoint_sg_id" {
  description = "Security group ID to attach to Interface endpoints."
  type        = string
}

# Master toggle and per-service toggles
variable "enable_endpoints" {
  description = "Master toggle to enable/disable all endpoints in this module."
  type        = bool
  default     = false
}

variable "enable_ssm" {
  description = "Create Interface endpoint for SSM."
  type        = bool
  default     = true
}

variable "enable_ssmmessages" {
  description = "Create Interface endpoint for SSM Messages."
  type        = bool
  default     = true
}

variable "enable_secretsmanager" {
  description = "Create Interface endpoint for Secrets Manager."
  type        = bool
  default     = true
}

variable "enable_s3" {
  description = "Create Gateway endpoint for S3."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags applied to all endpoint resources."
  type        = map(string)
  default     = {}
}