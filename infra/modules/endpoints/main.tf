############################################
# aws-ha-webapp — Endpoints Module
# Purpose: Provide VPC endpoints for AWS services to keep private subnets off 0.0.0.0/0
############################################

# ---- Interface Endpoints (SSM, Secrets Manager) ----
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [var.endpoint_sg_id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name    = "${var.project_name}-vpce-ssm"
    Project = var.project_name
  })
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [var.endpoint_sg_id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name    = "${var.project_name}-vpce-ssmmessages"
    Project = var.project_name
  })
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [var.endpoint_sg_id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name    = "${var.project_name}-vpce-secretsmanager"
    Project = var.project_name
  })
}

# ---- Gateway Endpoint (S3) ----
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.private_route_table_ids

  tags = merge(var.tags, {
    Name    = "${var.project_name}-s3-endpoint"
    Project = var.project_name
  })
}

# ---- Optional: Interface Endpoint (EC2Messages) ----
resource "aws_vpc_endpoint" "ec2messages" {
  count               = var.enable_endpoints ? 1 : 0
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.private_subnet_ids
  security_group_ids  = [var.endpoint_sg_id]
  private_dns_enabled = true

  tags = merge(var.tags, {
    Name    = "${var.project_name}-vpce-ec2messages"
    Project = var.project_name
  })
}

# ---- Outputs ----
output "endpoint_ids" {
  description = "IDs of all created VPC endpoints"
  value = [
    aws_vpc_endpoint.ssm.id,
    aws_vpc_endpoint.ssmmessages.id,
    aws_vpc_endpoint.secretsmanager.id,
    aws_vpc_endpoint.s3.id
  ]
}