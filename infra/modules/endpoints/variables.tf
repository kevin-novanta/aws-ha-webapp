variable "project_name" {
  description = "Project name for tagging"
  type        = string
}

variable "region" {
  description = "AWS region (e.g., us-east-1)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to attach VPC endpoints to"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for Interface endpoints"
  type        = list(string)
}

variable "private_route_table_ids" {
  description = "Private route table IDs for Gateway endpoints (e.g., S3)"
  type        = list(string)
}

variable "endpoint_sg_id" {
  description = "Security Group ID to attach to Interface endpoints"
  type        = string
}

variable "app_sg_id" {
  description = "(Optional) App SG ID if you add SG rules to allow 443 into the endpoint SG"
  type        = string
  default     = null
}

variable "enable_endpoints" {
  description = "Master toggle to create endpoints"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
