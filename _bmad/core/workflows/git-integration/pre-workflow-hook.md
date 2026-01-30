---
name: pre-workflow-git-hook
description: Creates feature branch before workflow execution
---

# Pre-Workflow Git Hook

## Purpose

Automatically create and switch to a feature branch before any BMAD workflow executes.

## Execution Logic

```javascript
// Pseudo-code for implementation

async function preWorkflowGitHook(workflowName, workflowPhase) {
  // 1. Check if git integration is enabled
  const gitEnabled = getConfig('git_integration_enabled');
  if (!gitEnabled) return;
  
  // 2. Check if we're in a git repository
  const isGitRepo = await runCommand('git rev-parse --git-dir');
  if (!isGitRepo.success) {
    console.log('⚠️  Not a git repository. Skipping git integration.');
    return;
  }
  
  // 3. Get current branch (base branch)
  const baseBranch = await runCommand('git rev-parse --abbrev-ref HEAD');
  
  // 4. Determine phase number
  const phaseNumber = determinePhase(workflowName);
  
  // 5. Create branch name
  const branchName = `${baseBranch}/${phaseNumber}/${workflowName}`;
  
  // 6. Check if branch already exists
  const branchExists = await runCommand(`git rev-parse --verify ${branchName}`);
  
  if (branchExists.success) {
    // Branch exists, switch to it
    await runCommand(`git checkout ${branchName}`);
    console.log(`✅ Switched to existing branch: ${branchName}`);
  } else {
    // Create and switch to new branch
    await runCommand(`git checkout -b ${branchName}`);
    console.log(`✅ Created and switched to new branch: ${branchName}`);
  }
  
  // Store branch info for post-workflow hook
  storeWorkflowContext({
    baseBranch,
    featureBranch: branchName,
    phaseNumber,
    workflowName
  });
}

function determinePhase(workflowName) {
  const phaseMap = {
    // Phase 1: Analysis
    'brainstorming': 1,
    'research': 1,
    'create-product-brief': 1,
    
    // Phase 2: Planning
    'create-prd': 2,
    'prd': 2,
    'create-ux-design': 2,
    'ux-design': 2,
    
    // Phase 3: Solutioning
    'create-architecture': 3,
    'architecture': 3,
    'create-epics-and-stories': 3,
    'check-implementation-readiness': 3,
    
    // Phase 4: Implementation
    'sprint-planning': 4,
    'create-story': 4,
    'dev-story': 4,
    'code-review': 4,
    'retrospective': 4,
    'automate': 4,
    'correct-course': 4,
    
    // Quick Flow (uses phase 2 for planning, 4 for implementation)
    'quick-spec': 2,
    'quick-dev': 4
  };
  
  return phaseMap[workflowName] || 0;  // 0 = core/utility workflow
}
```

## Terminal Commands

### Check Git Repository
```bash
git rev-parse --git-dir 2>/dev/null
```

### Get Current Branch
```bash
git rev-parse --abbrev-ref HEAD
```

### Check if Branch Exists
```bash
git rev-parse --verify <branch-name> 2>/dev/null
```

### Create and Switch to New Branch
```bash
git checkout -b <branch-name>
```

### Switch to Existing Branch
```bash
git checkout <branch-name>
```

## User Experience

### Silent Mode (Default)
```
Starting workflow: brainstorming
✅ Created branch: main/1/brainstorming

[Workflow executes normally]
```

### Verbose Mode
```
🔀 Git Integration Enabled

Current branch: main
Creating feature branch: main/1/brainstorming
Phase: 1 (Analysis)
Workflow: brainstorming

✅ Branch created and checked out

[Workflow executes normally]
```

### When Branch Exists
```
🔀 Git Integration Enabled

Branch main/1/brainstorming already exists.
✅ Switched to existing branch

[Workflow executes normally]
```

## Error Scenarios

### Not a Git Repository
```
⚠️  Not a git repository. Skipping git integration.
Workflow will continue without git branch management.

[Workflow executes normally]
```

### Uncommitted Changes
```
⚠️  You have uncommitted changes on main.

Options:
1. Commit changes first
2. Stash changes (git stash)
3. Continue anyway (changes will be in feature branch)
4. Cancel workflow

Choice: _
```

### Network Issues
```
⚠️  Could not connect to remote repository.
Branch created locally. You can push later manually.

[Workflow executes normally]
```

## Configuration Options

From `core/config.yaml`:

```yaml
git_integration_enabled: true          # Master switch
git_prompt_on_dirty_workdir: true      # Warn about uncommitted changes
git_verbose_output: false              # Show detailed git operations
```

## Implementation Location

This logic is implemented in:
- **Task:** [core/tasks/git-pre-workflow.xml](../../../core/tasks/git-pre-workflow.xml)
- **Called by:** [core/tasks/workflow.xml](../../../core/tasks/workflow.xml) at workflow initialization
- **Context storage:** `_bmad/_memory/.bmad-git-context.json`
