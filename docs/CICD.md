# CI/CD Pipeline Documentation

## 🎯 Overview

This project uses **GitHub Actions** for CI/CD with intelligent trigger mechanisms to save CI minutes while maintaining fast feedback loops. Workflows are designed to be **intentional** rather than automatic, with specific controls for different stages.

---

## 📋 Workflow Catalog

| Workflow | File | Trigger(s) | Purpose |
|----------|------|------------|---------|
| **Node CI** | `.github/workflows/node-ci.yml` | PRs to `develop`/`main`, pushes to `develop` (app code only), manual | Run Node.js install, unit tests, and smoke test. Supports `[skip ci]` flag.
| **Auto Deploy Dev** 🆕 | `.github/workflows/auto-deploy-dev.yml` | After successful Node CI on `develop` | Automatically builds image and deploys to dev cluster after tests pass.
| **Deploy to Development** | `.github/workflows/deploy-dev.yml` | Manual `workflow_dispatch` | Manually builds an image and deploys specific tag to dev namespace/cluster.
| **Deploy to Production** | `.github/workflows/deploy-prod.yml` | Manual `workflow_dispatch` + approval text | Builds image, deploys manifests to prod, runs health/perf gates.
| **Canary Deployment** | `.github/workflows/canary-deploy.yml` | Manual `workflow_dispatch` | Spin up canary deployment and split traffic via ingress weights.
| **Promote to Production** | `.github/workflows/promote-to-prod.yml` | Manual `workflow_dispatch` + approval text | Promote specific commit from `develop` to prod after validation.
| **Terraform Plan** | `.github/workflows/terraform-plan.yml` | Manual `workflow_dispatch` or PRs touching `infra/**` | Generate Terraform plan per environment and publish artifact/PR comment.
| **Terraform Apply** | `.github/workflows/terraform-apply.yml` | Manual `workflow_dispatch` only | Run Terraform plan+apply for dev/prod when `auto_approve=true`.
| **Terraform Destroy** | `.github/workflows/terraform-destroy.yml` | Manual `workflow_dispatch` only | Tear down environment after explicit confirmation phrases.
| **Legacy Deploy** | `.github/workflows/deploy-node-app.yml` | Manual `workflow_dispatch` | Old one-shot workflow for monolithic namespace; kept for reference only.

---

## 🚦 Trigger Strategy Summary

### **Automatic Triggers**
- ✅ **Node CI**: Runs on PRs and `develop` pushes (app code only)
- ✅ **Auto Deploy Dev**: Runs after successful Node CI on `develop`
- ✅ **Terraform Plan**: Runs on PRs touching `infra/**`

### **Manual Triggers**
- 🔒 **All production deployments** (safety)
- 🔒 **All Terraform apply/destroy** (safety)
- 🔧 **All workflows** can be manually triggered via `workflow_dispatch`

### **Skip Controls**
- 🚫 Add `[skip ci]` or `[ci skip]` to commit messages to skip CI
- 📝 See [`.github/COMMIT_CONVENTIONS.md`](../.github/COMMIT_CONVENTIONS.md) for details

---

## Workflow Details

### Node CI (`node-ci.yml`) 🔄 UPDATED
- **Triggers**:
  - Pull requests to `develop` or `main` branches
  - Pushes to `develop` branch (only when app code changes)
  - Manual trigger via workflow_dispatch
  - **Skipped** when commit contains `[skip ci]` or `[ci skip]`
- **Path Filters**: Only runs when these files change:
  - `node-app/**`
  - `Dockerfile`
  - `package*.json`
  - `.github/workflows/node-ci.yml`
- **Steps**: Checkout → `setup-node@v4` → `npm ci` (full dev install) → `npm test` (non-blocking if no tests) → smoke test by requiring `server.js`.
- **Why**: Ensures tests run on all PRs and develop pushes, but skips CI for feature branch pushes and docs-only changes to save CI minutes.

### Auto Deploy to Development (`auto-deploy-dev.yml`) 🆕 NEW
- **Triggers**: Automatically runs after successful `Node CI` workflow on `develop` branch
- **Condition**: Only deploys if tests passed
- **Steps**:
  1. Build Docker image with tag `develop-{short-sha}`
  2. Push to ECR repository `practice-node-app-dev`
  3. Run Trivy vulnerability scan
  4. Apply `k8s/environments/dev/all-in-one.yaml` manifests
  5. Update deployment with new image
  6. Wait for rollout and perform health checks
  7. Clean up old ECR images (keep last 10)
- **Why**: Provides continuous deployment to dev environment after tests pass, enabling fast feedback loop without manual intervention.
- **Note**: This is separate from the manual `deploy-dev.yml` workflow, which can still be used to deploy specific image tags.

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

## 🚀 Recommended Release Flow

### **Development Flow** (Feature → Dev)

1. **Create feature branch**
   ```bash
   git checkout -b feature/user-dashboard
   ```

2. **Work in progress commits** (skip CI to save minutes)
   ```bash
   git commit -m "wip: scaffold dashboard [skip ci]"
   git push origin feature/user-dashboard
   ```
   - ℹ️ No CI runs on feature branch pushes

3. **Ready for review** - Create Pull Request
   ```bash
   gh pr create --base develop --title "Add user dashboard"
   ```
   - ✅ **Node CI** runs automatically on PR
   - ✅ Tests must pass before merge

4. **Merge to `develop`**
   ```bash
   gh pr merge
   ```
   - ✅ **Node CI** runs on merge commit
   - ✅ **Auto Deploy Dev** triggers after CI passes
   - ✅ Application automatically deployed to dev cluster
   - 📊 Check deployment status in GitHub Actions

