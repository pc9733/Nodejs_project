# Commit Message Conventions

This document describes the commit message format and conventions used in this project to control CI/CD workflows and maintain a clean git history.

---

## 🎯 Commit Message Format

```
<type>(<scope>): <subject>

[optional body]

[optional footer with flags]
```

### **Type** (required)
The type of change being made:

| Type | Description | Triggers CI? |
|------|-------------|--------------|
| `feat` | New feature | ✅ Yes |
| `fix` | Bug fix | ✅ Yes |
| `docs` | Documentation only | ❌ No (path-ignored) |
| `style` | Code formatting (no logic change) | 🟡 Yes (if app code) |
| `refactor` | Code restructuring | ✅ Yes |
| `perf` | Performance improvement | ✅ Yes |
| `test` | Adding or updating tests | ✅ Yes |
| `build` | Build system changes | ✅ Yes |
| `ci` | CI/CD configuration changes | ✅ Yes |
| `chore` | Maintenance tasks | 🟡 Depends on files |
| `revert` | Revert previous commit | ✅ Yes |
| `wip` | Work in progress (use with `[skip ci]`) | ❌ Should skip |

### **Scope** (optional)
The module or area affected:
- `api` - API changes
- `auth` - Authentication
- `ui` - User interface
- `infra` - Infrastructure (Terraform)
- `k8s` - Kubernetes manifests
- `ci` - CI/CD workflows
- `deps` - Dependency updates

### **Subject** (required)
- Short description (≤50 characters)
- Imperative mood ("add" not "added")
- No period at the end
- Lowercase after the type prefix

### **Body** (optional)
- Detailed explanation of the change
- Wrap at 72 characters
- Explain **why**, not just **what**

### **Footer** (optional)
- References to issues: `Closes #123`, `Fixes #456`
- Breaking changes: `BREAKING CHANGE: description`
- CI control flags: `[skip ci]`, `[deploy dev]`

---

## 🚦 CI/CD Control Flags

### **Skip CI Completely**
Use these flags to skip **all** CI workflows:

```bash
git commit -m "wip: experimenting with new approach [skip ci]"
git commit -m "docs: fix typo in README [ci skip]"
git commit -m "chore: update local config [no ci]"
```

**Supported flags:**
- `[skip ci]`
- `[ci skip]`
- `[no ci]`
- `[skip actions]`

**When to skip CI:**
- ✅ Work-in-progress commits (WIP)
- ✅ Documentation-only changes
- ✅ Local configuration files
- ✅ Temporary experiments
- ✅ Commit message fixes
- ❌ Code changes (never skip for actual code)
- ❌ Bug fixes (always run CI)

---

## 📝 Examples

### **Good Commit Messages**

#### 1. Feature Addition
```
feat(auth): add JWT token refresh mechanism

Implements automatic token refresh before expiration.
Tokens are refreshed 5 minutes before they expire.

Closes #42
```

#### 2. Bug Fix
```
fix(api): handle connection timeout in database queries

Previously, queries would hang indefinitely. Now they
timeout after 30 seconds and retry up to 3 times.

Fixes #128
```

#### 3. Work in Progress (Skip CI)
```
wip: testing new caching strategy [skip ci]
```

#### 4. Documentation Update
```
docs: update API documentation with new endpoints

Added examples for /auth/refresh endpoint.
Updated response schemas for v2 API.

[skip ci]
```

#### 5. Infrastructure Change
```
chore(infra): upgrade EKS cluster to version 1.31

- Updated Terraform variables
- Modified node group configuration
- Added cluster autoscaler support
```

#### 6. Dependency Update
```
build(deps): upgrade Node.js dependencies

- express: 4.18.0 → 4.19.0
- helmet: 7.0.0 → 7.1.0

Fixes security vulnerabilities CVE-2024-XXXX
```

#### 7. Refactoring
```
refactor(server): extract database connection to module

No functional changes. Improves code organization
and makes testing easier.
```

#### 8. Breaking Change
```
feat(api): change authentication to OAuth 2.0

BREAKING CHANGE: JWT authentication removed.
All clients must migrate to OAuth 2.0.

Migration guide: docs/OAUTH_MIGRATION.md
```

---

## 🚀 CI/CD Workflow Triggers

### **What Triggers CI:**

| Event | Node CI Runs? | Auto-Deploy Dev? | Why |
|-------|---------------|------------------|-----|
| Push to `feature/foo` | ❌ No | ❌ No | Not in trigger branches |
| Push to `develop` (app code) | ✅ Yes | ✅ Yes | Auto-trigger for develop |
| Push to `develop` (docs only) | ❌ No | ❌ No | Path filter excludes docs |
| Push to `develop` with `[skip ci]` | ❌ No | ❌ No | Explicitly skipped |
| Create PR to `develop` | ✅ Yes | ❌ No | Always run on PRs |
| Push to PR (update) | ✅ Yes | ❌ No | Re-run on changes |
| Merge PR to `develop` | ✅ Yes | ✅ Yes | Triggers CI + deploy |
| Push to `main` | ✅ Yes | ❌ No | CI only, no auto-deploy |
| Manual trigger | ✅ Yes | ✅ Yes | Always allowed |

