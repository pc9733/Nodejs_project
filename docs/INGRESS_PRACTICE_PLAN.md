# Ingress Practice Plan

Come back to this doc whenever Ingress feels confusing. Work **in order** — each phase builds on the last.

---

## What you are building (end goal)

A small **multi-page site** behind **one ALB**:

| URL (path-based) | Page | What it shows |
|---|---|---|
| `http://<alb>/` | **Intro** | Welcome + link to About |
| `http://<alb>/about` | **About** | Second page (clickable from intro) |
| `/images/logo.svg` | **Static file** | Image in `node-app/public/images/` |

Optional second app (nginx) on same ALB:

| URL | App |
|---|---|
| `http://<alb>/nginx` | nginx welcome (from `deployment-2`) |

Later: same thing with **hostnames** (`app1.local`, `app2.local`).

---

## Mental model (read this when lost)

```
Browser
   │
   ▼
ALB  ←── Ingress rules (path or host)
   │
   ▼
Service (ClusterIP)  ←── stable name inside cluster
   │
   ▼
Pod(s)  ←── your app containers
```

| Object | Job | Analogy |
|---|---|---|
| **Pod** | Runs containers | The actual app process |
| **Service** | Stable IP/DNS to pods | Internal phone number |
| **Ingress** | HTTP routing rules | Receptionist / URL map |
| **ALB** | AWS load balancer | Building front door |
| **LoadBalancer Service** | Skips Ingress, creates NLB/ELB per Service | Extra door (avoid for practice) |

**Rule:** For Ingress practice, Services should be **ClusterIP**, not LoadBalancer.

---

## Networking checklist (AWS side)

Before Ingress exercises, confirm:

```bash
# 1. Cluster reachable
aws eks update-kubeconfig --name practice-node-app-prod --region us-east-1
kubectl get nodes

# 2. ALB controller running
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# 3. After Ingress apply — get URL
kubectl get ingress -A
```

| Need | Already in this project? |
|---|---|
| VPC + public/private subnets | ✅ Terraform |
| Subnet tags for ALB | ✅ VPC module |
| AWS Load Balancer Controller | ✅ Terraform Helm |
| ALB IAM permissions | ✅ `infra/iam-policy-alb.json` |
| Internet-facing ALB | ✅ Ingress annotation |
| DNS for host-based routing | ❌ use `/etc/hosts` or `curl -H Host:` for practice |
| HTTPS | ❌ optional later (ACM cert) |

**No new Terraform required** for Ingress practice.

---

## App structure (multi-page + images)

Files live in `node-app/public/`:

```
node-app/public/
├── index.html      # Intro page (/)
├── about.html      # Second page (/about)
└── images/
    └── logo.svg    # Served at /images/logo.svg
```

Server routes (after Phase 2 code change):

| Path | File |
|---|---|
| `/` | `public/index.html` |
| `/about` | `public/about.html` |
| `/images/*` | files under `public/images/` |
| `/health` | JSON (for ALB health check — keep this!) |

---

## Phase 0 — Baseline (15 min)

**Goal:** Know what is running today.

```bash
kubectl get pods,svc,ingress -n practice-app-prod
kubectl get pods,svc,ingress -n practice-app-prod-2
```

| Namespace | App | How exposed today |
|---|---|---|
| `practice-app-prod` | Node API | Ingress (ALB) + LoadBalancer Service |
| `practice-app-prod-2` | nginx | NLB + Ingress (redundant — pick one later) |

**Write down your ALB DNS:**
```bash
kubectl get ingress practice-node-app-prod -n practice-app-prod \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}{"\n"}'
```

✅ Done when: you can `curl http://<alb>/health` and get `200`.

---

## Phase 1 — Understand one Ingress (20 min)

**Goal:** Read the manifest; don't change anything yet.

Open: `k8s/environments/prod/all-in-one.yaml` (Ingress section)

Key fields:

```yaml
annotations:
  kubernetes.io/ingress.class: "alb"           # use AWS ALB controller
  alb.ingress.kubernetes.io/scheme: internet-facing
  alb.ingress.kubernetes.io/target-type: ip     # traffic to pod IPs
  alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}]'
  alb.ingress.kubernetes.io/healthcheck-path: "/health"

spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: practice-node-app-prod   # must match Service name
            port:
              number: 80                 # Service port, not container port
```

**Confusion fix:**

| Question | Answer |
|---|---|
| Service port 80 but app listens 3000? | Service maps `80 → 3000` in `all-in-one.yaml` |
| Ingress vs Service? | Ingress = external URL rules; Service = internal routing to pods |
| Why no hostname? | `*` catches all hosts — fine for practice |

✅ Done when: you can explain each annotation without looking.

---

## Phase 2 — Multi-page app (30 min)

**Goal:** Intro + About + image on the same app.

### 2a. Files already scaffolded

- `node-app/public/index.html` — intro with link to `/about`
- `node-app/public/about.html` — second page
- `node-app/public/images/logo.svg` — sample image

### 2b. Update server (when ready)

Add static file serving to `node-app/server.js` for:
- `GET /` → index.html
- `GET /about` → about.html
- `GET /images/*` → static files
- Keep `GET /health` for ALB

