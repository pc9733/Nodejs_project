# AWS Parameter Store Integration Guide

This document explains how to use AWS Systems Manager Parameter Store for managing secrets in the practice-node-app project.

## Overview

All application secrets are stored in **AWS Systems Manager Parameter Store** and automatically synced to Kubernetes using **External Secrets Operator (ESO)**. This ensures:

- ✅ **No hardcoded secrets** in Git repositories
- ✅ **Centralized secret management** in AWS
- ✅ **Automatic secret rotation** capabilities
- ✅ **Audit trail** for secret access
- ✅ **Encryption at rest** using AWS KMS

## Architecture

```
AWS Parameter Store  →  External Secrets Operator  →  Kubernetes Secrets  →  Application Pods
```

## Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** to provision infrastructure (installs ESO automatically)
3. **kubectl** to verify Kubernetes resources
4. **IAM permissions** to create SSM parameters

## Quick Start

### 1. Setup Parameter Store (One-time)

Run the interactive setup script:

```bash
./scripts/setup-parameter-store.sh
```

This script will:
- Prompt you for secret values
- Create encrypted parameters in AWS SSM Parameter Store
- Support both dev and prod environments

### 2. Deploy Infrastructure

The External Secrets Operator is automatically installed via Terraform:

```bash
# For development
cd infra/environments/dev
terraform init
terraform apply

# For production
cd infra/environments/prod
terraform init
terraform apply
```

### 3. Deploy Kubernetes Manifests

Deploy the SecretStore configuration:

```bash
kubectl apply -f k8s/addons/external-secrets-config.yaml
```

Deploy your application manifests:

```bash
# Development
kubectl apply -f k8s/environments/dev/all-in-one.yaml

# Production
kubectl apply -f k8s/environments/prod/all-in-one.yaml
```

## Parameter Store Structure

### Development Environment

```
/practice-node-app-dev/
  ├── dev/
  │   ├── db-password          # Database password
  │   ├── api-key              # External API key
  │   ├── jwt-secret           # JWT signing secret
  │   ├── datadog-api-key      # Datadog API key
  │   └── datadog-app-key      # Datadog application key
```

### Production Environment

```
/practice-node-app-prod/
  ├── prod/
  │   ├── db-password          # Database password
  │   ├── api-key              # External API key
  │   ├── jwt-secret           # JWT signing secret
  │   ├── datadog-api-key      # Datadog API key
  │   └── datadog-app-key      # Datadog application key
```

## Manual Parameter Creation

If you prefer to create parameters manually:

```bash
# Development DB Password
aws ssm put-parameter \
  --name "/practice-node-app-dev/dev/db-password" \
  --value "your-secure-password" \
  --type "SecureString" \
  --description "Database password for development" \
  --region us-east-1

# Production API Key
aws ssm put-parameter \
  --name "/practice-node-app-prod/prod/api-key" \
  --value "your-api-key" \
  --type "SecureString" \
  --description "API key for production" \
  --region us-east-1
```

## Verifying Setup

### 1. Check Parameter Store

```bash
# List all dev parameters
aws ssm get-parameters-by-path \
  --path "/practice-node-app-dev/dev" \
  --region us-east-1

# List all prod parameters
aws ssm get-parameters-by-path \
  --path "/practice-node-app-prod/prod" \
  --region us-east-1
```

### 2. Check External Secrets Operator

```bash
# Verify ESO is running
kubectl get pods -n external-secrets

# Check SecretStores
kubectl get secretstores -A

# Check ExternalSecrets
kubectl get externalsecrets -A
```

### 3. Check Synced Kubernetes Secrets

```bash
# Development
kubectl get secret practice-app-secrets-dev -n practice-app-dev
kubectl describe externalsecret practice-app-secrets-dev -n practice-app-dev

# Production
kubectl get secret practice-app-secrets-prod -n practice-app-prod
kubectl describe externalsecret practice-app-secrets-prod -n practice-app-prod
```

## How It Works

### 1. External Secrets Operator (ESO)

ESO is installed via Terraform Helm provider with:
- **IRSA (IAM Roles for Service Accounts)** for AWS authentication
- **IAM permissions** to read from Parameter Store
- **Namespace**: `external-secrets`

### 2. SecretStore Resource

