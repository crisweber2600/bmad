# Git Integration for BMAD Workflows

**Automatic git branching, committing, and PR management for all BMAD workflows**

## Overview

The git integration system automatically manages git operations throughout your BMAD workflow lifecycle:

1. **Before workflow:** Creates feature branch `{base_branch}/{phase}/{workflow}`
2. **During workflow:** You work normally
3. **After workflow:** Commits changes, pushes, prompts for PR, switches to phase branch

## Quick Start

### Enable Git Integration

Git integration is **enabled by default**. To verify:

```bash
# Check config
cat _bmad/core/config.yaml | grep git_integration_enabled
```

### Run Any Workflow

```bash
# Example: Run brainstorming workflow
/bmad:bmm:brainstorming
```

The git integration will automatically:
```
✅ Created branch: main/1/brainstorming
[Workflow executes...]
✅ Changes committed: [Analysis] brainstorming: Generated ideas - by Cris via BMAD
✅ Pushed to origin/main/1/brainstorming
Create PR into main/1? [Y/n]
✅ Switched to phase branch: main/1
```

## Branch Structure

### Phase-Based Branching

```
main (your base branch)
├── main/1 (Phase 1: Analysis)
│   ├── main/1/brainstorming
│   ├── main/1/research
│   └── main/1/create-product-brief
├── main/2 (Phase 2: Planning)
│   ├── main/2/create-prd
│   └── main/2/create-ux-design
├── main/3 (Phase 3: Solutioning)
│   ├── main/3/create-architecture
│   └── main/3/create-epics-and-stories
└── main/4 (Phase 4: Implementation)
    ├── main/4/sprint-planning
    ├── main/4/create-story
    └── main/4/dev-story
```

### Workflow Flow

```
1. Start on main
2. Run brainstorming → Creates main/1/brainstorming
3. Workflow completes → Commits, pushes, prompts for PR into main/1
4. Switch to main/1
5. Run create-prd → Creates main/2/create-prd (from main/1)
6. Workflow completes → Commits, pushes, prompts for PR into main/2
7. Switch to main/2
... and so on
```

## Configuration

All settings in [core/config.yaml](../../config.yaml):

```yaml
# Git Integration Settings
git_integration_enabled: true          # Master switch
git_auto_commit: true                  # Auto-commit changes
git_prompt_before_commit: false        # Ask before committing
git_auto_push: true                    # Auto-push to remote
git_prompt_for_pr: true                # Prompt for PR creation
git_switch_to_phase_branch: true       # Switch to phase branch after workflow
git_open_pr_in_browser: true           # Auto-open PR URL
git_verbose_output: false              # Show detailed git operations
git_prompt_on_dirty_workdir: true      # Warn about uncommitted changes
git_commit_message_template: "[{phase}] {workflow}: {summary} - by {user_name} via BMAD"
```

### Customize Commit Messages

Edit the template in config.yaml:

```yaml
git_commit_message_template: "[{phase}] {workflow}: {summary} - by {user_name} via BMAD"
```

Available variables:
- `{phase}` — Phase name (Analysis, Planning, Solutioning, Implementation)
- `{workflow}` — Workflow name (brainstorming, create-prd, etc.)
- `{summary}` — Intelligent summary of changes
- `{user_name}` — Your name from config

### Disable Git Integration

To disable globally, set in [core/config.yaml](../../config.yaml):

```yaml
git_integration_enabled: false
```

Re-enable by setting it back to `true`.

## Features

### Intelligent Commit Messages

The system generates meaningful commit messages based on:
- Workflow type
- Files changed
- Content analysis

Examples:
```
[Analysis] brainstorming: Generated 15 feature ideas for MVP - by Cris via BMAD
[Planning] create-prd: Created PRD with 12 FRs and 8 NFRs - by Cris via BMAD
[Implementation] dev-story: Implemented user login with JWT tokens - by Cris via BMAD
```

### Smart PR Creation

When workflow completes:
```
✅ Changes committed and pushed

🔀 Pull Request Prompt
   From: main/1/brainstorming
   Into: main/1

Create Pull Request into main/1? [Y/n]
> y

🌐 Opening PR creation page...
   https://github.com/crisweber2600/bmad/compare/main/1...main/1/brainstorming
```

### Phase Branch Switching

After each workflow, automatically switch to the phase branch for seamless workflow chaining:

