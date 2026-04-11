# Fresh AWS Account Setup Guide

This guide walks you through setting up the entire infrastructure from scratch in your new AWS account (602202572057).

## Prerequisites

- AWS Account ID: `602202572057`
- AWS IAM user with Administrator access
- AWS CLI installed
- Terraform installed (v1.0+)
- kubectl installed
- Docker installed (for building images)

---

## Phase 1: AWS Credentials Setup

### Step 1: Configure AWS CLI

```bash
# Configure AWS credentials
aws configure
```

Enter:
- **AWS Access Key ID**: `[Your access key]`
- **AWS Secret Access Key**: `[Your secret key]`
- **Default region name**: `us-east-1`
- **Default output format**: `json`

### Step 2: Verify Connection

```bash
# Verify you're connected to the correct account
aws sts get-caller-identity

# Expected output:
# {
#     "UserId": "AIDAXXXXXXXXXXXXXXXXX",
#     "Account": "602202572057",
#     "Arn": "arn:aws:iam::602202572057:user/your-username"
# }
```

✅ **Checkpoint**: Account ID should be `602202572057`

---

## Phase 2: Terraform Backend Setup

### Step 1: Create S3 Buckets and DynamoDB Tables

```bash
# Make script executable
chmod +x scripts/setup-terraform-backend.sh

# Run the script
./scripts/setup-terraform-backend.sh
```

This creates:
- `practice-node-app-terraform-state-dev` (S3 bucket)
- `practice-node-app-terraform-state-prod` (S3 bucket)
- `practice-node-app-terraform-locks-dev` (DynamoDB table)
- `practice-node-app-terraform-locks-prod` (DynamoDB table)

### Step 2: Verify Backend Resources

```bash
# Check S3 buckets
aws s3 ls | grep practice-node-app

# Check DynamoDB tables
aws dynamodb list-tables --region us-east-1 | grep practice-node-app
```

### Step 3: Enable Terraform Backend

Edit these files and **uncomment** the backend configuration:

**File**: `infra/environments/dev/main.tf`
```terraform
# Change from:
  # backend "s3" {
  #   bucket         = "practice-node-app-terraform-state-dev"
  #   ...
  # }

# To:
  backend "s3" {
    bucket         = "practice-node-app-terraform-state-dev"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "practice-node-app-terraform-locks-dev"
  }
```

**File**: `infra/environments/prod/main.tf`
```terraform
  backend "s3" {
    bucket         = "practice-node-app-terraform-state-prod"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "practice-node-app-terraform-locks-prod"
  }
```

✅ **Checkpoint**: Backend resources created and configured

---

## Phase 3: Deploy Infrastructure with Terraform

### Step 1: Initialize Development Environment

```bash
cd infra/environments/dev

# Initialize Terraform
terraform init

# Review what will be created
terraform plan
```

### Step 2: Apply Development Infrastructure

```bash
# Create all infrastructure
terraform apply

# Type 'yes' when prompted
```

This creates (takes ~15-20 minutes):
- VPC with public/private subnets
- Internet Gateway and NAT Gateway
- EKS cluster (practice-node-app-dev)
- EKS node group
- ECR repository (practice-node-app-dev)
- External Secrets Operator (via Helm)
- IAM roles and policies
- KMS keys for encryption

### Step 3: Verify Infrastructure

```bash
# Check EKS cluster
aws eks list-clusters --region us-east-1

# Check ECR repositories
aws ecr describe-repositories --region us-east-1

# Get cluster details
aws eks describe-cluster --name practice-node-app-dev --region us-east-1
```

✅ **Checkpoint**: EKS cluster and ECR repository created

---

## Phase 4: Configure kubectl

### Step 1: Update kubeconfig

```bash
# Configure kubectl to use the new EKS cluster
aws eks update-kubeconfig --name practice-node-app-dev --region us-east-1
```

### Step 2: Verify Cluster Access

```bash
# Check nodes
kubectl get nodes

# Check External Secrets Operator
kubectl get pods -n external-secrets

# Expected output: external-secrets pods running
```

✅ **Checkpoint**: kubectl connected to EKS cluster

---

## Phase 5: Setup Parameter Store Secrets

### Step 1: Create Development Secrets

```bash
# Make script executable
chmod +x scripts/create-dev-params-quick.sh

# Run the script (creates default values)
./scripts/create-dev-params-quick.sh
```

This creates:
- `/practice-node-app-dev/dev/db-password`
- `/practice-node-app-dev/dev/api-key`
- `/practice-node-app-dev/dev/jwt-secret`

### Step 2: Verify Parameters

