# Node.js EKS Practice Project

**Goal:** open this repo → run the steps below → cluster + app running.  
After destroy, run the **same playbook again** — no guessing.

Two environments: **dev** and **prod**. Pick one playbook.

---

## Before you start (once per machine)

| Tool | Check |
|---|---|
| AWS CLI (`us-east-1`) | `aws sts get-caller-identity` |
| Terraform ≥ 1.0 | `terraform version` |
| kubectl | `kubectl version --client` |
| Docker (first manual deploy) | `docker version` |
| GitHub secrets (CI/CD only) | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` in repo settings |

Set region once:

```bash
export AWS_REGION=us-east-1
```

---

## Rebuild **prod** from zero

Use this after `./destroy-prod-simple.sh` or the first time.  
**Time:** ~20–30 min (cluster create is the slow part).

### Step 1 — Create cluster

```bash
cd infra
./create-prod.sh          # type: create-production
```

**✅ Pass when:**

```bash
aws eks update-kubeconfig --name practice-node-app-prod --region us-east-1
kubectl get nodes                    # all Ready
kubectl get pods -n external-secrets # all Running
kubectl get svc -n external-secrets  # external-secrets-webhook exists
```

**❌ If external-secrets pods are not Running** → see [docs/PARAMETER_STORE.md](docs/PARAMETER_STORE.md) (ESO webhook section).

---

### Step 2 — Create secrets in AWS (SSM)

From **repo root**:

```bash
./scripts/setup-parameter-store.sh   # choose: 2) Production
```

**✅ Pass when:**

```bash
aws ssm get-parameter --name /practice-node-app-prod/prod/db-password --with-decryption --query Parameter.Name
aws ssm get-parameter --name /practice-node-app-prod/prod/api-key --with-decryption --query Parameter.Name
aws ssm get-parameter --name /practice-node-app-prod/prod/jwt-secret --with-decryption --query Parameter.Name
```

---

### Step 3 — Connect cluster to SSM

```bash
kubectl apply -f k8s/addons/external-secrets-prod.yaml
```

**✅ Pass when:**

```bash
kubectl get clustersecretstore    # STATUS: Ready=True
```

---

### Step 4 — Deploy the app

Prod ECR is **immutable** — do **not** rely on `:latest` alone. Use one of these:

#### Option A — GitHub Actions (recommended)

1. Merge your code to `main`
2. GitHub → **Actions** → **Deploy to Production**
3. Type `deploy-production`

This builds the image, pushes `main-<sha>` to ECR, and updates the deployment.

#### Option B — Manual (local Docker)

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/practice-node-app-prod"
TAG="manual-$(date +%Y%m%d-%H%M)"

aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

cd node-app
docker build -t practice-node-app-prod:$TAG .
docker tag practice-node-app-prod:$TAG $ECR:$TAG
docker push $ECR:$TAG

cd ..
kubectl apply -f k8s/environments/prod/all-in-one.yaml
kubectl set image deployment/practice-node-app-prod \
  node-app=$ECR:$TAG -n practice-app-prod
```

---

### Step 5 — Verify app is healthy

```bash
kubectl get externalsecret -n practice-app-prod   # SecretSynced
kubectl get pods -n practice-app-prod             # 3/3 Running (no ImagePullBackOff)
kubectl rollout status deployment/practice-node-app-prod -n practice-app-prod

ALB=$(kubectl get ingress practice-node-app-prod -n practice-app-prod -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "http://$ALB/health"
curl -sf "http://$ALB/health"    # {"status":"ok"} or similar 200
```

**✅ Done** when `/health` returns 200 and all pods are Running.

| Common failure | Fix |
|---|---|
| `ImagePullBackOff` | No image in ECR — redo Step 4 (use a new tag for prod) |
| `SecretSynced: false` | Redo Steps 2–3; check [docs/PARAMETER_STORE.md](docs/PARAMETER_STORE.md) |
| `/health` times out | Wait 2–3 min for ALB; check `kubectl get ingress` has an ADDRESS |
| Wrong cluster | `kubectl config current-context` must be `practice-node-app-prod` |

---

## Rebuild **dev** from zero

Same idea as prod. Differences noted below.

### Step 1 — Create cluster

```bash
cd infra
./create-dev.sh
```

**✅ Pass when:**

```bash
aws eks update-kubeconfig --name practice-node-app-dev --region us-east-1
kubectl get nodes
kubectl get pods -n external-secrets    # all Running
```

> **Note:** Dev ECR is not created by Terraform. If the repo does not exist yet:
> `aws ecr create-repository --repository-name practice-node-app-dev --region us-east-1`

---

### Step 2 — Secrets

