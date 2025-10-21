############################################
# aws-ha-webapp — env: prod (orchestration)
############################################

# ---- Locals ----
locals {
  project_name = "aws-ha-webapp"
}

# ---- VPC & Networking ----
module "vpc" {
  source = "../../modules/vpc"

  project_name        = local.project_name
  vpc_cidr            = var.vpc_cidr
  azs                 = var.azs
  public_subnets      = var.public_subnet_cidrs
  private_app_subnets = var.app_subnet_cidrs
  private_db_subnets  = var.db_subnet_cidrs
}

# ---- Security (SGs/NACLs) ----
module "security" {
  source = "../../modules/security"

  vpc_id = module.vpc.vpc_id
  # Optionally restrict ALB ingress with allowed CIDRs if your module supports it
  # allowed_cidrs_for_alb = var.allowed_cidrs
  # app_port              = 8080
  # db_port               = 5432
}

# ---- IAM (SSM, ECR pull, CI roles) ----
module "iam" {
  source = "../../modules/iam"
  # Provide any OIDC inputs here if required by the module
}

# ---- ECR (app image repo) ----
module "ecr" {
  source = "../../modules/ecr"
  # repository_name = "${local.project_name}-app"
}

# ---- ALB (public) ----
module "alb" {
  source = "../../modules/alb"

  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.security.alb_sg_id

  # For now, we’re using Option A (HTTP-only) → pass empty ARN (set via tfvars)
  acm_cert_arn = var.acm_arn

  # health_check_path = "/health"
}

# ---- ASG (private app) ----
module "asg" {
  source = "../../modules/asg"

  vpc_id                 = module.vpc.vpc_id
  private_app_subnet_ids = module.vpc.private_app_subnet_ids
  app_sg_id              = module.security.app_sg_id

  instance_type = var.instance_type
  ecr_repo_uri  = module.ecr.repository_url
  image_tag     = var.image_tag

  target_group_arn = module.alb.target_group_arn
}

# ---- RDS (private db) ----
module "rds" {
  source = "../../modules/rds"

  vpc_id                = module.vpc.vpc_id
  private_db_subnet_ids = module.vpc.private_db_subnet_ids

  db_sg_source_sg_id = module.security.app_sg_id
  instance_class     = var.db_instance_class

  # Recommended prod toggles if your module supports them
  # multi_az             = var.multi_az
  # deletion_protection  = true
  # backup_retention_days = 7
}

# ---- Observability (alarms/dashboards) ----
module "observability" {
  source = "../../modules/observability"

  enable_alarms = var.enable_alarms

  alb_arn  = try(module.alb.alb_arn, null)
  tg_arn   = try(module.alb.target_group_arn, null)
  asg_name = try(module.asg.asg_name, null)
  rds_arn  = try(module.rds.db_arn, null)
}

# ---- VPC Endpoints (optional hardening) ----
module "endpoints" {
  source = "../../modules/endpoints"

  enable_endpoints = var.enable_endpoints
  vpc_id           = module.vpc.vpc_id
  subnet_ids       = module.vpc.private_app_subnet_ids
  # endpoint_sg_id   = module.security.app_sg_id
}

# ---- Useful outputs for this env ----
output "alb_dns" {
  description = "DNS name of the Application Load Balancer."
  value       = try(module.alb.alb_dns_name, null)
}

output "target_group_arn" {
  value       = try(module.alb.target_group_arn, null)
  description = "Target Group ARN for the app service."
}

output "asg_name" {
  value       = try(module.asg.asg_name, null)
  description = "Auto Scaling Group name for the app tier."
}

output "rds_endpoint" {
  value       = try(module.rds.db_endpoint, null)
  description = "RDS database endpoint."
}

# Re-export helpful IDs from modules so `terraform output` can read them
output "vpc_id" {
  description = "VPC ID for this environment"
  value       = module.vpc.vpc_id
}

# (optional but handy)
output "public_subnet_ids"       { value = module.vpc.public_subnet_ids }
output "private_app_subnet_ids"  { value = module.vpc.private_app_subnet_ids }
output "private_db_subnet_ids"   { value = module.vpc.private_db_subnet_ids }
