

variable "project_name" {
  description = "Project name used for tagging and naming the ECR repository."
  type        = string
}

variable "repository_name" {
  description = "Name of the ECR repository to create."
  type        = string
  default     = "aws-ha-webapp-app"
}

variable "scan_on_push" {
  description = "Enable vulnerability scanning on image push."
  type        = bool
  default     = true
}

variable "retain_images" {
  description = "Number of images to retain before lifecycle expiration."
  type        = number
  default     = 10
}

variable "tags" {
  description = "Common tags applied to ECR resources."
  type        = map(string)
  default     = {}
}