```bash
# List all dev parameters
aws ssm get-parameters-by-path \
  --path "/practice-node-app-dev/dev" \
  --region us-east-1

# Get a specific parameter (decrypted)
aws ssm get-parameter \
  --name "/practice-node-app-dev/dev/db-password" \
  --with-decryption \
  --region us-east-1
```

### Step 3: Update Secrets (Optional)

If you want to change the default placeholder values:

```bash
# Update DB password
aws ssm put-parameter \
  --name "/practice-node-app-dev/dev/db-password" \
  --value "your-real-password" \
  --type "SecureString" \
  --overwrite \
  --region us-east-1

# Update API key
aws ssm put-parameter \
  --name "/practice-node-app-dev/dev/api-key" \
  --value "your-real-api-key" \
  --type "SecureString" \
  --overwrite \
  --region us-east-1
```

✅ **Checkpoint**: Secrets stored in Parameter Store

---

## Phase 6: Deploy External Secrets Configuration

### Step 1: Deploy SecretStore Resources

```bash
# Deploy External Secrets configuration
kubectl apply -f k8s/addons/external-secrets-config.yaml
```

### Step 2: Verify SecretStores

```bash
# Check SecretStores in all namespaces
kubectl get secretstores -A

# Expected output:
# NAMESPACE          NAME                       AGE   STATUS   READY
# practice-app-dev   aws-parameter-store-dev    5s    Valid    True
# datadog            aws-parameter-store-datadog 5s   Valid    True
```

✅ **Checkpoint**: SecretStores configured

---

## Phase 7: Build and Push Docker Image

### Step 1: Login to ECR

```bash
# Get ECR login credentials
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  602202572057.dkr.ecr.us-east-1.amazonaws.com
```

### Step 2: Build Docker Image

```bash
# Navigate to application directory
cd node-app

# Build the image
docker build -t practice-node-app-dev .
```

### Step 3: Tag and Push

```bash
# Tag the image
docker tag practice-node-app-dev:latest \
  602202572057.dkr.ecr.us-east-1.amazonaws.com/practice-node-app-dev:latest

# Push to ECR
docker push 602202572057.dkr.ecr.us-east-1.amazonaws.com/practice-node-app-dev:latest
```

### Step 4: Verify Image in ECR

```bash
# List images in repository
aws ecr list-images \
  --repository-name practice-node-app-dev \
  --region us-east-1
```

✅ **Checkpoint**: Docker image in ECR

---

## Phase 8: Deploy Application to Kubernetes

### Step 1: Deploy Development Application

```bash
# Deploy all development resources
kubectl apply -f k8s/environments/dev/all-in-one.yaml
```

This creates:
- Namespace: `practice-app-dev`
- ServiceAccount for External Secrets
- ExternalSecret (syncs from Parameter Store)
- Deployment (2 replicas)
- Service (ClusterIP)
- ConfigMap
- Ingress

### Step 2: Verify ExternalSecrets Sync

```bash
# Check ExternalSecrets
kubectl get externalsecrets -n practice-app-dev

# Check if Kubernetes secret was created
kubectl get secret practice-app-secrets-dev -n practice-app-dev

# Describe ExternalSecret for details
kubectl describe externalsecret practice-app-secrets-dev -n practice-app-dev
```

### Step 3: Verify Application Deployment

```bash
# Check pods
kubectl get pods -n practice-app-dev

# Check if pods are running
kubectl wait --for=condition=ready pod \
  -l app=practice-node-app-dev \
  -n practice-app-dev \
  --timeout=300s

# Check logs
kubectl logs -f deployment/practice-node-app-dev -n practice-app-dev
```

### Step 4: Test Application

```bash
# Port forward to test locally
kubectl port-forward -n practice-app-dev \
  svc/practice-node-app-dev 8080:80

# In another terminal, test the endpoint
curl http://localhost:8080/health
```

✅ **Checkpoint**: Application running in Kubernetes

---

## Phase 9: Setup Datadog (Optional)

If you want to enable Datadog monitoring:

### Step 1: Create Datadog Parameters

```bash
# Create Datadog API key parameter
aws ssm put-parameter \
  --name "/practice-node-app-dev/dev/datadog-api-key" \
  --value "your-datadog-api-key" \
  --type "SecureString" \
  --region us-east-1

# Create Datadog App key parameter
aws ssm put-parameter \
  --name "/practice-node-app-dev/dev/datadog-app-key" \
  --value "your-datadog-app-key" \
  --type "SecureString" \
  --region us-east-1
```

### Step 2: Verify Datadog Secret Sync

```bash
# Check if Datadog secret was created
kubectl get secret datadog-secret -n datadog

# Restart Datadog agent if needed
kubectl rollout restart daemonset/datadog -n datadog
```

---

## Phase 10: Setup Production Environment (Optional)

Follow similar steps for production:

### Step 1: Create Production Infrastructure

