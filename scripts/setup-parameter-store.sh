#!/bin/bash
# =================================================================
# AWS SYSTEMS MANAGER PARAMETER STORE SETUP SCRIPT
# -----------------------------------------------------------------
# This script creates all required parameters in AWS SSM Parameter Store
# for the practice-node-app project.
# =================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION="${AWS_REGION:-us-east-1}"
CLUSTER_NAME_DEV="practice-node-app-dev"
CLUSTER_NAME_PROD="practice-node-app-prod"

echo -e "${GREEN}==================================================================${NC}"
echo -e "${GREEN}AWS Systems Manager Parameter Store Setup${NC}"
echo -e "${GREEN}==================================================================${NC}"
echo ""

# Function to create parameter
create_parameter() {
    local name=$1
    local value=$2
    local description=$3

    if aws ssm get-parameter --name "$name" --region "$AWS_REGION" >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Parameter $name already exists. Updating...${NC}"
        aws ssm put-parameter \
            --name "$name" \
            --value "$value" \
            --description "$description" \
            --type "SecureString" \
            --overwrite \
            --region "$AWS_REGION" \
            --tier "Standard" >/dev/null
    else
        echo -e "${GREEN}✅ Creating parameter $name${NC}"
        aws ssm put-parameter \
            --name "$name" \
            --value "$value" \
            --description "$description" \
            --type "SecureString" \
            --region "$AWS_REGION" \
            --tier "Standard" >/dev/null
    fi
}

# Prompt for environment
echo "Which environment do you want to setup?"
echo "1) Development (dev)"
echo "2) Production (prod)"
echo "3) Both"
read -p "Enter choice [1-3]: " env_choice

setup_dev() {
    echo -e "\n${GREEN}Setting up Development Environment Parameters...${NC}"

    # Prompt for values
    read -sp "Enter DB_PASSWORD for dev: " DEV_DB_PASSWORD
    echo ""
    read -sp "Enter API_KEY for dev: " DEV_API_KEY
    echo ""
    read -sp "Enter JWT_SECRET for dev: " DEV_JWT_SECRET
    echo ""
    read -sp "Enter DATADOG_API_KEY for dev (or press Enter to skip): " DEV_DATADOG_API_KEY
    echo ""
    read -sp "Enter DATADOG_APP_KEY for dev (or press Enter to skip): " DEV_DATADOG_APP_KEY
    echo ""

    # Create parameters
    create_parameter \
        "/${CLUSTER_NAME_DEV}/dev/db-password" \
        "$DEV_DB_PASSWORD" \
        "Database password for development environment"

    create_parameter \
        "/${CLUSTER_NAME_DEV}/dev/api-key" \
        "$DEV_API_KEY" \
        "API key for development environment"

    create_parameter \
        "/${CLUSTER_NAME_DEV}/dev/jwt-secret" \
        "$DEV_JWT_SECRET" \
        "JWT secret for development environment"

    if [ -n "$DEV_DATADOG_API_KEY" ]; then
        create_parameter \
            "/${CLUSTER_NAME_DEV}/dev/datadog-api-key" \
            "$DEV_DATADOG_API_KEY" \
            "Datadog API key for development"
    fi

    if [ -n "$DEV_DATADOG_APP_KEY" ]; then
        create_parameter \
            "/${CLUSTER_NAME_DEV}/dev/datadog-app-key" \
            "$DEV_DATADOG_APP_KEY" \
            "Datadog application key for development"
    fi

    echo -e "${GREEN}✅ Development parameters created successfully!${NC}"
}

setup_prod() {
    echo -e "\n${GREEN}Setting up Production Environment Parameters...${NC}"

    # Prompt for values
    read -sp "Enter DB_PASSWORD for prod: " PROD_DB_PASSWORD
    echo ""
    read -sp "Enter API_KEY for prod: " PROD_API_KEY
    echo ""
    read -sp "Enter JWT_SECRET for prod: " PROD_JWT_SECRET
    echo ""
    read -sp "Enter DATADOG_API_KEY for prod (or press Enter to skip): " PROD_DATADOG_API_KEY
    echo ""
    read -sp "Enter DATADOG_APP_KEY for prod (or press Enter to skip): " PROD_DATADOG_APP_KEY
    echo ""

    # Create parameters
    create_parameter \
        "/${CLUSTER_NAME_PROD}/prod/db-password" \
        "$PROD_DB_PASSWORD" \
        "Database password for production environment"

    create_parameter \
        "/${CLUSTER_NAME_PROD}/prod/api-key" \
        "$PROD_API_KEY" \
        "API key for production environment"

    create_parameter \
        "/${CLUSTER_NAME_PROD}/prod/jwt-secret" \
        "$PROD_JWT_SECRET" \
        "JWT secret for production environment"

    if [ -n "$PROD_DATADOG_API_KEY" ]; then
        create_parameter \
            "/${CLUSTER_NAME_PROD}/prod/datadog-api-key" \
            "$PROD_DATADOG_API_KEY" \
            "Datadog API key for production"
    fi

    if [ -n "$PROD_DATADOG_APP_KEY" ]; then
        create_parameter \
            "/${CLUSTER_NAME_PROD}/prod/datadog-app-key" \
            "$PROD_DATADOG_APP_KEY" \
            "Datadog application key for production"
    fi

    echo -e "${GREEN}✅ Production parameters created successfully!${NC}"
}

case $env_choice in
    1)
        setup_dev
        ;;
    2)
        setup_prod
        ;;
    3)
        setup_dev
        setup_prod
        ;;
    *)
        echo -e "${RED}Invalid choice. Exiting.${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}==================================================================${NC}"
echo -e "${GREEN}✅ Parameter Store setup completed!${NC}"
echo -e "${GREEN}==================================================================${NC}"
echo ""
echo "To verify, run:"
if [ "$env_choice" == "1" ] || [ "$env_choice" == "3" ]; then
    echo "  aws ssm get-parameters-by-path --path '/${CLUSTER_NAME_DEV}/dev' --region ${AWS_REGION}"
fi
if [ "$env_choice" == "2" ] || [ "$env_choice" == "3" ]; then
    echo "  aws ssm get-parameters-by-path --path '/${CLUSTER_NAME_PROD}/prod' --region ${AWS_REGION}"
fi