### 2c. Build & deploy

```bash
# Option A: CI — merge to main, run Deploy to Production
# Option B: local
cd node-app
docker build -t practice-node-app-prod .
# tag, push to ECR, kubectl set image ...
```

### 2d. Test

```bash
ALB=<your-alb-dns>
curl -s http://$ALB/ | head -5          # intro HTML
curl -s http://$ALB/about | head -5     # about HTML
curl -sI http://$ALB/images/logo.svg     # 200 image
curl http://$ALB/health                  # still works
```

✅ Done when: browser shows intro → click About → image loads at `/images/logo.svg`.

---

## Phase 3 — Path-based: two apps, one ALB (45 min)

**Goal:** One ALB, multiple paths.

```
http://<alb>/         → Node app (intro/about/images)
http://<alb>/nginx    → nginx (deployment-2)
```

### Steps

1. Change `practice-node-app-prod` Service to **ClusterIP** (remove LoadBalancer).
2. Change `deployment-2` Service to **ClusterIP** (remove NLB).
3. Add **same group** to both Ingress objects:

```yaml
metadata:
  annotations:
    alb.ingress.kubernetes.io/group.name: practice-apps
```

4. Main Ingress — path `/` → node service.
5. Second Ingress — path `/nginx` → nginx service.

Example second Ingress path rule:

```yaml
- path: /nginx
  pathType: Prefix
  backend:
    service:
      name: practice-node-app-prod-2
      port:
        number: 80
```

6. Fix nginx health check: `healthcheck-path: "/"` (not `/health`).

### Test

```bash
curl http://$ALB/
curl http://$ALB/about
curl http://$ALB/nginx/
```

✅ Done when: one ALB DNS, both apps reachable on different paths.

**Stuck?** Check:
```bash
kubectl describe ingress -A
kubectl get ingress -A -o wide
```

---

## Phase 4 — Host-based: two URLs, one ALB (30 min)

**Goal:** Different hostnames, same ALB.

| Host | App |
|---|---|
| `app1.practice.local` | Node multi-page app |
| `app2.practice.local` | nginx |

### Ingress rules

```yaml
# App 1
spec:
  rules:
  - host: app1.practice.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: practice-node-app-prod
            port:
              number: 80

# App 2
spec:
  rules:
  - host: app2.practice.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: practice-node-app-prod-2
            port:
              number: 80
```

Both need: `alb.ingress.kubernetes.io/group.name: practice-apps`

### Test without buying a domain

```bash
curl -H "Host: app1.practice.local" http://$ALB/
curl -H "Host: app2.practice.local" http://$ALB/
```

Or `/etc/hosts`:
```
<alb-ip>  app1.practice.local  app2.practice.local
```

✅ Done when: same ALB, different Host headers → different apps.

---

## Phase 5 — HTTPS (optional, later)

Only when you have a real domain + ACM certificate in `us-east-1`.

```yaml
alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-1:ACCOUNT:certificate/ID
alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80,"HTTPS":443}]'
```

---

## Troubleshooting cheat sheet

| Symptom | Check |
|---|---|
| Ingress has no ADDRESS | `kubectl describe ingress <name> -n <ns>` — IAM? controller pods? |
| 502 / unhealthy targets | Health check path wrong (`/health` vs `/`) |
| curl hangs | ALB `internal` not `internet-facing` |
| Wrong app served | Path order — longer/specific paths first |
| `kubectl get svc` empty | Wrong namespace — use `-n practice-app-prod` |
| ImagePullBackOff | ECR tag — use `main-<sha>` not `latest` |
| CreateContainerConfigError | ExternalSecret / SSM params missing |

**Debug commands:**
```bash
kubectl get ingress,svc,endpoints -n <namespace>
kubectl describe ingress <name> -n <namespace>
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller --tail=30
```

---

## Files map (this repo)

| File | Purpose |
|---|---|
| `k8s/environments/prod/all-in-one.yaml` | Main prod app + Ingress |
| `k8s/environments/prod/deployment-2.yml` | nginx practice app |
| `k8s/environments/prod/ingress-shared.yaml` | *(Phase 3)* combined path routing |
| `node-app/public/` | Intro, About, images |
| `node-app/server.js` | App + `/health` |
| `infra/iam-policy-alb.json` | ALB controller permissions |
| `docs/WORKFLOWS.md` | How to deploy via CI |

---

## Progress tracker

Copy and tick as you go:

```
[ ] Phase 0 — Baseline: ALB DNS works, /health returns 200
[ ] Phase 1 — Read & understand Ingress manifest
[ ] Phase 2 — Intro + About + /images/logo.svg in browser
[ ] Phase 3 — Path routing: / and /nginx on one ALB
[ ] Phase 4 — Host routing: app1.local / app2.local
[ ] Phase 5 — HTTPS (optional)
```

---

## When to stop and re-read this doc

- Mixed up Ingress vs Service vs LoadBalancer
- Created a second ALB by accident (forgot `group.name`)
- curl works on NLB but not ALB (or vice versa)
- Health checks failing after adding nginx
- Don't know which namespace to `kubectl apply` into

**Default answer:** Ingress + ClusterIP Service + one `group.name` = one ALB, many URLs.
