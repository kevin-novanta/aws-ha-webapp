

variable "project_name" {
  description = "Project name used for tagging and naming IAM resources."
  type        = string
  default     = "aws-ha-webapp"
}

variable "tags" {
  description = "Common tags to apply to IAM resources."
  type        = map(string)
  default     = {}
}

# --------------------------
# GitHub OIDC configuration
# --------------------------
variable "github_org" {
  description = "GitHub organization or user that owns the repository (e.g., kevinnovanta)."
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (without org)."
  type        = string
}

variable "github_oidc_audience" {
  description = "Expected audience for GitHub OIDC tokens."
  type        = string
  default     = "sts.amazonaws.com"
}

variable "github_ref" {
  description = "Optional ref to scope trust policy (e.g., refs/heads/main). If null, allows any ref in the repo."
  type        = string
  default     = null
}

# --------------------------
# CI role names and boundaries
# --------------------------
variable "terraform_role_name" {
  description = "Name of the IAM role assumed by Terraform pipelines via OIDC."
  type        = string
  default     = "aws-ha-webapp-ci-terraform-role"
}

variable "ecr_push_role_name" {
  description = "Name of the IAM role assumed by App CI to push images to ECR."
  type        = string
  default     = "aws-ha-webapp-ci-ecr-push-role"
}

variable "permissions_boundary_arn" {
  description = "Optional IAM permissions boundary ARN to attach to created roles."
  type        = string
  default     = null
}

# --------------------------
# Policy scoping knobs
# --------------------------
variable "ecr_repository_arn" {
  description = "Optional ECR repository ARN to scope ECR push/pull policies. If null, policies allow all repositories (demo-friendly)."
  type        = string
  default     = null
}

variable "grant_admin_to_terraform" {
  description = "If true, attach AdministratorAccess to the Terraform CI role (easy demo). Set false to attach a custom least-privilege policy instead."
  type        = bool
  default     = true
}