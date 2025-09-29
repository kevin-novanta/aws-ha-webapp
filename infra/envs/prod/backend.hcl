bucket         = "aws_s3_bucket.tfstate.bucket"
key            = "aws-ha-webapp/prod/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "aws_dynamodb_table.tf_locks.name"
encrypt        = true