

output "alb_sg_id" {
  description = "Security Group ID for the Application Load Balancer"
  value       = aws_security_group.alb.id
}

output "app_sg_id" {
  description = "Security Group ID for the application (EC2/ASG) tier"
  value       = aws_security_group.app.id
}

output "db_sg_id" {
  description = "Security Group ID for the database tier"
  value       = aws_security_group.db.id
}