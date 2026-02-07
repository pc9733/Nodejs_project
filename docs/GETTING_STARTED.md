# Environment Bootstrap & Deployment Guide

End-to-end checklist for standing up the AWS/EKS environment and deploying the Node.js application. Follow the steps in order; reference the linked docs for deeper dives.

## 1. Workstation & Access Prerequisites
- AWS account with permission to create VPC, EKS, IAM, ECR, and ALB resources.
- Installed CLIs: `aws` (v2), `terraform` (>=1.6), `kubectl`, `helm`, `docker`, and Node.js 18+ with npm.
- GitHub access to this repository plus permission to manage repo secrets/actions.
- Local AWS credentials configured via `aws configure` **or** environment variables.

## 2. Clone the Repository
```bash
git clone <repo-url>
cd Nodejs_project
```

## 3. Bootstrap Terraform Remote State (one-time)
```bash
cd infra
./setup-remote-state.sh      # Creates S3 bucket + DynamoDB table referenced by backend
terraform init               # Uses the remote backend
```

## 4. Provision the Environment
```bash
terraform plan -out=tfplan   # Review changes
terraform apply tfplan       # Create VPC, EKS, ECR, IAM, ALB controller, etc.
terraform output             # Capture cluster_name and ecr_repository_url
```
*See `docs/INFRASTRUCTURE.md` for component details.*

## 5. Configure kubectl Access
```bash
aws eks update-kubeconfig --name <cluster_name> --region us-east-1
kubectl get nodes
```
Optional: apply the dev manifests manually with `kubectl apply -f k8s/environments/dev/all-in-one.yaml` if you need an immediate smoke test.

## 6. Configure GitHub Secrets (required for workflows)
In the GitHub repo settings → *Secrets and variables → Actions*, add:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- Optional extras (e.g., Slack webhooks) if you extend notifications

These credentials must allow ECR, EKS, and ECR image lifecycle operations.

## 7. Validate the Application Locally
```bash
cd node-app
npm ci
npm test || echo "No tests configured"
node server.js               # Hit http://localhost:3000/health in another terminal
```

## 8. Deploy to Development via GitHub Actions
1. Push changes to a branch; `Node CI` (`.github/workflows/node-ci.yml`) runs automatically.
2. When ready, open the **Deploy to Development** workflow:
   - Choose `Run workflow` → select branch.
   - (Optional) Provide `image_tag`; default is the branch name.
3. Workflow stages:
   - Builds & pushes the Docker image to the `practice-node-app-dev` ECR repo.
   - Runs Trivy scan and uploads SARIF.
   - Updates kubeconfig, applies `k8s/environments/dev/all-in-one.yaml`, waits for rollout, runs health checks.
4. Validate:
   ```bash
   kubectl get pods -n practice-app-dev
   kubectl port-forward service/practice-node-app-dev 3000:80 -n practice-app-dev
   ```
*Reference: `docs/CICD.md` (Deploy to Development section).*

## 9. Optional Canary + Promotion
1. Trigger **canary-deploy.yml** to split traffic (specify percentage and optional `image_tag`).
2. Monitor metrics/logs.
3. Promote using **promote-to-prod.yml** if the canary looks good.

## 10. Deploy to Production
1. Ensure the prod Terraform stack is applied (same `infra/` code with prod vars if used).
2. Run **deploy-prod.yml**:
   - Provide `image_tag` if deploying a specific artifact.
   - Enter `deploy-production` in `approve_deployment`.
3. Workflow mirrors dev but targets the prod namespace/manifests, adds manual approval, optional k6 load test, and cleanup.
4. Confirm ALB URL:
   ```bash
   kubectl get ingress practice-node-app-prod -n practice-app-prod -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
   ```

## 11. Teardown / Maintenance
- Use **terraform-destroy.yml** or run `terraform destroy` locally with the confirmation strings when you need to remove an environment.
- ECR cleanup runs automatically in both deploy workflows, but you can also manage tags manually via the AWS console.

## Where to Go Next
- `docs/INFRASTRUCTURE.md` – deeper Terraform reference.
- `docs/KUBERNETES.md` – manifest details and kubectl tips.
- `docs/CICD.md` – workflow catalog and release strategy.

Keep this runbook in sync with any pipeline or infrastructure changes.
