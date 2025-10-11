output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets (one per AZ)"
  value       = values(aws_subnet.public)[*].id
}

output "private_app_subnet_ids" {
  description = "IDs of the private application subnets (one per AZ)"
  value       = values(aws_subnet.private_app)[*].id
}

output "private_db_subnet_ids" {
  description = "IDs of the private database subnets (one per AZ)"
  value       = values(aws_subnet.private_db)[*].id
}

output "public_route_table_id" {
  description = "Route table ID for public subnets"
  value       = aws_route_table.public.id
}

output "private_app_route_table_ids" {
  description = "Route table IDs for private app subnets (mapped 1:1 to AZs)"
  value       = values(aws_route_table.private_app)[*].id
}

output "private_db_route_table_ids" {
  description = "Route table IDs for private DB subnets (mapped 1:1 to AZs)"
  value       = values(aws_route_table.private_db)[*].id
}
