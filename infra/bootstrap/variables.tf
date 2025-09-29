

variable "bucket_name" {
  description = "Name of the S3 bucket to store Terraform state. Must be globally unique."
  type        = string
}

variable "table_name" {
  description = "Name of the DynamoDB table for Terraform state locking."
  type        = string
}

variable "region" {
  description = "AWS region where state backend resources will be created."
  type        = string
}

variable "tags" {
  description = "Optional map of tags to apply to all resources."
  type        = map(string)
  default     = {}
}