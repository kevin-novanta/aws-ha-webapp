

variable "project_name" {
  description = "Project name used for tagging and naming ASG resources."
  type        = string
}

variable "tags" {
  description = "Common tags applied to ASG and EC2 instances."
  type        = map(string)
  default     = {}
}

variable "private_app_subnet_ids" {
  description = "List of private subnet IDs for the Auto Scaling Group."
  type        = list(string)
}

variable "app_sg_id" {
  description = "Security Group ID for application instances."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for application instances."
  type        = string
  default     = "t3.micro"
}

variable "instance_profile_name" {
  description = "IAM instance profile name that grants EC2 access to SSM and ECR."
  type        = string
}

variable "ecr_repo_uri" {
  description = "ECR repository URI from which to pull the application image."
  type        = string
}

variable "image_tag" {
  description = "Image tag to deploy from ECR."
  type        = string
  default     = "latest"
}

variable "app_port" {
  description = "Port on which the application container listens."
  type        = number
  default     = 8080
}

variable "target_group_arn" {
  description = "Target Group ARN where the ASG will register EC2 instances."
  type        = string
}

variable "min_size" {
  description = "Minimum number of instances in the Auto Scaling Group."
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in the Auto Scaling Group."
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "Desired number of instances in the Auto Scaling Group."
  type        = number
  default     = 1
}