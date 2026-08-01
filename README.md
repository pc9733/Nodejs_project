# Node.js EKS Practice Project

Simple practice stack: **Node app → GitHub Actions → ECR → EKS**.

## When to use what

| I want to… | Do this |
|---|---|
| Create AWS (dev) | `cd infra && ./create-dev.sh` |
| Create AWS (prod) | `cd infra && ./create-prod.sh` |
| Destroy AWS | `./destroy-dev-simple.sh` or `./destroy-prod-simple.sh` |
| Set secrets | `./scripts/setup-parameter-store.sh` |
| Ship code to **dev** | Merge to `develop` → auto-deploys |
| Ship code to **prod** | Merge to `main` → run **Deploy to Production** workflow |
| Change infra | Edit `infra/` → PR runs plan → manual **Terraform Apply** |

## Repo map

```
node-app/                 # Node.js application
infra/                    # Terraform (use environments/dev|prod + scripts)
k8s/
  environments/dev/       # App manifests for dev  (all-in-one.yaml)
  environments/prod/      # App manifests for prod (all-in-one.yaml)
  addons/                 # External Secrets SecretStore config
  archive/                # Old examples (ignore for day-to-day)
.github/workflows/        # CI/CD (6 workflows)
scripts/                  # Backend + Parameter Store helpers
docs/                     # Short guides (long notes in docs/archive/)
```

## Quick start

```bash
# 1. Infra
cd infra && ./create-dev.sh

# 2. Secrets (once)
./scripts/setup-parameter-store.sh

# 3. SecretStore + app (or push to develop for CI)
kubectl apply -f k8s/addons/external-secrets-config.yaml
kubectl apply -f k8s/environments/dev/all-in-one.yaml
```

## Environments

| Env | Namespace | Cluster | Deploy |
|---|---|---|---|
| Dev | `practice-app-dev` | `practice-node-app-dev` | Auto on push to `develop` |
| Prod | `practice-app-prod` | `practice-node-app-prod` | Manual workflow |

## Docs

- [Workflows](docs/WORKFLOWS.md) — which GitHub Action to run
- [Parameter Store](docs/PARAMETER_STORE.md) — secrets setup
- [Infra scripts](infra/README.md) — create/destroy AWS
- `docs/archive/` — longer historical notes (optional reading)

## Useful commands

```bash
kubectl get all -n practice-app-dev
kubectl get all -n practice-app-prod
kubectl logs -f deployment/practice-node-app-dev -n practice-app-dev
kubectl port-forward svc/practice-node-app-dev 3000:80 -n practice-app-dev
```
