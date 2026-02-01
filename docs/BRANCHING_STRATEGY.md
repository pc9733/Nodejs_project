# Branching Strategy & Automation Guide

## 🌳 Git Flow Strategy

This project uses a modified Git Flow approach with clear separation between development and production environments.

### **Branch Structure**

```
main                    # Production-ready code
├── develop             # Staging/Integration environment
├── feature/*           # Feature development
├── hotfix/*            # Emergency production fixes
├── release/*           # Release preparation
└── bugfix/*            # Bug fixes
```

## 🔄 Workflow Triggers

### **Development Environment (`deploy-dev.yml`)**

**Triggers:**
- ✅ **Manual ONLY**: Workflow dispatch (select image tag or use latest)

**Purpose:**
- Update the dev EKS cluster only when a build is ready
- Keep the environment stable while feature work lands
- Provide an intentional gate between CI and shared testing space

**Environment:**
- **Cluster**: `practice-node-app-dev`
- **Repository**: `practice-node-app-dev`
- **Namespace**: `practice-app-dev`

### **Production Environment (`deploy-prod.yml`)**

**Triggers:**
- ✅ **Manual ONLY**: Workflow dispatch (with approval)

**Purpose:**
- Production deployments
- Manual control and safety
- No automatic triggers

**Environment:**
- **Cluster**: `practice-node-app-prod`
- **Repository**: `practice-node-app-prod`
- **Namespace**: `practice-app-prod`

### **Production Promotion (`promote-to-prod.yml`)**

**Triggers:**
- ✅ **Manual ONLY**: Workflow dispatch (with approval)

**Purpose:**
- Promote tested code from develop to production
- Controlled release process
- Rollback capabilities

**Environment:**
- **Cluster**: `practice-node-app-prod`
- **Repository**: `practice-node-app-prod`
- **Namespace**: `practice-app-prod`

### **Continuous Integration (`node-ci.yml`)**

**Triggers:**
- ✅ **Auto**: Pushes to `develop`, `feature/*`, `hotfix/*`
- ✅ **Auto**: Pull requests targeting `develop`

**Purpose:**
- Run `npm ci`, unit tests, and a smoke boot on every change
- Provide fast feedback without touching AWS infrastructure
- Gate merges before manual deployments are triggered

## 🛡️ Safety Controls

### **Production Safety**
```yaml
# Manual approval required - NO AUTOMATION
approve_deployment:
  description: 'Type "deploy-production" to confirm production deployment'
  required: true
  default: 'cancel'

approve_promotion:
  description: 'Type "promote-production" to confirm production promotion'
  required: true
  default: 'cancel'
```

### **Infrastructure Changes**
```yaml
# Auto-plan on PR (infra changes only), manual apply
terraform-plan.yml:  # Auto on PRs targeting develop/main when infra files change
terraform-apply.yml: # Manual with environment selection
```

## 📋 Branch Usage Guidelines

### **`main` Branch**
- **Purpose**: Production-ready code
- **Protection**: ❌ NO auto-deployment, NO direct push
- **Access**: Pull requests only from develop/hotfix
- **Triggers**: Manual production deployment ONLY
- **Safety**: Branch protection required

### **`develop` Branch**
- **Purpose**: Integration and staging
- **Deployment Trigger**: Manual via `deploy-dev.yml` (run when ready)
- **CI Coverage**: Node CI on every push/PR
- **Source**: For production promotion
- **Protection**: Pull requests required
- **Target**: For main branch merges

### **`feature/*` Branches**
- **Purpose**: Feature development
- **Deployment Trigger**: None (CI only). Use `deploy-dev.yml` after merge to update the cluster.
- **CI Coverage**: Node CI on every push/PR
- **Lifecycle**: Delete after merge
- **Naming**: `feature/feature-name`

### **`hotfix/*` Branches**
- **Purpose**: Emergency production fixes
- **Deployment Trigger**: Manual via `deploy-dev.yml` for validation
- **CI Coverage**: Node CI on every push/PR
- **Target**: Merge to both `develop` and `main`
- **Priority**: Immediate attention required
- **Production**: Manual deployment after testing

### **`release/*` Branches**
- **Purpose**: Release preparation (DEPRECATED)
- **Auto-promotion**: ❌ NO automation
- **Lifecycle**: Use promote-to-prod.yml instead
- **Naming**: No longer used
- **Alternative**: Manual promotion workflow

## 🚀 Deployment Workflow

### **Feature Development**
```bash
1. Create feature branch: git checkout -b feature/new-feature develop
2. Develop and test locally
3. Push to feature/* → Node CI runs (tests + smoke, no deploy)
4. Create PR to develop → Node CI reruns + Terraform Plan if infra files changed
5. Merge to develop → Nothing deploys automatically
6. Run `deploy-dev.yml` manually to refresh the dev cluster when you’re ready for shared validation
```