---

## 🔄 Typical Workflows

### **Feature Development**

```bash
# Create feature branch
git checkout -b feature/user-dashboard

# Work in progress commits (skip CI to save minutes)
git commit -m "wip: scaffold dashboard component [skip ci]"
git push origin feature/user-dashboard

# More WIP commits
git commit -m "wip: add user stats API [skip ci]"
git push origin feature/user-dashboard

# Ready for testing - no [skip ci]
git commit -m "feat(ui): implement user dashboard

Shows user statistics and recent activity.

Closes #156"
git push origin feature/user-dashboard

# Create PR - CI runs automatically
gh pr create --base develop --title "Add user dashboard"

# Address review feedback
git commit -m "refactor(ui): extract stats component"
git push origin feature/user-dashboard  # CI runs again

# Merge PR - CI runs + auto-deploys to dev
gh pr merge
```

### **Hotfix**

```bash
# Create hotfix branch from main
git checkout -b hotfix/fix-critical-bug main

# Fix the bug - always run CI for hotfixes
git commit -m "fix(api): prevent null pointer in user lookup

Fixes critical bug causing 500 errors.

Fixes #999"
git push origin hotfix/fix-critical-bug

# Create PR to main
gh pr create --base main --title "Hotfix: prevent null pointer"

# After merge, manually deploy to prod
# Go to Actions → Deploy to Production
```

### **Documentation Update**

```bash
# Update docs without triggering CI
git checkout -b docs/update-readme

git commit -m "docs: add troubleshooting guide [skip ci]"
git commit -m "docs: update API examples [skip ci]"

git push origin docs/update-readme

# Create PR - CI won't run (docs path ignored)
gh pr create --base develop
```

### **Infrastructure Change**

```bash
# Infrastructure changes in feature branch
git checkout -b infra/add-cluster-autoscaler

git commit -m "feat(infra): add cluster autoscaler IAM role

- Creates IRSA role for cluster autoscaler
- Adds necessary IAM permissions
- Outputs role ARN for K8s manifest"

git push origin infra/add-cluster-autoscaler

# Create PR - Terraform Plan runs automatically
gh pr create --base develop

# After merge, manually apply Terraform
# Go to Actions → Terraform Apply
```

---

## 🛡️ Best Practices

### **DO:**
- ✅ Use conventional commit format
- ✅ Write clear, descriptive subjects
- ✅ Reference issues in footer
- ✅ Use `[skip ci]` for WIP commits
- ✅ Squash WIP commits before merging PR
- ✅ Use imperative mood ("add" not "added")

### **DON'T:**
- ❌ Skip CI for bug fixes
- ❌ Skip CI for features
- ❌ Use vague messages ("fix stuff", "update")
- ❌ Commit secrets or credentials
- ❌ Mix multiple unrelated changes in one commit
- ❌ Use `[skip ci]` in commit messages on `main` branch

---

## 📊 Commit Message Templates

### **Git Commit Template** (Optional)

Create `~/.gitmessage`:

```
# <type>(<scope>): <subject>
#
# <body>
#
# <footer>
#
# Type: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
# Scope: api, auth, ui, infra, k8s, ci, deps
# Subject: imperative mood, ≤50 chars, no period
#
# Body: explain WHY, not what (wrap at 72 chars)
#
# Footer: Closes #123, Fixes #456, [skip ci], [ci skip]
#
# Examples:
#   feat(api): add user authentication
#   fix(ui): handle loading state correctly
#   docs: update README [skip ci]
#   wip: experimenting with caching [skip ci]
```

Configure Git to use it:
```bash
git config --global commit.template ~/.gitmessage
```

---

## 🔗 Related Documentation

- [GitHub Actions Workflows](../docs/CICD.md)
- [Branching Strategy](../docs/BRANCHING_STRATEGY.md)
- [Contributing Guide](../CONTRIBUTING.md)

---

## 📚 Resources

- [Conventional Commits](https://www.conventionalcommits.org/)
- [Semantic Commit Messages](https://gist.github.com/joshbuchea/6f47e86d2510bce28f8e7f42ae84c716)
- [GitHub Actions: Skip CI](https://docs.github.com/en/actions/managing-workflow-runs/skipping-workflow-runs)

---

**Questions?** Open an issue or check the [docs/](../docs/) directory.
