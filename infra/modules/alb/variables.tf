

variable "project_name" {
  description = "Project name used for tagging and naming ALB resources."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC in which to create the ALB and Target Group."
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs where the ALB will be deployed (one per AZ)."
  type        = list(string)
}

variable "alb_sg_id" {
  description = "Security Group ID attached to the ALB."
  type        = string
}

variable "acm_cert_arn" {
  description = "ACM certificate ARN for HTTPS listener. If empty, module stays HTTP-only."
  type        = string
  default     = ""
}

variable "target_port" {
  description = "Port on which the application listens (Target Group port)."
  type        = number
  default     = 8080
}

variable "health_check_path" {
  description = "HTTP path used by the ALB target group health checks."
  type        = string
  default     = "/health"
}

variable "tags" {
  description = "Common tags applied to ALB resources."
  type        = map(string)
  default     = {}
}


# was referenced by tfvars already
variable "multi_az" {
  description = "Whether to enable Multi-AZ for RDS in this environment"
  type        = bool
  default     = false
}