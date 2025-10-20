

variable "region" {
  description = "AWS region to deploy resources into."
  type        = string
}

variable "azs" {
  description = "List of availability zones to spread resources across."
  type        = list(string)
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets."
  type        = list(string)
}

variable "app_subnet_cidrs" {
  description = "List of CIDR blocks for private app subnets."
  type        = list(string)
}

variable "db_subnet_cidrs" {
  description = "List of CIDR blocks for private database subnets."
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type for the Auto Scaling Group."
  type        = string
  default     = "t3.micro"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "image_tag" {
  description = "Docker image tag to deploy from ECR."
  type        = string
}

variable "acm_arn" {
  description = "ARN of the ACM certificate for HTTPS on the ALB."
  type        = string
}

variable "enable_alarms" {
  description = "Flag to enable or disable CloudWatch alarms."
  type        = bool
  default     = true
}

variable "enable_endpoints" {
  description = "Flag to enable or disable creation of VPC Endpoints (S3, SSM, Secrets Manager)."
  type        = bool
  default     = false
}

# --- CI / GitHub OIDC inputs for IAM module ---
variable "github_org" {
  description = "GitHub organization or user that owns the repository used by CI"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (without org) that will run CI"
  type        = string
}

variable "oidc_audience" {
  description = "OIDC audience for GitHub → AWS (usually sts.amazonaws.com)"
  type        = string
  default     = "sts.amazonaws.com"
}

variable "project_name" {
  description = "Human-friendly project identifier used in tags and names"
  type        = string
}

variable "multi_az" {
  description = "Whether to enable Multi-AZ for RDS in this environment"
  type        = bool
  default     = false
}

variable "master_username" {
  description = "RDS master username"
  type        = string
  default     = "appadmin" # optional default
}