```bash
cd infra/environments/prod

terraform init
terraform plan
terraform apply
```

### Step 2: Create Production Secrets

```bash
chmod +x scripts/create-prod-params-quick.sh
./scripts/create-prod-params-quick.sh

# Update with real production secrets
aws ssm put-parameter \
  --name "/practice-node-app-prod/prod/db-password" \
  --value "STRONG-PRODUCTION-PASSWORD" \
  --type "SecureString" \
  --overwrite \
  --region us-east-1
```

### Step 3: Deploy Production Application

```bash
# Configure kubectl for prod cluster
aws eks update-kubeconfig --name practice-node-app-prod --region us-east-1

# Deploy
kubectl apply -f k8s/addons/external-secrets-config.yaml
kubectl apply -f k8s/environments/prod/all-in-one.yaml
```

---

## Troubleshooting

### Issue: Terraform fails with "InvalidClientTokenId"

**Solution**: Verify AWS credentials are configured correctly
```bash
aws configure list
aws sts get-caller-identity
```

### Issue: External Secrets not syncing

**Solution**: Check IAM role and ServiceAccount
```bash
# Check ServiceAccount annotation
kubectl get sa external-secrets -n practice-app-dev -o yaml | grep role-arn

# Check ExternalSecret status
kubectl describe externalsecret practice-app-secrets-dev -n practice-app-dev

# Check External Secrets Operator logs
kubectl logs -n external-secrets deployment/external-secrets
```

### Issue: Pods in ImagePullBackOff

**Solution**: Verify ECR image exists and is accessible
```bash
# Check if image exists
aws ecr describe-images \
  --repository-name practice-node-app-dev \
  --region us-east-1

# Check node IAM role has ECR permissions
kubectl describe pod <pod-name> -n practice-app-dev
```

### Issue: Parameters don't exist in Parameter Store

**Solution**: Create them manually
```bash
aws ssm put-parameter \
  --name "/practice-node-app-dev/dev/db-password" \
  --value "your-password" \
  --type "SecureString" \
  --region us-east-1
```

---

## Verification Checklist

Use this to verify everything is set up correctly:

- [ ] AWS credentials configured (`aws sts get-caller-identity` shows account 602202572057)
- [ ] S3 backend buckets created (dev and prod)
- [ ] DynamoDB lock tables created (dev and prod)
- [ ] Terraform backend enabled in main.tf files
- [ ] Dev infrastructure deployed via Terraform
- [ ] EKS cluster accessible via kubectl
- [ ] External Secrets Operator running (`kubectl get pods -n external-secrets`)
- [ ] Parameter Store secrets created
- [ ] SecretStores configured (`kubectl get secretstores -A`)
- [ ] Docker image built and pushed to ECR
- [ ] Application deployed to Kubernetes
- [ ] ExternalSecrets synced (`kubectl get secret practice-app-secrets-dev -n practice-app-dev`)
- [ ] Pods running (`kubectl get pods -n practice-app-dev`)
- [ ] Application health check passing

---

## Next Steps

After setup is complete:

1. **Setup CI/CD**: Configure GitHub Actions workflows with AWS credentials
2. **Setup monitoring**: Complete Datadog integration
3. **Setup DNS**: Point domain to ALB/Ingress
4. **Setup SSL**: Add TLS certificates via cert-manager or ACM
5. **Harden security**: Review IAM policies, network policies, pod security policies
6. **Backup**: Enable automated backups for critical data

---

## Quick Reference

### Important AWS Resources

```
Account ID: 602202572057
Region: us-east-1

Development:
- EKS Cluster: practice-node-app-dev
- ECR Repo: practice-node-app-dev
- S3 State: practice-node-app-terraform-state-dev
- DynamoDB Locks: practice-node-app-terraform-locks-dev

Production:
- EKS Cluster: practice-node-app-prod
- ECR Repo: practice-node-app-prod
- S3 State: practice-node-app-terraform-state-prod
- DynamoDB Locks: practice-node-app-terraform-locks-prod
```

### Useful Commands

```bash
# Switch kubectl context
aws eks update-kubeconfig --name practice-node-app-dev --region us-east-1

# View all resources
kubectl get all -A

# Get External Secrets status
kubectl get externalsecrets -A

# View Parameter Store secrets
aws ssm get-parameters-by-path --path "/practice-node-app-dev/dev" --region us-east-1

# Terraform state
cd infra/environments/dev && terraform state list
```

---

## Support

For issues, refer to:
- [PARAMETER_STORE_SETUP.md](PARAMETER_STORE_SETUP.md) - Parameter Store details
- [GETTING_STARTED.md](GETTING_STARTED.md) - General setup guide
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues

**Estimated total setup time**: 30-45 minutes
