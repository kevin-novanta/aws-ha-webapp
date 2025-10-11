

variable "project_name" {
  description = "Project name used for tagging and resource naming."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC (e.g., 10.0.0.0/16)."
  type        = string
  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid CIDR block (e.g., 10.0.0.0/16)."
  }
}

variable "azs" {
  description = "List of availability zones to spread subnets across (e.g., [\"us-east-1a\", \"us-east-1b\"])."
  type        = list(string)
  validation {
    condition     = length(var.azs) >= 2
    error_message = "Provide at least two AZs for high availability."
  }
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets (one per AZ)."
  type        = list(string)
}

variable "private_app_subnets" {
  description = "CIDR blocks for private application subnets (one per AZ)."
  type        = list(string)
}

variable "private_db_subnets" {
  description = "CIDR blocks for private database subnets (one per AZ)."
  type        = list(string)
}

variable "tags" {
  description = "Common tags applied to all resources in this module."
  type        = map(string)
  default     = {}
}

# Ensure the number of subnets matches the number of AZs
locals {
  _subnet_lengths_match = (
    length(var.public_subnets) == length(var.azs) &&
    length(var.private_app_subnets) == length(var.azs) &&
    length(var.private_db_subnets) == length(var.azs)
  )
}

# Terraform lacks cross-variable validation blocks, so we implement with a null_resource guard
resource "null_resource" "validate_subnet_counts" {
  count = local._subnet_lengths_match ? 0 : 1

  triggers = {
    error = "The counts of public_subnets, private_app_subnets, and private_db_subnets must each equal the number of AZs."
  }
}