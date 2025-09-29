bucket         = "aws_s3_bucket.tfstate.bucket"   # from bootstrap output: state_bucket_name
key            = "aws-ha-webapp/staging/terraform.tfstate"
region         = "us-east-1"
dynamodb_table = "aws_dynamodb_table.tf_locks.name"            # from bootstrap output: lock_table_name
encrypt        = true