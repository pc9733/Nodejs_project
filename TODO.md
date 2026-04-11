# DevOps Learning & Implementation TODO

**Project**: Practice Node.js App - EKS Infrastructure
**Purpose**: Learning modern DevOps practices and building portfolio
**Last Updated**: 2026-04-05

---

## 🔴 CRITICAL - Fix Immediately

- [ ] **Fix Cluster Autoscaler IAM Role**
  - [ ] Replace `<ACCOUNT_ID>` placeholder in `k8s/addons/cluster-autoscaler.yaml:18`
  - [ ] Add IAM role resource in `infra/modules/eks/main.tf`
  - [ ] Add IAM policy for autoscaler permissions
  - [ ] Output role ARN from Terraform
  - [ ] Test: `kubectl -n kube-system logs deploy/cluster-autoscaler`
  - **Files**: `infra/modules/eks/main.tf`, `k8s/addons/cluster-autoscaler.yaml`
  - **Docs**: [AWS Cluster Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler/cloudprovider/aws)

- [ ] **Add ASG Tags for Auto-Discovery**
  - [ ] Update `aws_eks_node_group` resource with autoscaler tags
  - [ ] Apply Terraform changes
  - [ ] Manually tag ASG if needed: `aws autoscaling create-or-update-tags`
  - [ ] Verify: Check ASG tags in AWS console
  - **Files**: `infra/modules/eks/main.tf`

---

## 🟡 PHASE 1: Core Infrastructure (Weeks 1-2)

### Terraform Improvements
- [ ] **Add Terragrunt for DRY Configuration**
  - [ ] Install Terragrunt: `brew install terragrunt` (or equivalent)
  - [ ] Create root `terragrunt.hcl` with remote state config
  - [ ] Create environment-specific `terragrunt.hcl` files
  - [ ] Refactor dev environment to use Terragrunt
  - [ ] Refactor prod environment to use Terragrunt
  - [ ] Test: `terragrunt plan` in both environments
  - **Learning**: Code reusability, advanced Terraform patterns
  - **Docs**: https://terragrunt.gruntwork.io/

- [ ] **Add Terraform State Backend Replication**
  - [ ] Create S3 replica bucket in us-west-2
  - [ ] Add replication configuration
  - [ ] Test failover scenario
  - **Files**: New `infra/modules/state-backend/`
  - **Learning**: Disaster recovery, business continuity

- [ ] **Add Terratest for Infrastructure Testing**
  - [ ] Install Go: `brew install go`
  - [ ] Create `test/` directory
  - [ ] Write test for EKS cluster creation
  - [ ] Write test for VPC networking
  - [ ] Add to CI/CD pipeline
  - **Files**: `test/eks_test.go`, `test/vpc_test.go`
  - **Learning**: Go programming, IaC testing
  - **Docs**: https://terratest.gruntwork.io/

### Security Hardening
- [ ] **Add OPA Gatekeeper for Policy Enforcement**
  - [ ] Install Gatekeeper: `kubectl apply -f gatekeeper.yaml`
  - [ ] Create policy: Require resource limits
  - [ ] Create policy: Block privileged containers
  - [ ] Create policy: Require labels (env, team, app)
  - [ ] Test violations
  - **Files**: `k8s/policies/`
  - **Learning**: Policy as Code, Kubernetes security
  - **Docs**: https://open-policy-agent.github.io/gatekeeper/

- [ ] **Restrict EKS Public Access (Dev)**
  - [ ] Get your public IP: `curl ifconfig.me`
  - [ ] Update `infra/environments/dev/main.tf` with specific CIDR
  - [ ] Apply changes
  - [ ] Test connectivity
  - **Files**: `infra/environments/dev/main.tf`

- [ ] **Add Pod Security Standards**
  - [ ] Create `PodSecurityPolicy` or `SecurityContext`
  - [ ] Apply to cluster-autoscaler
  - [ ] Apply to application deployments
  - **Files**: `k8s/addons/cluster-autoscaler.yaml`, `k8s/environments/*/`
  - **Docs**: https://kubernetes.io/docs/concepts/security/pod-security-standards/

