# Project Management Setup Guide

This document explains how to track progress for your DevOps learning project.

---

## 🎯 Quick Comparison: Project Management Tools

| Tool | Cost | Best For | Setup Time | Integration |
|------|------|----------|------------|-------------|
| **GitHub Projects** | FREE | Solo/small teams, simple tracking | 5 min | Native GitHub |
| **Jira Free** | FREE (≤10 users) | Learning enterprise tools, complex workflows | 15 min | GitHub app |
| **Linear** | FREE (solo) | Modern UI, keyboard-first | 10 min | GitHub webhook |
| **Trello** | FREE | Visual Kanban, simple tasks | 5 min | Power-Ups |
| **Notion** | FREE | Docs + tasks combined | 10 min | Manual |

**Recommendation**: Start with **GitHub Projects** → migrate to Jira if learning enterprise workflows

---

## Option 1: GitHub Projects (Recommended)

### Why Choose This?
- ✅ No context switching (same platform as code)
- ✅ Auto-links to PRs, commits, issues
- ✅ Zero setup cost
- ✅ Good enough for portfolio projects

### Setup Steps

1. **Create Project**
   ```bash
   # Navigate to your repository on GitHub
   # Go to: Projects tab → New project → Board view
   # Name: "DevOps Learning Roadmap"
   ```

2. **Configure Columns**
   - **Backlog** - Not started
   - **In Progress** - Currently working on
   - **Blocked** - Waiting on something
   - **Done** - Completed

3. **Add Custom Fields**
   - **Priority**: High, Medium, Low
   - **Phase**: Phase 1-5 (matches TODO.md)
   - **Learning Area**: IaC, GitOps, Security, Observability, Cost
   - **Estimated Hours**: 1-8 hours
   - **Status**: Not Started, In Progress, Testing, Done

4. **Import from TODO.md**
   ```bash
   # Manually create issues from TODO.md sections
   # Or use GitHub CLI:
   gh issue create --title "Fix Cluster Autoscaler IAM Role" \
     --label "critical,infrastructure" \
     --body "See TODO.md CRITICAL section"

   # Add to project
   gh project item-add <PROJECT_NUMBER> --owner @me --url <ISSUE_URL>
   ```

5. **Automation Rules**
   - Auto-move to "In Progress" when PR linked
   - Auto-move to "Done" when PR merged
   - Add label "needs-review" after 3 days in progress

---

## Option 2: Jira Free Tier

### Why Choose This?
- ✅ Industry standard (looks great on resume)
- ✅ Advanced features: sprints, burndown charts, roadmaps
- ✅ Free for up to 10 users
- ❌ Heavier than GitHub Projects
- ❌ Overkill for solo projects

### Jira Free Tier Limits
- **Users**: Up to 10
- **Storage**: 2GB
- **Projects**: Unlimited
- **Boards**: Unlimited
- **Features**:
  - ✅ Scrum/Kanban boards
  - ✅ Roadmaps
  - ✅ Basic reporting
  - ❌ Advanced reporting (premium)
  - ❌ Custom dashboards (premium)

### Setup Steps

1. **Create Account**
   - Go to: https://www.atlassian.com/software/jira/free
   - Sign up with email
   - Create site: `yourname-devops.atlassian.net`

2. **Create Project**
   - Template: **Kanban** (for continuous flow)
   - Name: "DevOps Learning - EKS Project"
   - Key: `DEVOPS`

3. **Configure Issue Types**
   - **Epic**: Large features (e.g., "Phase 1: Core Infrastructure")
   - **Story**: User-facing work (e.g., "Deploy ArgoCD")
   - **Task**: Technical work (e.g., "Update Terraform variable")
   - **Bug**: Fixes (e.g., "Fix IAM role placeholder")

4. **Import from TODO.md**
   ```bash
   # Option A: Manual (tedious but good for learning Jira)
   # Create epics for each phase
   # Create stories for each section
   # Link related issues

   # Option B: CSV Import
   # Convert TODO.md to CSV format:
   # Summary,Description,Issue Type,Priority,Labels
   # "Fix IAM Role","See TODO.md","Task","Highest","critical,eks"
   ```

