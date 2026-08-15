# Workflows

**Infra (create/destroy/update AWS):** use local scripts in `infra/` — not GitHub Actions.

**App (build + deploy):** use the 3 workflows below (optional once clusters exist).

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

## Workflows (3)

| File | Trigger | Purpose |
|---|---|---|
| `node-ci.yml` | push/PR on feature, develop, main | Run tests |
| `auto-deploy-dev.yml` | After CI succeeds on push to `develop` | Build + deploy to dev |
| `deploy-prod.yml` | Manual | Build from `main` + deploy to prod |

## When to use what

| Goal | Tool |
|---|---|
| Create / destroy cluster | `infra/create-*.sh` / `infra/destroy-*-simple.sh` |
| Change VPC/EKS/node size | Edit `infra/environments/*/`, then `terraform plan` + `terraform apply` locally |
| First app deploy on a cluster | `kubectl apply -f k8s/environments/<env>/all-in-one.yaml` |
| Routine code → **dev** | Merge to `develop` (auto-deploy) |
| Release → **prod** | Actions → **Deploy to Production** (type confirmation phrase) |

## Image tags

| Env | Tag |
|---|---|
| Dev | `develop-<7-char-sha>` |
| Prod | `main-<7-char-sha>` |

## App manifests used by CI

- Dev: `k8s/environments/dev/all-in-one.yaml`
- Prod: `k8s/environments/prod/all-in-one.yaml`