---

## 🟢 PHASE 2: Observability Stack (Weeks 3-4)

### Monitoring & Logging
- [ ] **Deploy Prometheus + Grafana Stack**
  - [ ] Add Helm repo: `prometheus-community`
  - [ ] Create values file for kube-prometheus-stack
  - [ ] Deploy via Helm or Terraform helm_release
  - [ ] Configure persistent storage (20Gi)
  - [ ] Access Grafana UI: `kubectl port-forward`
  - [ ] Import dashboards: Cluster Autoscaler, Node metrics, Pod metrics
  - **Files**: `k8s/observability/kube-prometheus-stack.yaml`
  - **Learning**: PromQL, Grafana dashboards, metrics-based alerting
  - **Docs**: https://prometheus.io/docs/

- [ ] **Configure Loki for Log Aggregation**
  - [ ] Deploy Loki stack
  - [ ] Configure log retention (7 days)
  - [ ] Add Promtail daemonset
  - [ ] Create log queries in Grafana
  - **Files**: `k8s/observability/loki-stack.yaml`
  - **Learning**: Centralized logging, LogQL
  - **Docs**: https://grafana.com/docs/loki/

- [ ] **Add Custom Application Metrics**
  - [ ] Instrument Node.js app with Prometheus client
  - [ ] Expose `/metrics` endpoint
  - [ ] Create ServiceMonitor for app
  - [ ] Build Grafana dashboard for app metrics
  - **Files**: `node-app/server.js`, `k8s/observability/servicemonitor.yaml`
  - **Learning**: Application instrumentation, RED/USE methodology

- [ ] **Set Up Alerting Rules**
  - [ ] Create PrometheusRule for cluster autoscaler
  - [ ] Create PrometheusRule for node pressure
  - [ ] Create PrometheusRule for pod restarts
  - [ ] Configure Alertmanager (Slack/email)
  - **Files**: `k8s/observability/prometheus-rules.yaml`
  - **Learning**: SRE practices, on-call management

### Distributed Tracing
- [ ] **Deploy Jaeger for Tracing**
  - [ ] Deploy Jaeger operator
  - [ ] Deploy Jaeger instance
  - [ ] Configure OpenTelemetry collector
  - [ ] Instrument Node.js app with OTEL SDK
  - [ ] View traces in Jaeger UI
  - **Files**: `k8s/observability/jaeger.yaml`
  - **Learning**: Distributed tracing, microservices observability
  - **Docs**: https://www.jaegertracing.io/

---

## 🔵 PHASE 3: GitOps & CI/CD (Weeks 5-6)

### GitOps Implementation
- [ ] **Deploy ArgoCD**
  - [ ] Create `argocd` namespace
  - [ ] Install ArgoCD: `kubectl apply -n argocd -f install.yaml`
  - [ ] Expose UI via LoadBalancer or Ingress
  - [ ] Get admin password: `kubectl get secret`
  - [ ] Login via CLI: `argocd login`
  - **Files**: `k8s/argocd/install.sh`
  - **Learning**: GitOps principles, declarative deployments
  - **Docs**: https://argo-cd.readthedocs.io/

- [ ] **Create ArgoCD Applications**
  - [ ] App: practice-node-app-dev (auto-sync enabled)
  - [ ] App: practice-node-app-prod (manual sync)
  - [ ] App: observability stack
  - [ ] App: cluster addons (autoscaler, etc.)
  - [ ] Configure notifications (Slack)
  - **Files**: `k8s/argocd/applications/`
  - **Learning**: App-of-apps pattern, sync strategies

- [ ] **Compare with Flux CD (Optional)**
  - [ ] Deploy Flux to separate namespace
  - [ ] Create GitRepository and Kustomization resources
  - [ ] Compare: ArgoCD UI vs Flux declarative
  - [ ] Document pros/cons of each
  - **Files**: `k8s/flux/`, `docs/GITOPS_COMPARISON.md`
  - **Learning**: Tool evaluation, architectural decisions

