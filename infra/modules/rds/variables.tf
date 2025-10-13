

variable "project_name" {
  description = "Project name used for tagging and naming RDS resources."
  type        = string
}

variable "tags" {
  description = "Common tags applied to RDS and related resources."
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "VPC ID where the RDS instance will reside."
  type        = string
}

variable "private_db_subnet_ids" {
  description = "List of private subnet IDs for RDS subnet group."
  type        = list(string)
}

variable "db_sg_source_sg_id" {
  description = "Security group ID from the application tier allowed to access the DB."
  type        = string
}

variable "db_port" {
  description = "Database port (5432 for Postgres, 3306 for MySQL)."
  type        = number
  default     = 5432
}

variable "engine" {
  description = "Database engine (e.g., postgres, mysql)."
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "Engine version to use for the DB instance."
  type        = string
  default     = "15.3"
}

variable "instance_class" {
  description = "RDS instance class (e.g., db.t3.micro)."
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Initial allocated storage in GB."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum storage in GB for autoscaling."
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Name of the initial database to create."
  type        = string
  default     = "appdb"
}

variable "master_username" {
  description = "Master username for the database."
  type        = string
  default     = "admin"
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment for high availability."
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Number of days to retain backups. Set to >0 in non-dev environments."
  type        = number
  default     = 1
}

variable "deletion_protection" {
  description = "Whether to enable deletion protection on the DB instance."
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot before DB deletion (recommended true for dev)."
  type        = bool
  default     = true
}

variable "secret_name" {
  description = "Optional custom name for the Secrets Manager secret storing DB credentials."
  type        = string
  default     = null
}