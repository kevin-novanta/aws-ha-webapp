# Terraform State Bootstrap

This module provisions the **remote backend** used by all environments:

- **S3 bucket** for Terraform state (versioned & encrypted)
- **DynamoDB table** for state **locking**

> Run this **once per AWS account/region** before applying any environment in `infra/envs/*`.

## ✅ What it creates

- **S3 bucket** (versioning enabled, server-side encryption on)
  - Stores `terraform.tfstate` for each environment under different keys
- **DynamoDB table** (`LockID` as the partition key)
  - Enforces **state locks** to prevent concurrent writes

## 🔐 IAM prerequisites

The identity running `terraform apply` here needs the ability to create and manage:

- S3 bucket (create, put policy, versioning, encryption)
- DynamoDB table (create, describe, delete)
- (Optional) KMS key if you choose customer-managed encryption

### Minimal policy (inline example)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "S3StateBucketAdmin",
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket",
        "s3:PutBucketVersioning",
        "s3:PutBucketEncryption",
        "s3:PutBucketPolicy",
        "s3:GetBucketLocation",
        "s3:PutBucketTagging",
        "s3:ListBucket",
        "s3:PutLifecycleConfiguration",
        "s3:GetEncryptionConfiguration"
      ],
      "Resource": "arn:aws:s3:::<your-state-bucket-name>"
    },
    {
      "Sid": "S3StateObjects",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:ListBucketMultipartUploads",
        "s3:AbortMultipartUpload"
      ],
      "Resource": "arn:aws:s3:::<your-state-bucket-name>/*"
    },
    {
      "Sid": "DDBTableAdmin",
      "Effect": "Allow",
      "Action": [
        "dynamodb:CreateTable",
        "dynamodb:DescribeTable",
        "dynamodb:DeleteTable",
        "dynamodb:UpdateTable",
        "dynamodb:TagResource",
        "dynamodb:ListTagsOfResource",
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:<region>:<accountId>:table/<your-lock-table-name>"
    }
  ]
}
```
