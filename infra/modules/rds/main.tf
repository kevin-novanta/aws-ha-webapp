############################################
# aws-ha-webapp — RDS Module
# Purpose: Private, HA-ready relational database with secrets management
############################################

# ---- Subnet Group (private DB subnets) ----
resource "aws_db_subnet_group" "this" {
  name       = "${var.project_name}-db-subnets"
  subnet_ids = var.private_db_subnet_ids

  tags = merge(var.tags, {
    Name    = "${var.project_name}-db-subnets"
    Project = var.project_name
    Tier    = "db"
  })
}

# ---- Security Group (allow from app tier only) ----

variable "db_security_group_id" { type = string }

# ---- Secrets Manager: store DB credentials ----
resource "random_password" "db" {
  length           = 20
  special          = true
  override_special = "!@#%^*()-_+="
}

resource "aws_secretsmanager_secret" "db" {
  name = coalesce(var.secret_name, "${var.project_name}/db-credentials")
  tags = merge(var.tags, { Project = var.project_name })
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.master_username,
    password = random_password.db.result,
    engine   = var.engine,
    dbname   = var.db_name
  })
}

# ---- RDS Instance ----
resource "aws_db_instance" "this" {
  vpc_security_group_ids = [var.db_security_group_id]
  identifier             = "${var.project_name}-db"
  engine                 = var.engine
  instance_class         = var.instance_class

  db_subnet_group_name = aws_db_subnet_group.this.name
  publicly_accessible  = false

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.master_username
  password = random_password.db.result

  multi_az                = var.multi_az
  backup_retention_period = var.backup_retention_days
  deletion_protection     = var.deletion_protection
  skip_final_snapshot     = var.skip_final_snapshot
  apply_immediately       = true

  # Parameter group and maintenance window can be added as needed

  tags = merge(var.tags, {
    Name    = "${var.project_name}-db"
    Project = var.project_name
    Tier    = "db"
  })
}
