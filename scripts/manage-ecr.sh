#!/bin/bash
# =================================================================
# ECR REPOSITORY MANAGEMENT SCRIPT
# Manages ECR repository outside of Terraform
# =================================================================

set -e

AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_ACCOUNT_ID="602202572057"
REPO_NAME="practice-node-app-dev"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}==================================================================${NC}"
echo -e "${GREEN}ECR Repository Management${NC}"
echo -e "${GREEN}Account: ${AWS_ACCOUNT_ID}${NC}"
echo -e "${GREEN}Region: ${AWS_REGION}${NC}"
echo -e "${GREEN}Repository: ${REPO_NAME}${NC}"
echo -e "${GREEN}==================================================================${NC}"
echo ""

# Function to create ECR repository
create_repository() {
    echo -e "${GREEN}Creating ECR repository: ${REPO_NAME}${NC}"
    
    if aws ecr describe-repositories --repository-names "${REPO_NAME}" --region "${AWS_REGION}" >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Repository ${REPO_NAME} already exists${NC}"
    else
        aws ecr create-repository \
            --repository-name "${REPO_NAME}" \
            --region "${AWS_REGION}" \
            --image-scanning-configuration scanOnPush=true \
            --image-tag-mutability MUTABLE \
            --encryption-type AES256
        
        echo -e "${GREEN}✅ ECR repository created: ${REPO_NAME}${NC}"
    fi
}

# Function to delete ECR repository (force)
delete_repository() {
    echo -e "${YELLOW}Force deleting ECR repository: ${REPO_NAME}${NC}"
    
    # Delete all images first
    echo "Deleting all images..."
    aws ecr batch-delete-image \
        --repository-name "${REPO_NAME}" \
        --region "${AWS_REGION}" \
        --image-ids "$(aws ecr list-images --repository-name "${REPO_NAME}" --region "${AWS_REGION}" --query 'imageIds[].imageDigest' --output text)" \
        --force || true
    
    # Delete repository
    aws ecr delete-repository \
        --repository-name "${REPO_NAME}" \
        --region "${AWS_REGION}" \
        --force
    
    echo -e "${GREEN}✅ ECR repository deleted: ${REPO_NAME}${NC}"
}

# Function to get repository URI
get_repository_uri() {
    aws ecr describe-repositories \
        --repository-names "${REPO_NAME}" \
        --region "${AWS_REGION}" \
        --query 'repositories[0].repositoryUri' \
        --output text
}

# Function to login to ECR
login() {
    echo -e "${GREEN}Logging into ECR...${NC}"
    aws ecr get-login-password --region "${AWS_REGION}" | docker login --username AWS --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
}

# Function to build and push image
build_and_push() {
    local IMAGE_TAG="${1:-latest}"
    echo -e "${GREEN}Building and pushing image: ${IMAGE_TAG}${NC}"
    
    # Build image
    docker build -t "${REPO_NAME}:${IMAGE_TAG}" ./node-app/
    
    # Tag for ECR
    docker tag "${REPO_NAME}:${IMAGE_TAG}" "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG}"
    
    # Push to ECR
    docker push "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG}"
    
    echo -e "${GREEN}✅ Image pushed: ${REPO_NAME}:${IMAGE_TAG}${NC}"
}

# Main menu
case "${1}" in
    "create")
        create_repository
        ;;
    "delete")
        delete_repository
        ;;
    "login")
        login
        ;;
    "push")
        build_and_push "${2}"
        ;;
    "uri")
        get_repository_uri
        ;;
    *)
        echo "Usage: $0 {create|delete|login|push|uri} [tag]"
        echo ""
        echo "Commands:"
        echo "  create   - Create ECR repository"
        echo "  delete   - Force delete ECR repository and all images"
        echo "  login    - Login to ECR"
        echo "  push     - Build and push image (optional tag)"
        echo "  uri      - Get repository URI"
        echo ""
        echo "Examples:"
        echo "  $0 create"
        echo "  $0 delete"
        echo "  $0 login"
        echo "  $0 push latest"
        echo "  $0 push v1.0.0"
        echo "  $0 uri"
        exit 1
        ;;
esac
