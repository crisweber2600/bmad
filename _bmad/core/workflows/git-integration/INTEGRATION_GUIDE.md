---
name: workflow-xml-git-integration
description: How to integrate git hooks into core/tasks/workflow.xml
---

# Workflow.xml Git Integration Guide

## Purpose

This document describes how to integrate the pre-workflow and post-workflow git hooks into the BMAD workflow execution engine.

## Integration Points

The git hooks should be added at two specific points in `core/tasks/workflow.xml`:

### 1. Pre-Workflow Hook (Step 1, After Initialization)

**Location:** After Step 1c "Initialize Output"

**Purpose:** Create feature branch before workflow execution begins

**Implementation:**

```xml
<step n="1" title="Load and Initialize Workflow">
  <!-- Existing substeps 1a, 1b, 1c -->
  
  <substep n="1d" title="Git Pre-Workflow Hook">
    <invoke-task path="{project-root}/_bmad/core/tasks/git-pre-workflow.xml" />
  </substep>
</step>
```

**Notes:**
- The task handles configuration loading and feature branch creation
- The task reads the phase map from `core/workflows/git-integration/phase-map.yaml`
- No inline git logic remains in `workflow.xml`

---

### 2. Post-Workflow Hook (Step 3, After Completion)

**Location:** Step 3 "Completion", before reporting completion

**Purpose:** Commit changes, push, prompt for PR, switch to phase branch

**Implementation:**

```xml
<step n="3" title="Completion">
  <substep n="3a" title="Git Post-Workflow Hook">
    <invoke-task path="{project-root}/_bmad/core/tasks/git-post-workflow.xml" />
  </substep>
  
  <substep n="3b" title="Report Completion">
    <check>Confirm document saved to output path</check>
    <action>Report workflow completion</action>
  </substep>
</step>
```

---

## Complete Modified Flow

```xml
<flow>
  <step n="1" title="Load and Initialize Workflow">
    <substep n="1a" title="Load Configuration and Resolve Variables">
      <!-- Existing content -->
    </substep>

    <substep n="1b" title="Load Required Components">
      <!-- Existing content -->
    </substep>

    <substep n="1c" title="Initialize Output" if="template-workflow">
      <!-- Existing content -->
    </substep>

    <!-- NEW: Git Pre-Workflow Hook -->
    <substep n="1d" title="Git Pre-Workflow Hook">
      <invoke-task path="{project-root}/_bmad/core/tasks/git-pre-workflow.xml" />
    </substep>
  </step>

  <step n="2" title="Process Each Instruction Step in Order">
    <!-- Existing content - no changes -->
  </step>

  <step n="3" title="Completion">
    <!-- NEW: Git Post-Workflow Hook -->
    <substep n="3a" title="Git Post-Workflow Hook">
      <invoke-task path="{project-root}/_bmad/core/tasks/git-post-workflow.xml" />
    </substep>

    <substep n="3b" title="Report Completion">
      <check>Confirm document saved to output path</check>
      <action>Report workflow completion</action>
    </substep>
  </step>
</flow>
```

---

## Phase Detection Logic

The workflow execution engine needs to determine the phase number from the workflow name. This can be done via a mapping function:

```javascript
function determineWorkflowPhase(workflowName) {
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
    'quick-spec': 2,
    
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
    'quick-dev': 4
  };
  
  return phaseMap[workflowName] || 0;  // 0 = utility workflow (no phase)
}
```

---

## Configuration Loading

The workflow engine must load git configuration from `core/config.yaml`:

```xml
<substep n="1a" title="Load Configuration and Resolve Variables">
  <action>Read workflow.yaml from provided path</action>
  <mandate>Load config_source (REQUIRED for all modules)</mandate>
  <phase n="1">Load external config from config_source path</phase>
  
  <!-- NEW: Load core config for git integration -->
  <phase n="1.5">Load core config from {project-root}/_bmad/core/config.yaml</phase>
  <phase n="1.6">Extract git_integration_* variables</phase>
  
  <phase n="2">Resolve all {config_source}: references with values from config</phase>
  <phase n="3">Resolve system variables (date:system-generated) and paths ({project-root}, {installed_path})</phase>
  <phase n="4">Ask user for input of any variables that are still unknown</phase>
</substep>
```

---

## Error Handling

### Git Not Available
```
⚠️  Git integration enabled but git command not found.
   Workflow will continue without git operations.
```

### Not a Git Repository
```
ℹ️  Not a git repository. Skipping git integration.
   Workflow will continue normally.
```

### Git Operations Fail
```
❌ Git operation failed: <error message>

Options:
1. Retry git operation
2. Skip git integration for this workflow
3. Cancel workflow

Choice: _
```

---

## Testing the Integration

### Test Workflow Execution

```bash
# Navigate to your project
cd d:/bmad

# Run a test workflow
# The git hooks should automatically:
# 1. Create branch: main/1/brainstorming
# 2. Execute workflow normally
# 3. Commit changes at the end
# 4. Push to remote
# 5. Prompt for PR
# 6. Switch to main/1
```

### Verify Branch Creation

```bash
# After running a workflow, check branches
git branch -a

# Should show:
#   main
#   main/1
#   main/1/brainstorming
```

### Verify Commits

```bash
# Check recent commits
git log --oneline -5

# Should show commits like:
#   abc1234 [Analysis] brainstorming: Generated ideas... - by Cris via BMAD
#   def5678 [Planning] create-prd: Created PRD with 12 FRs - by Cris via BMAD
```

---

## Implementation Checklist

- [ ] Add git configuration variables to core/config.yaml
- [ ] Create pre-workflow-hook.md with branch creation logic
- [ ] Create post-workflow-hook.md with commit/push/PR logic
- [ ] Modify workflow.xml to call hooks at appropriate points
- [ ] Implement phase detection function
- [ ] Add error handling for git failures
- [ ] Test with a sample workflow
- [ ] Document usage in core README

---

## Future Enhancements

### Conflict Resolution
- Auto-merge phase branches back to base
- Detect and resolve simple conflicts
- Smart rebase strategies

### Enhanced PR Integration
- GitLab support (in addition to GitHub)
- Auto-label PRs by phase
- Link PRs to workflow artifacts
- PR template generation

### Branch Cleanup
- Auto-delete merged branches
- Archive old phase branches
- Branch lifecycle management

### Workflow Chaining
- Auto-merge when workflow sequence completes
- Progressive PR approval workflow
- Multi-workflow transaction support