5. **GitHub Integration**
   ```bash
   # Install Jira app in GitHub
   # Go to: GitHub repo → Settings → Integrations → Jira
   # Authenticate with Jira
   # Link commits with: DEVOPS-123 in commit message
   ```

6. **Create Dashboard**
   - Burndown chart (if using sprints)
   - Issues by priority
   - Recent activity
   - Time tracking

---

## Option 3: Linear (Modern Alternative)

### Why Choose This?
- ✅ Fast, modern UI
- ✅ Excellent keyboard shortcuts
- ✅ Free for individuals
- ✅ Better than Jira for small teams
- ❌ Less enterprise features than Jira

### Setup Steps

1. **Create Account**: https://linear.app/
2. **Create Workspace**: "DevOps Learning"
3. **Create Project**: "EKS Infrastructure"
4. **Import Issues**: Use Linear's importer or API
5. **GitHub Integration**: Settings → Integrations → GitHub

---

## Option 4: Trello (Visual Kanban)

### Why Choose This?
- ✅ Super visual
- ✅ Drag-and-drop interface
- ✅ Free unlimited boards
- ❌ Less suitable for technical projects
- ❌ Limited reporting

### Setup Steps

1. **Create Account**: https://trello.com/
2. **Create Board**: "DevOps Learning Roadmap"
3. **Create Lists**:
   - 🔴 Critical
   - 🟡 Phase 1: Core
   - 🟢 Phase 2: Observability
   - 🔵 Phase 3: GitOps
   - 🟣 Phase 4: Advanced
   - ✅ Completed
4. **Add Cards**: Copy from TODO.md
5. **Power-Ups**: Enable GitHub power-up for commit linking

---

## Recommended Workflow

### Daily Routine
```bash
# 1. Check current task status
cat TODO.md | grep "in_progress"

# 2. Update GitHub Project or Jira
# Move card to "In Progress"

# 3. Work on task, commit frequently
git commit -m "feat: add cluster autoscaler IAM role

Implements IAM role with IRSA for cluster autoscaler.
Adds necessary permissions for ASG management.

Closes #42"

# 4. Mark complete when done
# Move card to "Done"
# Check off item in TODO.md
```

### Weekly Review
1. **Update TODO.md** with progress
2. **Review metrics**:
   - Tasks completed this week
   - Blockers encountered
   - Learning notes
3. **Plan next week**: Pick 3-5 tasks from backlog
4. **Update portfolio**: Screenshot progress, write notes

### Monthly Review
1. **Retrospective**: What went well? What to improve?
2. **Cost review**: AWS bill analysis
3. **Skills audit**: What did I learn? What's next?
4. **Portfolio update**: Blog post, LinkedIn update

---

## Syncing TODO.md with External Tools

### Sync with GitHub Projects
```bash
# Create issues from TODO.md sections
while IFS= read -r line; do
  if [[ $line == "- [ ] **"* ]]; then
    title=$(echo "$line" | sed 's/- \[ \] \*\*//g' | sed 's/\*\*//g')
    gh issue create --title "$title" --label "todo" --body "From TODO.md"
  fi
done < TODO.md
```

### Sync with Jira (using API)
```python
# sync_jira.py
import requests
import re

JIRA_URL = "https://yourname-devops.atlassian.net"
API_TOKEN = "your-api-token"
PROJECT_KEY = "DEVOPS"

with open("TODO.md", "r") as f:
    content = f.read()

# Parse markdown checkboxes
tasks = re.findall(r"- \[ \] \*\*(.*?)\*\*", content)

for task in tasks:
    # Create Jira issue
    payload = {
        "fields": {
            "project": {"key": PROJECT_KEY},
            "summary": task,
            "issuetype": {"name": "Task"}
        }
    }
    response = requests.post(
        f"{JIRA_URL}/rest/api/3/issue",
        json=payload,
        auth=("email", API_TOKEN)
    )
    print(f"Created: {task} - {response.status_code}")
```

