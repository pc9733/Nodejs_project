# Branch Protection Rules

## 🛡️ Main Branch Protection

### **Required Settings for GitHub Repository:**

#### **Branch Protection Rules for `main` branch:**

```yaml
# GitHub Settings → Branches → Branch protection rule → main
Protection Rules:
✅ Require status checks to pass before merging
  ✅ Require branches to be up to date before merging
  ✅ Require approval of pull requests
    - Required approvers: 2
    - Dismiss stale PR approvals when new commits are pushed
  ✅ Require review from CODEOWNERS
  ✅ Limit who can dismiss pull request reviews
    - Administrators, maintainers
  ✅ Require conversation resolution before merging
  ✅ Require signed commits
  ✅ Limit who can push to matching branches
    - Administrators, maintainers
  ✅ Allow force pushes: ❌ DISABLED
  ✅ Allow deletions: ❌ DISABLED
```

#### **Required Status Checks:**
```yaml
Required Status Checks:
✅ CI/CD Pipeline
  - build-and-deploy (dev workflow)
  - terraform-plan (if infra changes)
✅ Code Quality
  - tests (if configured)
  - lint (if configured)
✅ Security
  - trivy-scan (vulnerability scanning)
```

### **Branch Access Control:**

#### **Push Restrictions:**
```yaml
Who can push to main:
❌ Direct pushes: DISABLED
✅ Pull requests only
✅ Require PR review
✅ Require status checks
```

#### **Merge Methods:**
```yaml
Allowed merge methods:
✅ Squash and merge (recommended)
✅ Create a merge commit
❌ Rebase and merge (not recommended for main)
```

## 🚀 Workflow Implications

### **Production Deployment Flow:**
```bash
# NO direct pushes to main allowed
# All changes must go through PR process

1. Create feature branch from develop
2. Develop and test
3. Push to feature/* → Auto-dev-deploy
4. Create PR to develop → Auto-dev-deploy
5. Merge to develop → Auto-dev-deploy
6. Create PR from develop to main
7. PR review and approval required
8. Status checks must pass
9. Merge to main → NO auto-deploy
10. Manual production deploy via deploy-prod.yml workflow
```

### **Emergency Hotfix Flow:**
```bash
1. Create hotfix branch from main
2. Fix and test locally
3. Push to hotfix/* → Auto-dev-deploy
4. Create PR to main (emergency bypass possible)
5. Admin approval for emergency merge
6. Merge to main → NO auto-deploy
7. Manual production deploy
```

## 🔒 Security Benefits

### **Why Main Branch Protection:**

1. **Prevents Accidental Production Deployments**
   - No direct pushes to main
   - No automatic triggers from main

2. **Ensures Code Quality**
   - Required PR reviews
   - Status checks must pass
   - Conversation resolution required

3. **Audit Trail**
   - All changes tracked via PRs
   - Clear who approved what
   - Timestamped reviews

4. **Controlled Production Access**
   - Production deployment is manual-only
   - Requires typed confirmation
   - Human oversight at every step

## 📋 Implementation Checklist

### **GitHub Repository Settings:**
- [ ] Enable branch protection for main
- [ ] Configure required reviewers (minimum 2)
- [ ] Set up required status checks
- [ ] Disable force pushes
- [ ] Disable branch deletion
- [ ] Configure CODEOWNERS file

### **Team Training:**
- [ ] Document PR process
- [ ] Train on branch protection
- [ ] Emergency procedures
- [ ] Review workflow triggers

### **Monitoring:**
- [ ] Set up alerts for failed status checks
- [ ] Monitor PR merge times
- [ ] Track production deployment frequency
- [ ] Audit branch protection compliance

## 🚨 Emergency Procedures

### **Bypassing Protection (Emergency Only):**
```bash
# Only repository administrators can bypass
1. Temporarily disable branch protection
2. Make emergency change
3. Re-enable protection immediately
4. Document emergency bypass
5. Review and improve procedures
```

### **Rollback Procedures:**
```bash
1. Use GitHub revert for merged PRs
2. Manual production rollback if needed
3. Create hotfix branch from safe commit
4. Follow normal PR process for fix
```

This ensures production safety while maintaining development velocity.
