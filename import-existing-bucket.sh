#!/bin/bash

# Import existing S3 bucket into Terraform state
# This prevents the "BucketAlreadyExists" error

set -e

BUCKET_NAME="xxxxxxx-321312321312-s3"

echo "🔧 Importing existing S3 bucket into Terraform state..."

# Initialize Terraform
terraform init

# Import the existing bucket
terraform import aws_s3_bucket.main_bucket "$BUCKET_NAME"

# Import bucket versioning
terraform import aws_s3_bucket_versioning.main_bucket_versioning "$BUCKET_NAME"

# Import bucket encryption
terraform import aws_s3_bucket_server_side_encryption_configuration.main_bucket_encryption "$BUCKET_NAME"

# Import public access block
terraform import aws_s3_bucket_public_access_block.main_bucket_pab "$BUCKET_NAME"

echo "✅ Import complete! Now Terraform can manage the existing bucket."
echo "🚀 Next: Run 'terraform plan' to see what changes are needed."
