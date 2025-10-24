############################################
# aws-ha-webapp — ASG Module
# Purpose: Launch Template + ASG in private app subnets and register with ALB TG
############################################

# ---- AMI (Amazon Linux 2023 via SSM Parameter) ----
# Keeps image fresh without hardcoding AMI IDs per region
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-6.1-x86_64"
}

# ---- Launch Template ----
resource "aws_launch_template" "app" {
  name_prefix   = "aws-ha-webapp-lt-"
  image_id      = data.aws_ssm_parameter.al2023_ami.value
  instance_type = var.instance_type

  iam_instance_profile {
    name = var.instance_profile_name
  }

  # App runs in private subnets — no public IPs
  network_interfaces {
    security_groups             = [var.app_sg_id]
    associate_public_ip_address = false
  }

  user_data = base64encode(
    templatefile("${path.module}/user_data.tpl", {
      ECR_REPO_URI = var.ecr_repo_uri
      IMAGE_TAG    = var.image_tag
      APP_PORT     = tostring(var.app_port)
      REGION       = var.region
    })
  )

  # Propagate useful tags to instances/volumes
  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name      = "aws-ha-webapp-ec2"
      Project   = var.project_name
      Tier      = "app"
      ManagedBy = "terraform"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(var.tags, {
      Project   = var.project_name
      ManagedBy = "terraform"
    })
  }
}

# ---- Auto Scaling Group ----
resource "aws_autoscaling_group" "app" {
  name                      = "aws-ha-webapp-asg"
  vpc_zone_identifier       = var.private_app_subnet_ids
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  health_check_type         = "ELB"
  health_check_grace_period = 120
  target_group_arns         = [var.target_group_arn]
  capacity_rebalance        = true

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }

  tag {
    key                 = "Tier"
    value               = "app"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}