### CI/CD Enhancements
- [ ] **Add Semantic Release**
  - [ ] Install `semantic-release` npm package
  - [ ] Create `.releaserc.json` config
  - [ ] Configure commit message linting
  - [ ] Add GitHub release workflow
  - [ ] Test with fix/feat/breaking commits
  - **Files**: `.releaserc.json`, `.github/workflows/release.yml`
  - **Learning**: Semantic versioning, automated releases
  - **Docs**: https://semantic-release.gitbook.io/

- [ ] **Add Pre-commit Hooks**
  - [ ] Install pre-commit: `pip install pre-commit`
  - [ ] Create `.pre-commit-config.yaml`
  - [ ] Add hooks: terraform fmt, tflint, shellcheck
  - [ ] Install hooks: `pre-commit install`
  - **Files**: `.pre-commit-config.yaml`
  - **Learning**: Code quality, shift-left security

- [ ] **Add DORA Metrics Tracking**
  - [ ] Choose tool: Sleuth, LinearB, or custom
  - [ ] Instrument deployment workflows
  - [ ] Track: Deployment frequency, lead time, MTTR, change failure rate
  - [ ] Create dashboard
  - **Files**: `.github/workflows/dora-metrics.yml`
  - **Learning**: DevOps metrics, performance measurement

---

## 🟣 PHASE 4: Advanced Topics (Weeks 7-8)

### Cost Optimization
- [ ] **Deploy Kubecost**
  - [ ] Install Kubecost: `helm install kubecost`
  - [ ] Configure AWS integration for accurate pricing
  - [ ] Analyze: Cost by namespace, deployment, label
  - [ ] Set up cost alerts
  - **Files**: `k8s/observability/kubecost.yaml`
  - **Learning**: FinOps, cloud cost management
  - **Docs**: https://www.kubecost.com/

- [ ] **Implement Karpenter (Cluster Autoscaler Alternative)**
  - [ ] Deploy Karpenter controller
  - [ ] Create Provisioner with Spot + On-Demand mix
  - [ ] Configure consolidation (bin packing)
  - [ ] Compare cost savings vs Cluster Autoscaler
  - [ ] Document migration path
  - **Files**: `k8s/addons/karpenter/`, `docs/KARPENTER_VS_CA.md`
  - **Learning**: Advanced scheduling, spot instances, cost optimization
  - **Docs**: https://karpenter.sh/

- [ ] **Add Spot Instance Strategy**
  - [ ] Update node group to use SPOT capacity type
  - [ ] Configure spot interruption handler
  - [ ] Test node replacement scenarios
  - [ ] Calculate cost savings
  - **Files**: `infra/modules/eks/main.tf`
  - **Learning**: EC2 spot instances, cost-performance tradeoffs

### Service Mesh
- [ ] **Deploy Istio**
  - [ ] Install istioctl
  - [ ] Deploy Istio operator: `istioctl install`
  - [ ] Enable sidecar injection for namespace
  - [ ] Create VirtualService for canary routing
  - [ ] Configure mTLS (strict mode)
  - [ ] View service graph in Kiali
  - **Files**: `k8s/istio/`
  - **Learning**: Service mesh architecture, mTLS, advanced traffic management
  - **Docs**: https://istio.io/latest/docs/

- [ ] **Implement Circuit Breaking**
  - [ ] Create DestinationRule with connection pool settings
  - [ ] Test with load generator (k6, hey)
  - [ ] Monitor circuit breaker metrics
  - **Files**: `k8s/istio/destination-rules.yaml`
  - **Learning**: Resilience patterns, failure isolation

### Chaos Engineering
- [ ] **Deploy Chaos Mesh**
  - [ ] Install Chaos Mesh operator
  - [ ] Create pod-kill experiment (random pod every 10m)
  - [ ] Create network-delay experiment (50ms latency)
  - [ ] Create stress-test experiment (CPU/memory pressure)
  - [ ] Verify app resilience via metrics
  - **Files**: `k8s/chaos/experiments.yaml`
  - **Learning**: Resilience testing, SRE practices, game days
  - **Docs**: https://chaos-mesh.org/