Defines the connection to AWS Parameter Store:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-parameter-store-dev
  namespace: practice-app-dev
spec:
  provider:
    aws:
      service: ParameterStore
      region: us-east-1
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets
```

### 3. ExternalSecret Resource

Maps Parameter Store parameters to Kubernetes secrets:

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: practice-app-secrets-dev
  namespace: practice-app-dev
spec:
  secretStoreRef:
    name: aws-parameter-store-dev
    kind: SecretStore
  target:
    name: practice-app-secrets-dev
  refreshInterval: 1h
  data:
    - secretKey: DB_PASSWORD
      remoteRef:
        key: /practice-node-app-dev/dev/db-password
```

### 4. Application Consumption

Pods consume secrets normally via environment variables or volume mounts:

```yaml
env:
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: practice-app-secrets-dev
        key: DB_PASSWORD
```

## Updating Secrets

### Update Parameter in AWS

```bash
aws ssm put-parameter \
  --name "/practice-node-app-dev/dev/db-password" \
  --value "new-password" \
  --overwrite \
  --region us-east-1
```

### Sync Updates

Secrets are automatically refreshed based on `refreshInterval` (default: 1 hour).

To force immediate sync:

```bash
kubectl annotate externalsecret practice-app-secrets-dev \
  -n practice-app-dev \
  force-sync=$(date +%s)
```

## IAM Permissions

The External Secrets Operator requires these IAM permissions (automatically created by Terraform):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ],
      "Resource": [
        "arn:aws:ssm:us-east-1:602202572057:parameter/practice-node-app-*/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Decrypt"
      ],
      "Resource": [
        "arn:aws:kms:us-east-1:602202572057:key/*"
      ]
    }
  ]
}
```

## Troubleshooting

### External Secrets Not Syncing

```bash
# Check ESO logs
kubectl logs -n external-secrets deployment/external-secrets

# Check ExternalSecret status
kubectl describe externalsecret practice-app-secrets-dev -n practice-app-dev

# Common issues:
# 1. IAM role not attached to ServiceAccount
kubectl get sa external-secrets -n practice-app-dev -o yaml | grep eks.amazonaws.com/role-arn

# 2. Parameters don't exist in Parameter Store
aws ssm get-parameter --name "/practice-node-app-dev/dev/db-password" --region us-east-1

# 3. Wrong parameter path
kubectl get externalsecret practice-app-secrets-dev -n practice-app-dev -o yaml
```

### Permission Denied Errors

```bash
# Verify IAM role trust relationship
aws iam get-role --role-name practice-node-app-dev-external-secrets-operator

# Verify OIDC provider exists
aws iam list-open-id-connect-providers
```

### Secret Not Available to Pods

```bash
# Check if Kubernetes secret was created
kubectl get secret practice-app-secrets-dev -n practice-app-dev

# View secret keys (not values)
kubectl get secret practice-app-secrets-dev -n practice-app-dev -o jsonpath='{.data}'

# Check pod can mount secret
kubectl describe pod <pod-name> -n practice-app-dev
```

## Security Best Practices

1. **Use SecureString type** for all sensitive parameters
2. **Enable encryption** using AWS KMS (done automatically)
3. **Rotate secrets regularly** using AWS rotation features
4. **Use least-privilege IAM policies** (scoped to specific parameter paths)
5. **Enable CloudTrail** to audit parameter access
6. **Never commit secrets to Git** (replaced by Parameter Store)
7. **Use different parameters** for dev vs prod environments

## Cost Optimization

- **Standard tier** parameters: Free for first 10,000 parameters
- **SecureString encryption**: Uses AWS managed KMS key (free) or customer-managed key
- **ESO refreshInterval**: Set to 1h to reduce API calls

## Migration from Hardcoded Secrets

✅ **Completed**: All hardcoded secrets have been removed from:
- `k8s/environments/dev/all-in-one.yaml`
- `k8s/environments/prod/all-in-one.yaml`
- `k8s/service-discovery.yml`

Secrets are now managed via ExternalSecret resources.

## References

- [External Secrets Operator Documentation](https://external-secrets.io/)
- [AWS Systems Manager Parameter Store](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-parameter-store.html)
- [EKS IRSA (IAM Roles for Service Accounts)](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
