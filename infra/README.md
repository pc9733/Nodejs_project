# Infrastructure

Terraform for VPC, EKS, ECR, and cluster addons (ALB controller + External Secrets via Helm).

**Always work from `environments/dev` or `environments/prod`** (via the scripts below).

## Create / destroy

```bash
cd infra

./create-dev.sh              # create development
./create-prod.sh             # create production (typed confirm)

./destroy-dev-simple.sh      # destroy development
./destroy-prod-simple.sh     # destroy production (typed confirm)
```

`create-*.sh` runs `setup-*.sh` first (S3 state bucket + DynamoDB lock table), then `terraform apply`.

## Update existing infra (not full recreate)

```bash
cd infra/environments/dev    # or prod
terraform plan
terraform apply
```

## Layout

```
infra/
├── environments/dev/     # live Terraform for dev
├── environments/prod/    # live Terraform for prod
├── modules/              # vpc, eks, ecr, parameter-store
├── create-*.sh / destroy-*.sh / setup-*.sh
```

## Env details

| | Dev | Prod |
|---|---|---|
| Cluster | `practice-node-app-dev` | `practice-node-app-prod` |
| ECR | `practice-node-app-dev` | `practice-node-app-prod` |
| Namespace | `practice-app-dev` | `practice-app-prod` |
| Nodes | t3.small, 1–2 | t3.medium, 2–4 |

## After create

```bash
aws eks update-kubeconfig --name practice-node-app-dev --region us-east-1
kubectl get nodes

# from repo root:
./scripts/setup-parameter-store.sh
kubectl apply -f k8s/addons/external-secrets-dev.yaml
kubectl apply -f k8s/environments/dev/all-in-one.yaml
```

## Prerequisites

- AWS CLI configured (`us-east-1`)
- Terraform >= 1.0
- kubectl