### **Production Release**
```bash
# ONLY Manual Process
1. Ensure develop is stable and tested
2. Run promote-to-prod.yml workflow manually
3. Type "promote-production" to confirm
4. Deploy to production with full testing

# OR Direct Production Deploy
1. Run deploy-prod.yml workflow manually
2. Type "deploy-production" to confirm
3. Deploy to production with full testing
```

### **Emergency Hotfix**
```bash
1. Create hotfix from main: git checkout -b hotfix/critical-fix main
2. Fix issue and test locally
3. Push to hotfix/* → Node CI runs (tests + smoke, no deploy)
4. Optionally run `deploy-dev.yml` to validate in dev
5. Create PR to main and develop
6. Merge to both → Manual production deployment
```

## 🔍 Automation Matrix

| Branch | Infra Plan | Infra Apply | Dev Deploy | Prod Deploy | Promotion |
|--------|------------|-------------|------------|------------|----------|
| `main` | ✅ Auto on PRs touching `infra/**` | ❌ Manual (`terraform-apply.yml`) | ❌ N/A | ✅ Manual (`deploy-prod.yml`) | ✅ Manual (`promote-to-prod.yml`) |
| `develop` | ✅ Auto on PRs targeting `develop` (infra-only) | ❌ Manual (`terraform-apply.yml`) | ⚙️ Manual (`deploy-dev.yml` when ready) | ❌ N/A | ✅ Manual (source for promotion) |
| `feature/*` | ✅ Auto on PRs into `develop` (infra-only) | ❌ Manual | ⚙️ Manual (optional `deploy-dev.yml`) | ❌ N/A | ❌ N/A |
| `hotfix/*` | ✅ Auto on PRs into `develop`/`main` (infra-only) | ❌ Manual | ⚙️ Manual (`deploy-dev.yml` to validate) | ✅ Manual (`deploy-prod.yml`) | ✅ Manual (`promote-to-prod.yml`) |
| `release/*` | ❌ Deprecated | ❌ Deprecated | ❌ Deprecated | ❌ Deprecated | ❌ Deprecated |

## 📊 Environment Comparison

| Feature | Development | Production |
|---------|-------------|-------------|
| **Branch** | `develop`, `feature/*`, `hotfix/*` | `main` ONLY |
| **Deployment Trigger** | Manual via `deploy-dev.yml` | Manual via `deploy-prod.yml` or `promote-to-prod.yml` |
| **CI Coverage** | Node CI on every push/PR | Node CI via PRs + manual gates |
| **Replicas** | 1 | 3 |
| **Resources** | Minimal | High |
| **Monitoring** | Basic | Advanced |
| **Security** | Basic | Enhanced |
| **Testing** | Unit/Smoke | Full + Performance |
| **Approval** | Workflow dispatch owner | Manual confirmation strings |

## 🔄 CI/CD Pipeline Flow

```mermaid
graph TD
    A[Feature Branch Push] --> B[Node CI]
    B --> C[PR to develop]
    C --> D[Node CI + Terraform Plan (if infra)]
    D --> E[Merge to develop]
    E --> F[Manual Deploy to Dev (deploy-dev.yml)]
    F --> G[QA / Validation]
    G --> H[Manual Promotion]
    H --> I[Prod Deploy (deploy-prod.yml)]
    
    J[Hotfix Branch Push] --> K[Node CI]
    K --> L[Optional Deploy to Dev]
    L --> M[PR to main + develop]
    M --> N[Manual Prod Deploy]
```

## 🛠️ Best Practices

### **Branch Management**
- Keep `main` clean and production-ready
- Use descriptive branch names
- Delete merged feature branches
- Protect `main` and `develop` branches

### **Commit Messages**
```
feat: add user authentication
fix: resolve memory leak in API
docs: update deployment guide
hotfix: critical security patch
release: prepare v1.2.0
```

### **Pull Requests**
- Include description and testing steps
- Ensure CI/CD passes
- Request code review
- Link to relevant issues

### **Deployment Safety**
- Never auto-deploy to production
- Always test in development first
- Use promotion workflow for releases
- Monitor production deployments

## 🚨 Emergency Procedures

### **Production Rollback**
```bash
# Option 1: GitHub Actions
# Run deploy-prod.yml with rollback

# Option 2: Manual
kubectl rollout undo deployment/practice-node-app-prod -n practice-app-prod
```

### **Infrastructure Recovery**
```bash
# Terraform state issues
cd infra/environments/prod
terraform force-unlock LOCK_ID

# Complete rebuild
./destroy-prod.sh
./setup-prod.sh
./apply-prod.sh
```

## 📈 Monitoring & Alerts

### **Development Environment**
- Basic health checks
- Unit test results
- Deployment status

### **Production Environment**
- Advanced health checks
- Performance metrics
- Error rates
- Resource utilization
- Security alerts

This branching strategy ensures safe, controlled deployments while maintaining development velocity and production stability.
