

output "instance_profile_name" {
  description = "Name of the EC2 instance profile created for app servers"
  value       = aws_iam_instance_profile.ec2_profile.name
}

output "ec2_role_arn" {
  description = "ARN of the EC2 role attached to instance profile"
  value       = aws_iam_role.ec2_role.arn
}

output "ci_terraform_role_arn" {
  description = "ARN of the CI/CD Terraform plan/apply role"
  value       = aws_iam_role.ci_terraform.arn
}

output "ci_ecr_push_role_arn" {
  description = "ARN of the CI/CD role for pushing Docker images to ECR"
  value       = aws_iam_role.ci_ecr_push.arn
}