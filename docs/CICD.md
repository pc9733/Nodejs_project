# CI/CD Pipeline Documentation

## Workflow Catalog

| Workflow | File | Trigger(s) | Purpose |
|----------|------|------------|---------|
| Node CI | `.github/workflows/node-ci.yml` | Pushes to `develop`, `feature/*`, `hotfix/*` (docs ignored) and PRs to `develop` | Run Node.js install, unit tests, and a smoke test without touching infrastructure.
| Deploy to Development | `.github/workflows/deploy-dev.yml` | Manual `workflow_dispatch` | Builds an image and deploys the latest tag into the dev namespace/cluster.
| Deploy to Production | `.github/workflows/deploy-prod.yml` | Manual `workflow_dispatch` + approval text | Builds image, deploys manifests to prod, runs health/perf gates.
| Canary Deployment | `.github/workflows/canary-deploy.yml` | Manual `workflow_dispatch` | Spin up a canary deployment and split traffic via ingress weights.
| Promote to Production | `.github/workflows/promote-to-prod.yml` | Manual `workflow_dispatch` + approval text | Promote a specific commit from `develop` to prod after validation.
| Terraform Plan | `.github/workflows/terraform-plan.yml` | Manual `workflow_dispatch` or PRs touching `infra/**` | Generate a Terraform plan per environment and publish the artifact/PR comment.
| Terraform Apply | `.github/workflows/terraform-apply.yml` | Manual `workflow_dispatch` only | Run Terraform plan+apply for dev/prod when `auto_approve=true`.
| Terraform Destroy | `.github/workflows/terraform-destroy.yml` | Manual `workflow_dispatch` only | Tear down an environment after explicit confirmation phrases.
| Legacy Deploy | `.github/workflows/deploy-node-app.yml` | Manual `workflow_dispatch` | Old one-shot workflow for the monolithic namespace; kept for reference only.

> **Key change:** Pushes to `develop` no longer deploy or run Terraform. They only run the `Node CI` workflow. Deployments and Terraform applies must now be triggered intentionally.

## Workflow Details

### Node CI (`node-ci.yml`)
- **Why**: Ensures every push/PR still runs Node.js tests without automatically touching AWS or Kubernetes.
- **Steps**: Checkout → `setup-node@v4` → `npm ci` (full dev install) → `npm test` (non-blocking if no tests) → smoke test by requiring `server.js`.
- **Notes**: `paths-ignore` skips docs-only pushes, keeping the pipeline fast.

### Deploy to Development (`deploy-dev.yml`)
- **Trigger**: Manual input for `image_tag` (defaults to `latest`).
- **Steps**: Similar to CI but includes `npm ci --omit=dev`, Docker build/push, Trivy scan, kubeconfig update, manifest apply for `k8s/environments/dev/all-in-one.yaml`, rollout wait, health checks, and cleanup.
- **Result**: Only runs when requested, so merges to `develop` are safe until you hit “Run workflow.”

### Deploy to Production (`deploy-prod.yml`)
- **Trigger**: Manual with `approve_deployment` set to `deploy-production`.
- **Steps**: Build/push prod image, security scan, explicit approval gate, kubeconfig update, manifest apply for prod namespace, rollout+health/perf checks, optional k6 load test, and ECR cleanup.
- **Use**: Run only after dev validation and a Terraform plan/apply (if infra changed).

### Canary Deployment (`canary-deploy.yml`)
- **Trigger**: Manual, specify traffic % (1–50) and optional `image_tag`.
- **Flow**: Clone the main deployment into `practice-node-app-canary`, update to selected image, wait for rollout, patch ingress rules to split traffic, and emit cleanup instructions.
- **Follow-up**: Use `promote-to-prod.yml` or `deploy-prod.yml` once confidence is built.

### Promote to Production (`promote-to-prod.yml`)
- **Trigger**: Manual with `approve_promotion` set to `promote-production`; optional `commit_sha` targeting a specific `develop` commit.
- **Flow**: Checkout full history, resolve commit SHA, rerun Node.js install/tests, authenticate to AWS/ECR, update prod manifests to that artifact, and run the same health checks as a standard prod deploy.

### Terraform Plan (`terraform-plan.yml`)
- **Triggers**: Manual dispatch (choose `dev` or `prod`) *or* automatically on PRs that touch `infra/**`.
- **Flow**: Determine environment, run remote-state bootstrap script, `terraform init/validate/plan`, upload `tfplan` artifact, render `plan.json`, and comment on PRs.
- **Change from old setup**: Pushes to `develop` no longer invoke this workflow; you get plans only where they’re reviewed.

### Terraform Apply (`terraform-apply.yml`)
- **Trigger**: Manual dispatch. You **must** set `auto_approve=true`; otherwise the workflow halts intentionally after printing instructions.
- **Flow**: Same bootstrap/init/validate/plan sequence as the plan workflow, followed by `terraform apply -auto-approve tfplan`, outputs (`cluster_name`, `ecr_repository_url`), kubeconfig update, optional cluster verification, and a summary block detailing next steps (e.g., run `deploy-dev` or `deploy-prod`).

### Terraform Destroy (`terraform-destroy.yml`)
- **Trigger**: Manual dispatch only, with confirmation strings (`destroy` and `destroy-production`).
- **Flow**: Remote-state bootstrap, `terraform destroy -auto-approve`, optional cleanup of S3/DynamoDB state stores, and a summary of removed resources.

### Legacy Deploy (`deploy-node-app.yml`)
- **Status**: Kept for historical reference; still available via manual dispatch but not recommended for multi-env setups.
- **Behavior**: Applies everything under `k8s/` to the shared namespace and updates the single deployment image.

## Recommended Release Flow

1. **Developers push code** → `Node CI` runs automatically (tests + smoke). Fix failures before opening PRs.
2. **Infra changes?** → Open a PR; `Terraform Plan` posts the plan automatically for review. Iterate until approved.
3. **Merge to `develop`** → Nothing deploys automatically. When ready, manually:
   1. Run `deploy-dev.yml` (select image tag if you need an older artifact).
   2. Smoke-test the app / run any QA checks in dev.
   3. If Terraform changes are needed, trigger `terraform-apply.yml` for the relevant environment with `auto_approve=true`.
4. **Preparing prod**:
   - Option A: Run a canary via `canary-deploy.yml`, monitor, then `promote-to-prod.yml`.
   - Option B: Run `deploy-prod.yml` directly with the approval passphrase.
5. **Cleanup**: When an environment must be torn down, run `terraform-destroy.yml` with the required confirmations.

This separation keeps CI fast, makes deployments intentional, and prevents Terraform from running on every push while still documenting a clear path from commit → dev → prod.
