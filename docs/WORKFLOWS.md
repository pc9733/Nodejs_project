# Workflows

## Branch flow

```
feature/* ──PR──▶ develop ──PR──▶ main
                    │               │
               auto-deploy-dev   (manual) deploy-prod
```

| Branch | Purpose |
|---|---|
| `feature/*` | Day-to-day work |
| `develop` | Integration — auto-deploys to **dev** |
| `main` | Production-ready — deploy **prod** manually |

## Workflows (6)

| File | Trigger | Purpose |
|---|---|---|
| `node-ci.yml` | push/PR on feature, develop, main | Tests |
| `auto-deploy-dev.yml` | After CI succeeds on push to `develop` | Build + deploy to dev |
| `deploy-prod.yml` | Manual | Build from `main` + deploy to prod |
| `terraform-plan.yml` | PR touching `infra/**`, or manual | Terraform plan |
| `terraform-apply.yml` | Manual | Terraform apply (dev or prod) |
| `terraform-destroy.yml` | Manual | Terraform destroy (typed confirm) |

## Which prod action?

Use **Deploy to Production** (`deploy-prod.yml`) after merging to `main`.

Type the confirmation phrase when prompted.

## Image tags

| Env | Tag |
|---|---|
| Dev | `develop-<7-char-sha>` |
| Prod | `main-<7-char-sha>` |

## App manifests used by CI

- Dev: `k8s/environments/dev/all-in-one.yaml`
- Prod: `k8s/environments/prod/all-in-one.yaml`