```
✅ Workflow completed: brainstorming
✅ Switched to phase branch: main/1

[Now ready for next Phase 1 workflow, or move to Phase 2]
```

## Workflow-to-Phase Mapping

| Phase | Number | Workflows |
|-------|--------|-----------|
| **Analysis** | 1 | brainstorming, research, create-product-brief |
| **Planning** | 2 | create-prd, prd, create-ux-design, ux-design, quick-spec |
| **Solutioning** | 3 | create-architecture, architecture, create-epics-and-stories, check-implementation-readiness |
| **Implementation** | 4 | sprint-planning, create-story, dev-story, code-review, retrospective, automate, correct-course, quick-dev |

## Use Cases

### Standard Development Flow

```bash
# Start from main branch
git checkout main

# Phase 1: Analysis
/bmad:bmm:brainstorming
# → Branch: main/1/brainstorming
# → After: You're on main/1

# Phase 2: Planning
/bmad:bmm:create-prd
# → Branch: main/2/create-prd (based on main/1)
# → After: You're on main/2

# Phase 3: Solutioning
/bmad:bmm:create-architecture
# → Branch: main/3/create-architecture (based on main/2)
# → After: You're on main/3

# Phase 4: Implementation
/bmad:bmm:dev-story
# → Branch: main/4/dev-story (based on main/3)
# → After: You're on main/4
```

### Multiple Features in Parallel

```bash
# Feature A - Authentication
git checkout main/2  # Planning phase
/bmad:bmm:create-architecture
# → Branch: main/3/create-architecture
# PR into main/3 when ready

# Feature B - Dashboard (parallel work)
git checkout main/2  # Same phase, different feature
/bmad:bmm:create-architecture  # Will create new timestamped branch
# → Branch: main/3/create-architecture-2
# PR into main/3 when ready
```

## Troubleshooting

### Git Integration Not Working

```bash
# Check if enabled
grep git_integration_enabled _bmad/core/config.yaml

# Should show:
# git_integration_enabled: true
```

### Not a Git Repository

```
⚠️  Not a git repository. Skipping git integration.
```

**Solution:** Initialize git in your project:
```bash
git init
git add .
git commit -m "Initial commit"
```

### Uncommitted Changes Warning

```
⚠️  You have uncommitted changes on main.

Options:
1. Commit changes first
2. Stash changes (git stash)
3. Continue anyway
4. Cancel workflow
```

**Recommendation:** Commit or stash before running workflows.

### Push Failed

```
⚠️  Push failed: <error message>
   Your changes are committed locally.
   Run: git push origin main/1/brainstorming
```

**Common causes:**
- No remote configured
- Network issues
- Authentication required

**Solution:**
```bash
# Configure remote if needed
git remote add origin <your-repo-url>

# Push manually
git push origin main/1/brainstorming
```

## Advanced Usage

### Disable Git Integration Globally

Edit `_bmad/core/config.yaml`:

```yaml
git_integration_enabled: false
```

### Custom Branch Naming

Currently uses `{base_branch}/{phase}/{workflow}` pattern. 

**Future enhancement:** Configurable branch naming patterns.

### Manual Git Operations

You can always use git commands manually:

```bash
# Create your own branch
git checkout -b feature/my-custom-branch

# Run workflow (git integration will use current branch as base)
/bmad:bmm:create-prd
```

## Files

```
git-integration/
├── README.md                   # This file
├── workflow.md                 # Main workflow documentation
├── pre-workflow-hook.md        # Branch creation logic
├── post-workflow-hook.md       # Commit/push/PR logic
├── INTEGRATION_GUIDE.md        # Integration instructions for workflow.xml
├── phase-map.yaml              # Workflow → phase mapping
└── test-integration.sh         # Test script
```

Core task hooks:

- [core/tasks/git-pre-workflow.xml](../../../core/tasks/git-pre-workflow.xml)
- [core/tasks/git-post-workflow.xml](../../../core/tasks/git-post-workflow.xml)

Context file (auto-managed):

- `_bmad/_memory/.bmad-git-context.json`

## Support

For issues or questions:
- **Discord:** [#bmad-method-help](https://discord.gg/gk8jAdXWmj)
- **GitHub Issues:** [Report a bug](https://github.com/bmad-code-org/BMAD-METHOD/issues)
- **Documentation:** `/bmad-help` in your IDE

---

**Happy branching! 🌿**
