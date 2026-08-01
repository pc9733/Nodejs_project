# Parameter Store (secrets)

Secrets live in **AWS SSM Parameter Store** and sync into Kubernetes via **External Secrets Operator** (installed by Terraform).

```
SSM Parameter Store → ClusterSecretStore → ExternalSecret → K8s Secret → Pods
```

## Setup (once per env)

```bash
# 1. Create parameters
./scripts/setup-parameter-store.sh

# 2. Infra must already exist (ESO installed by Terraform)
cd infra && ./create-dev.sh

# 3. Confirm ESO is healthy (webhook Service must exist)
kubectl get deploy,svc -n external-secrets

# 4. Apply ClusterSecretStore for THIS cluster
kubectl apply -f k8s/addons/external-secrets-dev.yaml    # on dev
# kubectl apply -f k8s/addons/external-secrets-prod.yaml # on prod

# 5. Deploy app (creates ExternalSecret)
kubectl apply -f k8s/environments/dev/all-in-one.yaml
```

## Parameter paths

**Dev:** `/practice-node-app-dev/dev/{db-password,api-key,jwt-secret}`  
**Prod:** `/practice-node-app-prod/prod/{db-password,api-key,jwt-secret}`

## Verify

```bash
kubectl get clustersecretstore
kubectl get externalsecret -n practice-app-dev
kubectl get secrets -n practice-app-dev
```

Expected: `ClusterSecretStore` **Ready=True**, `ExternalSecret` **SecretSynced**.

## If ESO webhook is broken

Terraform Helm release can end up `failed` (no webhook Service). Repair:

```bash
helm repo add external-secrets https://charts.external-secrets.io
helm upgrade --install external-secrets external-secrets/external-secrets \
  -n external-secrets --version 0.9.11 --set installCRDs=true --wait

# Re-attach IRSA (required for SSM access)
kubectl annotate sa external-secrets -n external-secrets \
  eks.amazonaws.com/role-arn=arn:aws:iam::ACCOUNT:role/practice-node-app-dev-external-secrets-operator \
  --overwrite
```

Longer notes: [docs/archive/PARAMETER_STORE_SETUP.md](archive/PARAMETER_STORE_SETUP.md)
