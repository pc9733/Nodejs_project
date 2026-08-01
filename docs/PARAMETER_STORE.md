# Parameter Store (secrets)

Secrets live in **AWS SSM Parameter Store** and sync into Kubernetes via **External Secrets Operator** (installed by Terraform).

```
SSM Parameter Store → External Secrets Operator → K8s Secret → Pods
```

## Setup (once per env)

```bash
# 1. Create parameters
./scripts/setup-parameter-store.sh

# 2. Infra must already exist (ESO is installed by Terraform)
cd infra && ./create-dev.sh   # or create-prod.sh

# 3. Apply SecretStores
kubectl apply -f k8s/addons/external-secrets-config.yaml

# 4. Deploy app (creates ExternalSecret resources)
kubectl apply -f k8s/environments/dev/all-in-one.yaml
# or for prod:
kubectl apply -f k8s/environments/prod/all-in-one.yaml
```

## Parameter paths

**Dev**

- `/practice-node-app-dev/dev/db-password`
- `/practice-node-app-dev/dev/api-key`
- `/practice-node-app-dev/dev/jwt-secret`

**Prod**

- `/practice-node-app-prod/prod/db-password`
- `/practice-node-app-prod/prod/api-key`
- `/practice-node-app-prod/prod/jwt-secret`

## Verify

```bash
kubectl get secretstore -A
kubectl get externalsecret -n practice-app-dev
kubectl get secrets -n practice-app-dev
```

Longer notes (optional): [docs/archive/PARAMETER_STORE_SETUP.md](archive/PARAMETER_STORE_SETUP.md)
