# Infrastructure

Terraform for VPC, EKS, ECR, and cluster addons (ALB controller + External Secrets via Helm).

**Always work from `environments/dev` or `environments/prod`** (via the scripts below). Ignore `infra/archive/` — old root module.

## Create / destroy

```bash
cd infra

./create-dev.sh              # create development
./create-prod.sh             # create production (typed confirm)

./destroy-dev-simple.sh      # destroy development
./destroy-prod-simple.sh     # destroy production (typed confirm)
```

## Layout

```
infra/
├── environments/dev/     # live Terraform for dev
├── environments/prod/    # live Terraform for prod
├── modules/              # vpc, eks, ecr, parameter-store
├── create-*.sh / destroy-*.sh / setup-*.sh
└── archive/              # legacy root module (unused)
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
```

## GitHub Actions

- `terraform-plan.yml` — plan on infra PRs
- `terraform-apply.yml` — manual apply
- `terraform-destroy.yml` — manual destroy

## Prerequisites

- AWS CLI configured (`us-east-1`)
- Terraform >= 1.0
- kubectl
