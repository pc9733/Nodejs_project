# Node.js EKS Practice Project

**Node app → GitHub Actions → ECR → EKS**

Only two environments: **dev** and **prod**.  
Ignore everything under `archive/` — those are old leftovers.

---

## Start here: what do you want?

Answer the questions top → bottom. Use **only** the command in that box.

### 1) Do you have a cluster yet?

```
No cluster / starting from zero?
  └─ YES →  cd infra && ./create-dev.sh
            (prod: ./create-prod.sh)

Done practicing / stop AWS bills?
  └─ YES →  cd infra && ./destroy-dev-simple.sh
            (prod: ./destroy-prod-simple.sh)

Already have a cluster?
  └─ YES →  go to question 2
```

| Use this | Don’t use this |
|---|---|
| `infra/create-*.sh` / `destroy-*.sh` | Root `infra/*.tf` (archived), random Terraform in other folders |

---

### 2) Are secrets in AWS and wired to Kubernetes?

```
Need to CREATE secret values in AWS (SSM)?
  └─ YES →  ./scripts/setup-parameter-store.sh
             (run once per env; interactive)

Need to CONNECT the cluster to those secrets?
  └─ YES →  # on DEV cluster:
             kubectl apply -f k8s/addons/external-secrets-dev.yaml

             # on PROD cluster:
             kubectl apply -f k8s/addons/external-secrets-prod.yaml

Secrets already working (ExternalSecret = SecretSynced)?
  └─ YES →  go to question 3
```

| Use this | Don’t use this |
|---|---|
| `external-secrets-dev.yaml` or `…-prod.yaml` | `external-secrets-config.yaml` (pointer only — do not apply) |
| Matching file for the cluster you’re on | Dev file on prod cluster (or vice versa) |

---

### 3) Do you want to run / update the app?

```
First deploy on this cluster (or fix manifests by hand)?
  └─ YES →  # DEV:
             kubectl apply -f k8s/environments/dev/all-in-one.yaml

             # PROD:
             kubectl apply -f k8s/environments/prod/all-in-one.yaml

Normal coding — ship a new build to DEV?
  └─ YES →  1. Commit on feature/*
            2. Open PR → merge to develop
            3. Wait: Node CI → Auto Deploy to Development
            (no kubectl needed)

Ship a new build to PROD?
  └─ YES →  1. PR develop → merge to main
            2. GitHub → Actions → "Deploy to Production"
            3. Type the confirmation phrase
            (do NOT rely on auto-deploy for prod)
```

| Situation | Tool |
|---|---|
| First-time / manual fix | `kubectl apply` + `all-in-one.yaml` |
| Everyday code change → **dev** | Git merge to `develop` |
| Release → **prod** | Manual workflow `deploy-prod.yml` |
| Only change AWS (VPC/EKS/size) | Edit `infra/` → PR → **Terraform Apply** workflow |

---

### 4) Changing infrastructure (not app code)?

```
Edited files under infra/?
  └─ YES →  1. PR to main (terraform-plan comments on the PR)
            2. Actions → "Terraform Apply" → pick dev or prod

Just create/destroy whole env?
  └─ YES →  use create-*.sh / destroy-*.sh (question 1)
            not required to use GitHub Actions for that
```

---

## One cheat sheet (print this)

| Goal | Command / action | When |
|---|---|---|
| Create **dev** AWS | `cd infra && ./create-dev.sh` | Once / rebuild |
| Create **prod** AWS | `cd infra && ./create-prod.sh` | Once / rebuild |
| Destroy **dev** | `cd infra && ./destroy-dev-simple.sh` | Done practicing |
| Destroy **prod** | `cd infra && ./destroy-prod-simple.sh` | Done practicing |
| Put secrets in SSM | `./scripts/setup-parameter-store.sh` | Once per env |
| Link SSM → cluster (dev) | `kubectl apply -f k8s/addons/external-secrets-dev.yaml` | After cluster exists |
| Link SSM → cluster (prod) | `kubectl apply -f k8s/addons/external-secrets-prod.yaml` | After cluster exists |
| Install / refresh app (dev) | `kubectl apply -f k8s/environments/dev/all-in-one.yaml` | First deploy or manifest edit |
| Install / refresh app (prod) | `kubectl apply -f k8s/environments/prod/all-in-one.yaml` | First deploy or manifest edit |
| New code → **dev** | Merge to `develop` | Every feature |
| New code → **prod** | Actions → Deploy to Production | Releases |
| Terraform change | Actions → Terraform Apply | Infra edits |
| Look at pods | `kubectl get pods -n practice-app-dev` | Debugging |
| Hit the API locally | `kubectl port-forward svc/practice-node-app-dev 3000:80 -n practice-app-dev` | Debugging |

