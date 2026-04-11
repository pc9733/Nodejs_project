#!/bin/bash
# =================================================================
# TERRAFORM BACKEND SETUP FOR NEW AWS ACCOUNT
# Creates S3 bucket and DynamoDB table for Terraform state
# =================================================================

set -e

AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_ACCOUNT_ID="602202572057"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}==================================================================${NC}"
echo -e "${GREEN}Terraform Backend Setup for New AWS Account${NC}"
echo -e "${GREEN}Account ID: ${AWS_ACCOUNT_ID}${NC}"
echo -e "${GREEN}Region: ${AWS_REGION}${NC}"
echo -e "${GREEN}==================================================================${NC}"
echo ""

# Verify AWS credentials
echo "Verifying AWS credentials..."
CURRENT_ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "ERROR")

if [ "$CURRENT_ACCOUNT" == "ERROR" ]; then
    echo -e "${RED}❌ AWS credentials not configured or invalid${NC}"
    echo "Please run: aws configure"
    exit 1
fi

echo -e "${GREEN}✅ Connected to AWS Account: ${CURRENT_ACCOUNT}${NC}"

if [ "$CURRENT_ACCOUNT" != "$AWS_ACCOUNT_ID" ]; then
    echo -e "${YELLOW}⚠️  Warning: Expected account ${AWS_ACCOUNT_ID}, but connected to ${CURRENT_ACCOUNT}${NC}"
    read -p "Continue anyway? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        exit 1
    fi
fi

echo ""

# Function to create S3 bucket and DynamoDB table
setup_backend() {
    local ENV=$1
    local BUCKET_NAME="practice-node-app-terraform-state-${AWS_ACCOUNT_ID}-${ENV}"
    local DYNAMODB_TABLE="practice-node-app-terraform-locks-${AWS_ACCOUNT_ID}-${ENV}"

    echo -e "${GREEN}Setting up backend for ${ENV} environment...${NC}"

    # Create S3 bucket
    if aws s3 ls "s3://${BUCKET_NAME}" 2>/dev/null; then
        echo -e "${YELLOW}⚠️  S3 bucket ${BUCKET_NAME} already exists${NC}"
    else
        echo "Creating S3 bucket: ${BUCKET_NAME}"
        # us-east-1 doesn't accept LocationConstraint parameter
        if [ "${AWS_REGION}" == "us-east-1" ]; then
            aws s3api create-bucket \
                --bucket "${BUCKET_NAME}" \
                --region "${AWS_REGION}"
        else
            aws s3api create-bucket \
                --bucket "${BUCKET_NAME}" \
                --region "${AWS_REGION}" \
                --create-bucket-configuration LocationConstraint="${AWS_REGION}"
        fi

        # Enable versioning
        aws s3api put-bucket-versioning \
            --bucket "${BUCKET_NAME}" \
            --versioning-configuration Status=Enabled

        # Enable encryption
        aws s3api put-bucket-encryption \
            --bucket "${BUCKET_NAME}" \
            --server-side-encryption-configuration '{
                "Rules": [{
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }]
            }'

        # Block public access
        aws s3api put-public-access-block \
            --bucket "${BUCKET_NAME}" \
            --public-access-block-configuration \
            "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

        echo -e "${GREEN}✅ S3 bucket created: ${BUCKET_NAME}${NC}"
    fi

    # Create DynamoDB table
    if aws dynamodb describe-table --table-name "${DYNAMODB_TABLE}" --region "${AWS_REGION}" >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  DynamoDB table ${DYNAMODB_TABLE} already exists${NC}"
    else
        echo "Creating DynamoDB table: ${DYNAMODB_TABLE}"
        aws dynamodb create-table \
            --table-name "${DYNAMODB_TABLE}" \
            --attribute-definitions AttributeName=LockID,AttributeType=S \
            --key-schema AttributeName=LockID,KeyType=HASH \
            --billing-mode PAY_PER_REQUEST \
            --region "${AWS_REGION}" \
            >/dev/null

        echo -e "${GREEN}✅ DynamoDB table created: ${DYNAMODB_TABLE}${NC}"
    fi

    echo ""
}

# Setup for development
setup_backend "dev"

# Setup for production
setup_backend "prod"

echo -e "${GREEN}==================================================================${NC}"
echo -e "${GREEN}✅ Terraform backend setup completed!${NC}"
echo -e "${GREEN}==================================================================${NC}"
echo ""
echo "Next steps:"
echo "1. Uncomment the backend configuration in:"
echo "   - infra/environments/dev/main.tf"
echo "   - infra/environments/prod/main.tf"
echo ""
echo "2. Re-initialize Terraform:"
echo "   cd infra/environments/dev && terraform init"
echo "   cd infra/environments/prod && terraform init"
echo ""
echo "Backend resources created:"
echo "  Dev:"
echo "    - S3 Bucket: practice-node-app-terraform-state-${AWS_ACCOUNT_ID}-dev"
echo "    - DynamoDB: practice-node-app-terraform-locks-${AWS_ACCOUNT_ID}-dev"
echo "  Prod:"
echo "    - S3 Bucket: practice-node-app-terraform-state-${AWS_ACCOUNT_ID}-prod"
echo "    - DynamoDB: practice-node-app-terraform-locks-${AWS_ACCOUNT_ID}-prod"
