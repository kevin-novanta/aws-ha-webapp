

############################################
# aws-ha-webapp — ECR Module
############################################

resource "aws_ecr_repository" "app" {
  name                 = var.repository_name
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(var.tags, {
    Name    = var.repository_name
    Project = var.project_name
  })
}

# ---- Lifecycle Policy ----
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1,
        description  = "Expire old images, keep only N most recent",
        selection = {
          tagStatus   = "any",
          countType   = "imageCountMoreThan",
          countNumber = var.retain_images
        },
        action = {
          type = "expire"
        }
      }
    ]
  })
}
