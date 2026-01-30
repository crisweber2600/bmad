---
name: git-integration
description: Automatic git branching and commit management for BMAD workflows
---

# Git Integration Workflow

**Purpose:** Provides automatic git branch creation, commits, and PR management for all BMAD workflows.

## Overview

This workflow integrates with the BMAD workflow execution engine to:
1. **Pre-execution:** Create feature branches before workflow starts
2. **Post-execution:** Commit changes, push, and prompt for PR creation
3. **Branch naming:** `{base_branch}/{phase}/{workflow_name}`
4. **Phase tracking:** Switch to phase branch after workflow completion

## How It Works

### Pre-Workflow Hook

When any workflow is triggered:

```
1. Detect current branch (base_branch)
2. Determine phase number from workflow
3. Create branch: {base_branch}/{phase}/{workflow}
4. Switch to new branch
5. Proceed with workflow execution
```

### Post-Workflow Hook

When workflow completes successfully:

```
1. Detect changed files (git status)
2. Stage all changes (git add .)
3. Generate commit message:
   "[{phase}] {workflow}: {summary} - by {user_name} via BMAD"
4. Commit changes
5. Push to remote
6. Prompt user: "Create PR into {base_branch}/{phase}? [Y/n]"
7. Switch to phase branch: {base_branch}/{phase}
```

## Branch Structure

### Example Branch Flow

Starting on `main` branch:

```
Workflow: brainstorming
→ Branch: main/1/brainstorming
→ Commit & Push
→ PR prompt: Create PR into main/1?
→ Switch to: main/1

Workflow: create-prd
→ Branch: main/2/create-prd
→ Commit & Push
→ PR prompt: Create PR into main/2?
→ Switch to: main/2
```

### Phase Mapping

| Phase | Workflows |
|-------|-----------|
| 1 | brainstorming, research, create-product-brief |
| 2 | create-prd, create-ux-design |
| 3 | create-architecture, create-epics-and-stories, check-implementation-readiness |
| 4 | sprint-planning, create-story, dev-story, code-review, retrospective |

## Configuration

Settings in `core/config.yaml`:

```yaml
git_integration_enabled: true
git_auto_commit: true
git_auto_push: true
git_prompt_for_pr: true
git_switch_to_phase_branch: true
git_commit_message_template: "[{phase}] {workflow}: {summary} - by {user_name} via BMAD"
```

## Usage

### Automatic (Default)

Git integration works automatically when enabled. No user action required.

### Manual Override

Users can disable for specific workflows:

```bash
# In workflow execution
Skip git integration for this workflow? [y/N]
```

### PR Creation

When prompted:

```
✅ Changes committed and pushed to main/1/brainstorming

Create Pull Request into main/1? [Y/n]
> y

Opening GitHub PR creation page...
Title: [Phase 1] Brainstorming: Project ideation session
Base: main/1
Compare: main/1/brainstorming

[Create PR on GitHub]
```

## Implementation Notes

### File Change Detection

```bash
# Detect changes (single source of truth)
git status --porcelain
```

### Commit Message Generation

```
Format: [{phase_name}] {workflow_name}: {intelligent_summary} - by {user_name} via BMAD

Examples:
[Analysis] Brainstorming: Generated 15 feature ideas for MVP - by Cris via BMAD
[Planning] Create PRD: Defined 12 FRs and 8 NFRs for auth system - by Cris via BMAD
[Implementation] Dev Story: Implemented user login with JWT tokens - by Cris via BMAD
```

### Error Handling

- **No git repo:** Warn user, skip git operations
- **Merge conflicts:** Detect and prompt user to resolve
- **No changes:** Skip commit, inform user
- **Network error on push:** Inform user, commit remains local

---

## Integration with BMAD Workflow Engine

Git integration is executed via core tasks invoked from `core/tasks/workflow.xml`:

- **Pre-hook:** [core/tasks/git-pre-workflow.xml](../../../core/tasks/git-pre-workflow.xml)
- **Post-hook:** [core/tasks/git-post-workflow.xml](../../../core/tasks/git-post-workflow.xml)

See: [core/tasks/workflow.xml](../../../core/tasks/workflow.xml) for integration details.
