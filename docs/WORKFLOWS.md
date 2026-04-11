# Workflows & Branching Guide

## Branch Model

```
feature/* ──── PR ────→ develop ──── PR ────→ main
                           │                    │
                      auto-deploy          notify-ready
                        (dev)            (reminder only)
                                              │
                                         manual trigger
                                        (prod deploy)
```

| Branch | Protected | Direct push | Purpose |
|---|---|---|---|
| `main` | Yes | No | Production-ready code |
| `develop` | Yes | No | Integration branch — auto-deploys to dev |
| `feature/*` | No | Yes | Day-to-day development |

> Branch protection rules (no direct push, CI required to merge) must be configured in **GitHub repo Settings → Branches**.

---

## Automatic Triggers

| Event | Workflows that fire | Notes |
|---|---|---|
| Push to `feature/**` | `node-ci` | Tests only — no deploy |
| PR → `develop` | `node-ci` | Must pass before merge |
| Push to `develop` (merged PR) | `node-ci` → `auto-deploy-dev` | CI must pass first; auto-deploy only fires on push, not PRs |
| PR → `main` | `node-ci`, `terraform-plan` (if `infra/**` changed) | Must pass before merge |
| Push to `main` (merged PR) | `node-ci`, `notify-ready` | Reminder posted in step summary to run prod deploy |

---

## Manual Workflows

### Standard release — `deploy-prod.yml`
Use when merging `develop` → `main` and you want a clean build deployed to prod.

```
merge develop → main
      ↓
notify-ready posts reminder
      ↓
Actions → Deploy to Production → Run workflow
Type: deploy-production
```

Builds fresh from `main` HEAD, Trivy scans the image, deploys with SHA tag `main-<sha>`, runs k6 load test, auto-rolls back on failure.

---

### Canary release — `canary-deploy.yml`
Use for risky changes where you want to validate with partial traffic before full rollout.

```
Step 1 — action=deploy, traffic_percentage=10
         Deploys canary alongside stable, splits 10% traffic to canary

Step 2a — action=promote (if canary looks good)
          Rolls canary image to stable deployment, removes canary, 100% traffic restored

Step 2b — action=rollback (if canary looks bad)
          Removes canary deployment, 100% traffic back to stable immediately
```

---

### Promote — `promote-to-prod.yml`
Use when a `develop-<sha>` image has already been running in dev for a while and you trust it — skips the rebuild entirely.

```
Actions → Promote to Production → Run workflow
commit_sha: <7-char sha that ran in dev>
Type: promote-production
```

Pulls `develop-<sha>` from dev ECR, retags it as `main-<sha>` in prod ECR, Trivy scans, deploys. Same binary that was tested in dev — no source rebuild.

---

### Infrastructure — `terraform-plan.yml` / `terraform-apply.yml`

```
edit infra/** on feature branch
      ↓
PR → main: terraform-plan auto-runs, plan posted as PR comment
      ↓
merge PR
      ↓
Actions → Terraform Apply → Run workflow (select env: dev or prod)
```

Always review the plan output before applying. `terraform-destroy.yml` requires typing `destroy` (dev) or `destroy-production` (prod) to confirm.

---

### Bootstrap a new environment — `complete-bootstrap.yml`
Run once when setting up a brand new environment from scratch. Handles S3 state backend, DynamoDB lock table, Terraform apply, and initial app deploy in one shot.

---

### Manual dev redeploy — `deploy-dev.yml`
Use only when you need to redeploy a specific older image tag to dev. Under normal flow this is not needed — dev auto-deploys on every push to `develop`.

---

## Decision Tree — Which prod workflow?

```
Releasing to prod?
        │
        ├── Risky change, want gradual rollout?
        │         └── YES → canary-deploy (deploy → monitor → promote or rollback)
        │
        ├── Image already validated in dev, want fastest path / no rebuild?
        │         └── YES → promote-to-prod (retag dev image → prod ECR)
        │
        └── Standard release from main HEAD?
                  └── YES → deploy-prod (build → Trivy → k6 → auto-rollback)
```

---

## Image Tag Convention

| Environment | Tag format | Example |
|---|---|---|
| Dev | `develop-<7-char-sha>` | `develop-a1b2c3d` |
| Prod | `main-<7-char-sha>` | `main-a1b2c3d` |

Tags are immutable. Rollback via `kubectl rollout undo` works correctly because each deploy has a unique tag in ECR.

---

## Workflow File Reference

| File | Trigger | Purpose |
|---|---|---|
| `node-ci.yml` | push `feature/**`, `develop`, `main`; PR → `develop`, `main` | Tests + smoke test |
| `auto-deploy-dev.yml` | after `node-ci` passes on push to `develop` | Build + deploy to dev EKS |
| `notify-ready.yml` | push to `main` (app code) | Step summary reminder to deploy prod |
| `deploy-prod.yml` | manual | Build from `main`, deploy to prod |
| `promote-to-prod.yml` | manual | Retag dev image → prod, no rebuild |
| `canary-deploy.yml` | manual (action: deploy / promote / rollback) | Canary traffic split on prod |
| `deploy-dev.yml` | manual | Redeploy specific tag to dev |
| `terraform-plan.yml` | PR on `infra/**`, manual | Terraform plan |
| `terraform-apply.yml` | manual | Terraform apply |
| `terraform-destroy.yml` | manual | Terraform destroy |
| `complete-bootstrap.yml` | manual | Full environment setup from zero |