---

## Layers (so you don’t mix tools)

```
┌─────────────────────────────────────────────────────────┐
│  AWS cloud (VPC, EKS, ECR, IAM)                         │
│  → Terraform scripts in infra/                          │
├─────────────────────────────────────────────────────────┤
│  Cluster addons (ALB controller, External Secrets)      │
│  → Installed by Terraform automatically                 │
│  → You only apply ClusterSecretStore YAML (addons/)     │
├─────────────────────────────────────────────────────────┤
│  Your Node app (Deployment, Service, Ingress, secrets)  │
│  → k8s/environments/*/all-in-one.yaml                   │
│  → OR GitHub Actions after you merge                    │
├─────────────────────────────────────────────────────────┤
│  App source code                                        │
│  → node-app/  (edit here, push via Git)                 │
└─────────────────────────────────────────────────────────┘
```

**Rule:**  
- Cloud problem → `infra/` scripts or Terraform workflows  
- Secrets problem → `scripts/setup-parameter-store.sh` + `k8s/addons/external-secrets-*.yaml`  
- App/runtime problem → `all-in-one.yaml` or CI deploy  
- Code change → Git branches, not Terraform  

---

## First-time path (dev) — copy/paste order

```bash
cd infra && ./create-dev.sh

kubectl get nodes
kubectl get deploy,svc -n external-secrets          # webhook Service must exist

cd .. && ./scripts/setup-parameter-store.sh

kubectl apply -f k8s/addons/external-secrets-dev.yaml
kubectl apply -f k8s/environments/dev/all-in-one.yaml

kubectl get clustersecretstore                      # Ready=True
kubectl get externalsecret -n practice-app-dev      # SecretSynced
kubectl get pods -n practice-app-dev                # Running

kubectl port-forward svc/practice-node-app-dev 3000:80 -n practice-app-dev
# http://localhost:3000/health
```

After that, **stop using kubectl for routine deploys** — merge to `develop` instead.

---

## Branches (code only)

```
feature/* ──PR──▶ develop ──PR──▶ main
                    │               │
              auto → DEV EKS    you run → PROD EKS
```

| Branch | Use when |
|---|---|
| `feature/*` | Writing code / tests |
| `develop` | “Put this on the dev cluster” |
| `main` | “This is ready for prod” (still must click Deploy) |

---

## Names you will see

| | Dev | Prod |
|---|---|---|
| Cluster | `practice-node-app-dev` | `practice-node-app-prod` |
| Namespace | `practice-app-dev` | `practice-app-prod` |
| Manifest | `k8s/environments/dev/all-in-one.yaml` | `k8s/environments/prod/all-in-one.yaml` |
| SecretStore file | `k8s/addons/external-secrets-dev.yaml` | `k8s/addons/external-secrets-prod.yaml` |

Always check: `kubectl config current-context` matches the env you’re applying.

---

## Prerequisites

AWS CLI (`us-east-1`), Terraform ≥ 1.0, kubectl, Docker (optional locally).  
GitHub repo secrets: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`.

---

## Common “wrong tool” mistakes

| You did… | Wrong because… | Do this instead |
|---|---|---|
| Applied `external-secrets-config.yaml` | It’s not a real manifest | Use `-dev.yaml` or `-prod.yaml` |
| Applied prod YAML on the dev cluster | Wrong cluster / namespaces | Match file to context |
| Used Terraform to change app image | Infra ≠ app deploys | Merge to `develop` or `kubectl set image` / CI |
| Used kubectl every push | CI already deploys develop | Merge to `develop` |
| Expected prod auto-deploy on `main` | Prod is manual on purpose | Run **Deploy to Production** |

---

## More detail (only if needed)

| Doc | Open when… |
|---|---|
| [docs/WORKFLOWS.md](docs/WORKFLOWS.md) | Which of the 6 GitHub Actions to click |
| [docs/PARAMETER_STORE.md](docs/PARAMETER_STORE.md) | Secrets broken / ESO webhook missing |
| [infra/README.md](infra/README.md) | Terraform module / script details |
| `docs/archive/` | Curiosity only — may be outdated |

---

## Stop costs

```bash
cd infra && ./destroy-dev-simple.sh
```
