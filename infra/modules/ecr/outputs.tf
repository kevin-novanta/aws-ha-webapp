


output "repository_url" {
  description = "Full ECR repository URL (used by CI/CD pipelines and ASG user data)."
  value       = aws_ecr_repository.app.repository_url
}

output "repository_arn" {
  description = "ARN of the ECR repository."
  value       = aws_ecr_repository.app.arn
}