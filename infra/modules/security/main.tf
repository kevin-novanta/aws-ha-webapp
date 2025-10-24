############################################
# aws-ha-webapp — Security Module
############################################

# ---- ALB Security Group ----
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow inbound HTTP (80) or HTTPS (443) from the internet, egress to app port"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP from anywhere (can be restricted by allowed_cidrs)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidrs
  }

  # Optional: enable HTTPS if desired later (commented out for now)
  # ingress {
  #   description = "Allow HTTPS from anywhere (or restricted CIDRs)"
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = var.allowed_cidrs
  # }

  egress {
    description = "Allow all outbound (no SG reference to avoid cycles)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-alb-sg"
    Tier = "alb"
  })
}

# ---- App Security Group ----
resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg"
  description = "Allow inbound from ALB, egress to internet via NAT or endpoints"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow app traffic from ALB SG"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all outbound (DNS/ECR/SSM, etc.)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-app-sg"
    Tier = "app"
  })
}

# ---- DB Security Group ----
resource "aws_security_group" "db" {
  name        = "${var.project_name}-db-sg"
  description = "Allow inbound DB traffic from app servers only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow PostgreSQL/MySQL traffic from app SG"
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    description = "Allow all egress (usually to internal services)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-db-sg"
    Tier = "db"
  })
}

# (Optional) Example NACL stubs (commented for future hardening)
# resource "aws_network_acl" "private" {
#   vpc_id = var.vpc_id
#   tags = merge(var.tags, { Name = "${var.project_name}-nacl-private" })
# }

resource "aws_security_group" "vpce" {
  name        = "${var.project_name}-vpce"
  description = "Allow app instances to reach interface endpoints on 443"
  vpc_id      = var.vpc_id

  # allow instances in app SG to hit the endpoint ENIs on 443
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id] # or var.app_sg_id if in endpoints module
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}