---

## Progress Tracking Metrics

### Track These KPIs
1. **Velocity**: Tasks completed per week
2. **Learning Time**: Hours spent on each phase
3. **Cost**: AWS bill trends
4. **Quality**: Number of reworks/fixes needed
5. **Portfolio**: Blog posts, demos created

### Example Metrics Dashboard
```markdown
## Week 1 Progress (2026-04-05)
- Tasks Completed: 5/8 ✅
- Hours Spent: 12h (Phase 1)
- AWS Cost: $23.45 (under budget)
- Learnings: Terraform IRSA, EKS autoscaling
- Blockers: ASG tagging not working (resolved)
- Next Week: Deploy Prometheus stack
```

---

## GitHub Actions Integration

### Auto-update TODO.md on PR Merge
```yaml
# .github/workflows/update-todo.yml
name: Update TODO
on:
  pull_request:
    types: [closed]

jobs:
  update:
    if: github.event.pull_request.merged == true
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Check off completed task
        run: |
          # Parse PR title for task name
          TASK="${{ github.event.pull_request.title }}"
          # Update TODO.md checkbox
          sed -i "s/- \[ \] \*\*$TASK/- \[x\] **$TASK/" TODO.md
      - name: Commit changes
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add TODO.md
          git commit -m "chore: mark $TASK as complete" || exit 0
          git push
```

---

## Recommended Setup for This Project

**Phase 1 (Now)**: Use TODO.md + GitHub Projects
- Simple, integrated, no learning curve
- Good enough for 80% of use cases

**Phase 2 (Optional)**: Add Jira Free Tier
- Only if you want Jira experience for resume
- Set up sprints (2-week iterations)
- Practice Scrum ceremonies

**Phase 3 (Future)**: Document your workflow
- Create `docs/MY_WORKFLOW.md`
- Show this in interviews
- Explain tool choices

---

## Setting Up GitHub Projects Right Now

```bash
# 1. Go to your repository on GitHub
# https://github.com/yourusername/Nodejs_project

# 2. Click "Projects" tab → "New project"

# 3. Choose "Board" template

# 4. Name: "DevOps Learning Roadmap"

# 5. Create columns:
#    - 🔴 Critical (red)
#    - 📋 Backlog (gray)
#    - 🔄 In Progress (yellow)
#    - 🔍 Review (blue)
#    - ✅ Done (green)

# 6. Add custom fields:
#    - Priority (Single select): Critical, High, Medium, Low
#    - Phase (Single select): Phase 1-5
#    - Hours (Number): Estimated effort
#    - Learning (Multi-select): Terraform, K8s, GitOps, Security

# 7. Create first issue
gh issue create \
  --title "Fix Cluster Autoscaler IAM Role" \
  --label "critical,infrastructure,phase-1" \
  --body "$(cat <<EOF
## Description
Fix the <ACCOUNT_ID> placeholder in cluster-autoscaler.yaml

## Tasks
- [ ] Replace placeholder with actual AWS account ID
- [ ] Add IAM role resource in Terraform
- [ ] Add IAM policy for autoscaler
- [ ] Test autoscaler logs

## References
- TODO.md: CRITICAL section
- File: k8s/addons/cluster-autoscaler.yaml:18
- Docs: https://github.com/kubernetes/autoscaler
EOF
)"

# 8. Add to project
# (Do this manually in GitHub UI for now)
```

---

## Next Steps

1. ✅ **You now have TODO.md** - Your master task list
2. 🔄 **Choose a tool**: GitHub Projects (recommended) or Jira
3. 📝 **Create first task**: "Fix Cluster Autoscaler IAM Role"
4. 🚀 **Start working**: Update status as you go
5. 📊 **Weekly review**: Update TODO.md and metrics

**Want me to help set up GitHub Projects with you?** I can create the first few issues!