### Backup & Disaster Recovery
- [ ] **Deploy Velero**
  - [ ] Create S3 bucket for backups
  - [ ] Install Velero CLI
  - [ ] Install Velero server components
  - [ ] Create backup schedule (daily at 1 AM)
  - [ ] Test restore to new namespace
  - [ ] Document DR runbook
  - **Files**: `k8s/velero/`, `docs/DISASTER_RECOVERY.md`
  - **Learning**: BCDR, RTO/RPO, compliance
  - **Docs**: https://velero.io/

---

## 🟠 PHASE 5: Production Readiness (Weeks 9-10)

### Security Scanning
- [ ] **Add Trivy Operator (Runtime Scanning)**
  - [ ] Deploy Trivy operator
  - [ ] Configure scanning schedule
  - [ ] View vulnerability reports: `kubectl get vulnerabilityreports`
  - [ ] Integrate with CI/CD (fail on HIGH/CRITICAL)
  - **Files**: `k8s/security/trivy-operator.yaml`
  - **Learning**: Runtime security, compliance scanning

- [ ] **Deploy Falco for Runtime Threat Detection**
  - [ ] Install Falco daemonset
  - [ ] Configure custom rules (detect crypto mining, reverse shells)
  - [ ] Integrate alerts with Prometheus/Slack
  - [ ] Test with suspicious activity
  - **Files**: `k8s/security/falco-rules.yaml`
  - **Learning**: SIEM, threat detection, SOC operations
  - **Docs**: https://falco.org/

- [ ] **Implement Network Policies**
  - [ ] Create default deny-all policy
  - [ ] Allow: app → database (specific port)
  - [ ] Allow: app → internet (egress)
  - [ ] Deny: cross-namespace traffic
  - [ ] Test with netshoot pod
  - **Files**: `k8s/network-policies/`
  - **Learning**: Zero-trust networking, microsegmentation

### Multi-Cluster Management (Optional)
- [ ] **Deploy Cluster API (CAPI)**
  - [ ] Install clusterctl
  - [ ] Create management cluster
  - [ ] Provision workload cluster via YAML
  - [ ] Test cluster lifecycle (create, upgrade, delete)
  - **Files**: `k8s/cluster-api/`
  - **Learning**: Cluster as cattle, declarative cluster management
  - **Docs**: https://cluster-api.sigs.k8s.io/

- [ ] **Implement Crossplane (Alternative to Terraform)**
  - [ ] Install Crossplane operator
  - [ ] Configure AWS provider
  - [ ] Create EKS cluster via Crossplane CRD
  - [ ] Compare: Terraform vs Crossplane
  - [ ] Document use cases for each
  - **Files**: `k8s/crossplane/`, `docs/TERRAFORM_VS_CROSSPLANE.md`
  - **Learning**: Kubernetes operators, cloud-native IaC

---

## 📊 PROJECT MANAGEMENT OPTIONS

### Option 1: GitHub Projects (FREE, Integrated)
- **Pros**: Free, built into GitHub, good for solo/small teams
- **Cons**: Less features than Jira, basic reporting
- **Setup**:
  - Go to repo → Projects tab → New project
  - Link this TODO.md
  - Use "Status" field: Backlog, In Progress, Done
  - Add "Priority" and "Phase" custom fields

### Option 2: Jira Free Tier
- **Limits**: Up to 10 users, 2GB storage
- **Pros**: Industry standard, great for learning, advanced features
- **Cons**: Overkill for solo project
- **Setup**:
  ```bash
  # Create account at https://www.atlassian.com/software/jira/free
  # Create project: Kanban or Scrum
  # Import issues from this TODO.md
  ```

### Option 3: Linear (FREE for solo)
- **Pros**: Modern UI, keyboard shortcuts, fast
- **Cons**: Less enterprise features than Jira
- **URL**: https://linear.app/

