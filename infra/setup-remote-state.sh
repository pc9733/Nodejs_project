#!/bin/bash

# Setup remote state backend to prevent state loss
echo "Setting up remote state backend..."

# Create S3 bucket for state
aws s3 mb s3://practice-node-app-terraform-state --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning --bucket practice-node-app-terraform-state --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
    --table-name terraform-state-lock \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region us-east-1

echo "Remote state backend configured!"
echo "Run 'terraform init' to migrate state to remote backend."
