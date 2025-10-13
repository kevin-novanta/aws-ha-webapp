

output "db_endpoint" {
  description = "DNS address clients should use to connect to the database"
  value       = aws_db_instance.this.address
}

output "db_port" {
  description = "Port the database is listening on"
  value       = aws_db_instance.this.port
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret that stores DB credentials"
  value       = aws_secretsmanager_secret.db.arn
}