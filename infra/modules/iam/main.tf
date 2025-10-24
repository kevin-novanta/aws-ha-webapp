

############################################
# aws-ha-webapp — IAM Module
# Purpose:
#  - EC2 role + instance profile with SSM
#  - ECR pull permissions for EC2
#  - GitHub OIDC provider + CI roles (Terraform + ECR push)
############################################

# ----------------------
# EC2 instance role (SSM + ECR pull)
# ----------------------
resource "aws_iam_role" "ec2_role" {
  name = "aws-ha-webapp-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
  tags = { Project = "aws-ha-webapp" }
}

# Attach SSM core managed policy (Session Manager access)
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Inline policy for pulling images from ECR (read-only)
resource "aws_iam_policy" "ecr_pull" {
  name        = "aws-ha-webapp-ecr-pull"
  description = "Allow EC2 instances to authenticate and pull images from ECR"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "Auth",
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken"
        ],
        Resource = "*"
      },
      {
        Sid    = "Pull",
        Effect = "Allow",
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:DescribeImages",
          "ecr:ListImages"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_ecr_pull" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ecr_pull.arn
}

# Instance profile for EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "aws-ha-webapp-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# ----------------------
# GitHub OIDC provider (for GitHub Actions)
# ----------------------
# If you already have this provider in the account, you can import or skip creation.
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = [
    "sts.amazonaws.com"
  ]
  thumbprint_list = [
    # GitHub OIDC root CA thumbprint (current at time of writing)
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
}

# ----------------------
# CI role: Terraform plan/apply (broad perms for demo; tighten in prod)
# ----------------------
resource "aws_iam_role" "ci_terraform" {
  name = "aws-ha-webapp-ci-terraform-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          },
          StringLike = {
            # Lock to your repo later (e.g., "repo:ORG/REPO:ref:refs/heads/main")
            "token.actions.githubusercontent.com:sub" = "repo:*"
          }
        }
      }
    ]
  })
  tags = { Project = "aws-ha-webapp" }
}

# Attach broad admin for demo simplicity (replace with least-privilege in prod)
resource "aws_iam_role_policy_attachment" "ci_terraform_admin" {
  role       = aws_iam_role.ci_terraform.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# ----------------------
# CI role: ECR push (scoped to ECR actions)
# ----------------------
resource "aws_iam_role" "ci_ecr_push" {
  name = "aws-ha-webapp-ci-ecr-push-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          },
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:*"
          }
        }
      }
    ]
  })
  tags = { Project = "aws-ha-webapp" }
}

# Minimal ECR push permissions (wildcarded for demo; scope to your repo ARN later)
resource "aws_iam_policy" "ecr_push" {
  name        = "aws-ha-webapp-ecr-push"
  description = "Allow CI to authenticate and push images to ECR"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "Auth",
        Effect   = "Allow",
        Action   = ["ecr:GetAuthorizationToken"],
        Resource = "*"
      },
      {
        Sid    = "Push",
        Effect = "Allow",
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ci_ecr_push_attach" {
  role       = aws_iam_role.ci_ecr_push.name
  policy_arn = aws_iam_policy.ecr_push.arn
}

