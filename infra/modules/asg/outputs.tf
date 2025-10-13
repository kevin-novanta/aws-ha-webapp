

# Echo key inputs for visibility/debugging
output "private_app_subnet_ids" {
  description = "Private app subnet IDs used by the ASG"
  value       = var.private_app_subnet_ids
}

output "ecr_repo_uri" {
  description = "ECR repository URI the Launch Template pulls from"
  value       = var.ecr_repo_uri
}

output "image_tag" {
  description = "Docker image tag deployed by the ASG"
  value       = var.image_tag
}

output "app_sg_id" {
  description = "Security Group ID attached to app instances"
  value       = var.app_sg_id
}

output "instance_profile_name" {
  description = "IAM instance profile name attached to app instances"
  value       = var.instance_profile_name
}

# Core identifiers produced by this module
output "asg_name" {
  description = "Auto Scaling Group name for the application tier"
  value       = aws_autoscaling_group.app.name
}

output "launch_template_id" {
  description = "Launch Template ID used by the ASG"
  value       = aws_launch_template.app.id
}