### Option 4: Trello (FREE)
- **Pros**: Visual, simple, good for Kanban
- **Cons**: Less suitable for DevOps workflows
- **URL**: https://trello.com/

### Recommendation for This Project:
**Use GitHub Projects** → Easy to sync with this TODO.md, no context switching

---

## 📚 DOCUMENTATION TO CREATE

- [ ] `docs/ARCHITECTURE.md` - High-level architecture diagrams
- [ ] `docs/GITOPS_COMPARISON.md` - ArgoCD vs Flux analysis
- [ ] `docs/COST_ANALYSIS.md` - Before/after Karpenter, Spot instances
- [ ] `docs/DISASTER_RECOVERY.md` - DR procedures, RTO/RPO
- [ ] `docs/SECURITY_HARDENING.md` - Security controls implemented
- [ ] `docs/OBSERVABILITY.md` - Metrics, logs, traces guide
- [ ] `docs/LEARNING_NOTES.md` - Your learning journey, gotchas
- [ ] `docs/INTERVIEW_TALKING_POINTS.md` - Key achievements for resume

---

## 🎯 PORTFOLIO ENHANCEMENTS

- [ ] Create architecture diagrams (draw.io or Mermaid)
- [ ] Write blog post: "Building Production-Ready EKS with Terraform"
- [ ] Record demo video: GitOps deployment walkthrough
- [ ] Add CI/CD status badges to README.md
- [ ] Create cost savings report with graphs
- [ ] Share on LinkedIn with lessons learned
- [ ] Submit to DevOps communities (r/devops, DEV.to)

---

## 🏆 INTERVIEW PREPARATION

### Key Talking Points from This Project:
1. **IaC**: Terraform modules, state management, testing
2. **GitOps**: ArgoCD, declarative deployments, drift detection
3. **Observability**: Prometheus, Grafana, distributed tracing
4. **Security**: OPA policies, Falco, network policies, IRSA
5. **Cost Optimization**: Karpenter, spot instances, Kubecost analysis
6. **CI/CD**: GitHub Actions, semantic release, DORA metrics
7. **Chaos Engineering**: Resilience testing, failure injection
8. **DR**: Velero backups, multi-region strategy

### Metrics to Quantify:
- Deployment frequency: X deploys/day
- Lead time: Commit to prod in X minutes
- Cost savings: Y% reduction with Karpenter/Spot
- MTTR: Mean time to recovery = Z minutes
- Test coverage: N% infrastructure tested

---

## 🔄 MAINTENANCE & CLEANUP

### Weekly Tasks
- [ ] Review and update this TODO.md
- [ ] Check AWS costs (set budget alert: $50/month)
- [ ] Update Terraform modules to latest versions
- [ ] Review Dependabot PRs for security updates
- [ ] Check for Kubernetes CVEs

### Monthly Tasks
- [ ] Rotate AWS access keys
- [ ] Review and prune ECR images (keep last 10)
- [ ] Update Kubernetes version (EKS managed)
- [ ] Review and optimize resource requests/limits
- [ ] Generate cost report and trends

### Teardown (When Finished)
- [ ] Export all metrics/dashboards
- [ ] Screenshot important UIs for portfolio
- [ ] Document lessons learned
- [ ] Run `terraform destroy` for all environments
- [ ] Delete S3 buckets (state, backups, logs)
- [ ] Remove GitHub secrets
- [ ] Archive repository with final notes

---

## 📞 RESOURCES & SUPPORT

- **AWS Documentation**: https://docs.aws.amazon.com/eks/
- **Kubernetes Docs**: https://kubernetes.io/docs/
- **CNCF Landscape**: https://landscape.cncf.io/
- **DevOps Roadmap**: https://roadmap.sh/devops
- **Community**: r/devops, r/kubernetes, CNCF Slack

---

**Next Step**: Choose a task from CRITICAL section and mark it in progress!
**Tip**: Use GitHub Projects to sync this TODO with a Kanban board.
