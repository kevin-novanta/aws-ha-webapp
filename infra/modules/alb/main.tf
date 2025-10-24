

############################################
# aws-ha-webapp — ALB Module
############################################

# Application Load Balancer across public subnets
resource "aws_lb" "this" {
  name               = "aws-ha-webapp-alb"
  load_balancer_type = "application"

  security_groups = [var.alb_sg_id]
  subnets         = var.public_subnet_ids

  idle_timeout = 60

  tags = merge(var.tags, {
    Name    = "aws-ha-webapp-alb"
    Project = var.project_name
    Tier    = "edge"
  })
}

# Target Group for EC2 instances (ASG will register instances)
resource "aws_lb_target_group" "app" {
  name        = "aws-ha-webapp-tg"
  port        = var.target_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 10
    matcher             = "200-399"
  }

  tags = merge(var.tags, {
    Name    = "aws-ha-webapp-tg"
    Project = var.project_name
  })
}

# Listener on port 80
# If an ACM cert is provided, redirect HTTP -> HTTPS.
# If no ACM cert, forward HTTP directly to the target group.
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  dynamic "default_action" {
    for_each = var.acm_cert_arn != "" ? [1] : []
    content {
      type = "redirect"
      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = var.acm_cert_arn == "" ? [1] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.app.arn
    }
  }
}

# Conditional HTTPS listener on 443 (only if acm_cert_arn is set)
resource "aws_lb_listener" "https" {
  count = var.acm_cert_arn != "" ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_cert_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