Dev parameters are partly created by Terraform (`infra/environments/dev/parameter-store.tf`).  
To set real values (recommended):

```bash
./scripts/setup-parameter-store.sh   # choose: 1) Development
```

---

### Step 3 — Connect cluster to SSM

```bash
kubectl apply -f k8s/addons/external-secrets-dev.yaml
kubectl get clustersecretstore    # Ready=True
```

---

### Step 4 — Deploy the app

#### Option A — GitHub Actions (routine)

Merge to `develop` → **Node CI** runs → **Auto Deploy to Development** builds and deploys.

#### Option B — Manual (first deploy)

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/practice-node-app-dev"

aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin "${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

cd node-app && docker build -t practice-node-app-dev:latest .
docker tag practice-node-app-dev:latest $ECR:latest
docker push $ECR:latest
cd ..

kubectl apply -f k8s/environments/dev/all-in-one.yaml
```

---

### Step 5 — Verify

```bash
kubectl get externalsecret -n practice-app-dev   # SecretSynced
kubectl get pods -n practice-app-dev             # Running

kubectl port-forward svc/practice-node-app-dev 3000:80 -n practice-app-dev
# http://localhost:3000/health
```

---

## Health checklist (run after every rebuild)

Copy/paste — replace `<env>` with `dev` or `prod`:

```bash
kubectl get nodes
kubectl get pods -n external-secrets
kubectl get clustersecretstore
kubectl get externalsecret -n practice-app-<env>
kubectl get pods -n practice-app-<env>
kubectl get ingress -n practice-app-<env>
```

All green → app layer is fine. If something fails, use the table in the prod Step 5 section above.

---

## Destroy (stop AWS bills)

```bash
cd infra
./destroy-dev-simple.sh      # dev
./destroy-prod-simple.sh     # prod — type: destroy-production
```

After destroy, clusters and apps are gone. **To work again, run the full rebuild playbook** for that env from Step 1.

---

## Routine updates (after first successful deploy)

You do **not** repeat the full playbook for every code change.

| Env | How to ship code |
|---|---|
| **dev** | Merge to `develop` → auto-deploy |
| **prod** | Merge to `main` → Actions → **Deploy to Production** → type `deploy-production` |

### CI/CD workflows (3)

| Workflow | When | What you do |
|---|---|---|
| `node-ci.yml` | Push/PR when `node-app/` changes | Nothing — runs tests |
| `auto-deploy-dev.yml` | After CI passes on push to `develop` | Merge to `develop` |
| `deploy-prod.yml` | Manual only | Actions → Deploy to Production |

Image tags: `develop-<sha>` (dev), `main-<sha>` (prod).

**CI/CD needs:** cluster exists + GitHub AWS secrets set.  
**CI/CD does not:** create/destroy clusters — use `infra/*.sh` for that.

---

## Quick reference

| | Dev | Prod |
|---|---|---|
| Create | `cd infra && ./create-dev.sh` | `cd infra && ./create-prod.sh` |
| Destroy | `./destroy-dev-simple.sh` | `./destroy-prod-simple.sh` |
| Cluster | `practice-node-app-dev` | `practice-node-app-prod` |
| Namespace | `practice-app-dev` | `practice-app-prod` |
| App manifest | `k8s/environments/dev/all-in-one.yaml` | `k8s/environments/prod/all-in-one.yaml` |
| SecretStore | `k8s/addons/external-secrets-dev.yaml` | `k8s/addons/external-secrets-prod.yaml` |
| Practice nginx (optional) | — | `k8s/environments/prod/deployment-2.yml` |

### Infra tweak (existing cluster, not full rebuild)

```bash
cd infra/environments/dev    # or prod
terraform plan && terraform apply
```

### Common mistakes

| Mistake | Do instead |
|---|---|
| Applied prod YAML on dev cluster | Match manifest to `kubectl config current-context` |
| Skipped SSM / SecretStore steps | Always Steps 2–3 before expecting pods to start |
| Prod deploy with only `:latest` | Use **Deploy to Production** or push a unique tag |
| Ran CI/CD with no cluster | Run create script first |
| Changed app image via Terraform | Merge to `develop` or use deploy workflow |

---

## More detail

| Doc | When |
|---|---|
| [docs/PARAMETER_STORE.md](docs/PARAMETER_STORE.md) | Secrets / ExternalSecret not syncing |
| [docs/WORKFLOWS.md](docs/WORKFLOWS.md) | CI/CD quick reference |
| [docs/INGRESS_PRACTICE_PLAN.md](docs/INGRESS_PRACTICE_PLAN.md) | Ingress + multi-page app practice |
| [infra/README.md](infra/README.md) | Terraform layout |