5. **Test in dev environment**
   ```bash
   kubectl get pods -n practice-app-dev
   kubectl logs -f deployment/practice-node-app-dev -n practice-app-dev
   ```

### **Infrastructure Changes Flow**

1. **Update Terraform code**
   ```bash
   git checkout -b infra/add-cluster-autoscaler
   # Make changes to infra/**
   git commit -m "feat(infra): add cluster autoscaler"
   git push
   ```

2. **Create PR** → **Terraform Plan** runs automatically
   - 📋 Plan posted as PR comment
   - 👀 Review infrastructure changes

3. **After merge** → Manually apply Terraform
   - Go to Actions → **Terraform Apply**
   - Select environment (`dev` or `prod`)
   - Set `auto_approve=true`
   - Confirm and run

### **Production Deployment Flow**

#### **Option A: Standard Deployment**

1. **Verify dev deployment is stable**
   ```bash
   kubectl get deployment practice-node-app-dev -n practice-app-dev
   ```

2. **Manual deployment to prod**
   - Go to Actions → **Deploy to Production**
   - Enter approval: `deploy-production`
   - Workflow builds image, runs tests, deploys to prod

#### **Option B: Canary Deployment** (Recommended)

1. **Create canary**
   - Go to Actions → **Canary Deployment**
   - Set traffic percentage (e.g., `10`)
   - Specify image tag (optional)
   - Run workflow

2. **Monitor canary metrics**
   ```bash
   kubectl get pods -n practice-app-prod -l app=practice-node-app-canary
   # Check Datadog/Grafana metrics
   ```

3. **Promote or rollback**
   - If metrics look good → **Promote to Production** workflow
   - If issues detected → **Rollback** (delete canary deployment)

### **Complete Flow Diagram**

```
Feature Branch
    ↓
[WIP commits with [skip ci]]  ← No CI runs
    ↓
Create PR to develop
    ↓
[Node CI runs]  ← Tests, smoke test
    ↓
Merge to develop
    ↓
[Node CI runs]  ← Tests pass
    ↓
[Auto Deploy Dev]  ← Automatic deployment
    ↓
[Test in dev]  ← Manual QA
    ↓
[Deploy to Prod]  ← Manual trigger
    ↓
Production ✅
```

---

## 🎯 Trigger Matrix (Quick Reference)

| Event | Node CI | Auto Deploy Dev | Terraform Plan | Notes |
|-------|---------|----------------|----------------|-------|
| Push to `feature/foo` | ❌ No | ❌ No | ❌ No | Work on feature branch |
| Push to `feature/foo` with `[skip ci]` | ❌ No | ❌ No | ❌ No | Explicit skip |
| Push to `develop` (app code) | ✅ Yes | ✅ Yes* | ❌ No | Auto CI + deploy |
| Push to `develop` (docs only) | ❌ No | ❌ No | ❌ No | Path filter |
| Push to `develop` with `[skip ci]` | ❌ No | ❌ No | ❌ No | Explicit skip |
| Create PR to `develop` | ✅ Yes | ❌ No | 🟡 If infra | Always test PRs |
| Update PR (push to PR branch) | ✅ Yes | ❌ No | 🟡 If infra | Re-test changes |
| Merge PR to `develop` | ✅ Yes | ✅ Yes* | ❌ No | Auto CI + deploy |
| Push to `main` | ✅ Yes | ❌ No | ❌ No | CI only, no auto-deploy |
| Manual trigger (any workflow) | ✅ Yes | ✅ Yes | ✅ Yes | Always available |

\* Auto Deploy Dev only runs if Node CI succeeds

---

## 📝 Best Practices

### **Commit Messages**
- ✅ Use conventional commit format: `type(scope): subject`
- ✅ Add `[skip ci]` for WIP/docs commits
- ✅ Reference issues: `Closes #123`
- 📖 See [`.github/COMMIT_CONVENTIONS.md`](../.github/COMMIT_CONVENTIONS.md)

### **CI/CD Workflow**
- ✅ Always create PRs for code review
- ✅ Let CI pass before merging
- ✅ Test in dev before deploying to prod
- ✅ Use canary deployments for risky changes
- ❌ Don't skip CI for actual code changes
- ❌ Don't push directly to `main`

### **Infrastructure Changes**
- ✅ Review Terraform plan in PR comments
- ✅ Apply Terraform manually after merge
- ✅ Test infra changes in dev first
- ❌ Don't auto-apply Terraform on pushes

---

## 🔧 Troubleshooting

### **CI not running on my PR**
- Check if commit contains `[skip ci]`
- Verify PR is targeting `develop` or `main`
- Check if only docs were changed (path filter)

### **Auto Deploy Dev didn't run**
- Verify Node CI completed successfully
- Check that push was to `develop` branch
- Look for `[skip ci]` in commit message

### **Deployment failed in dev**
- Check EKS cluster is running: `aws eks list-clusters`
- Verify kubeconfig: `kubectl get nodes`
- Check pod logs: `kubectl logs -f deployment/practice-node-app-dev -n practice-app-dev`
- See [docs/TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

---

## 📚 Related Documentation

- [Commit Message Conventions](../.github/COMMIT_CONVENTIONS.md)
- [Branching Strategy](./BRANCHING_STRATEGY.md)
- [Infrastructure Guide](./INFRASTRUCTURE.md)
- [Kubernetes Guide](./KUBERNETES.md)
- [Troubleshooting](./TROUBLESHOOTING.md)

---

This separation keeps CI fast, makes deployments intentional, and prevents unnecessary workflow runs while still maintaining a clear path from commit → dev → prod with automatic deployment to dev for fast feedback.
