---
name: post-workflow-git-hook
description: Commits changes, pushes, and prompts for PR after workflow completion
---

# Post-Workflow Git Hook

## Purpose

Automatically commit and push changes after workflow completion, prompt for PR creation, and switch to phase branch.

## Execution Logic

```javascript
// Pseudo-code for implementation

async function postWorkflowGitHook() {
  // 1. Check if git integration is enabled
  const gitEnabled = getConfig('git_integration_enabled');
  if (!gitEnabled) return;
  
  // 2. Load workflow context from pre-hook
  const context = loadWorkflowContext();
  if (!context) {
    console.log('⚠️  No git context found. Skipping post-workflow git operations.');
    return;
  }
  
  const { baseBranch, featureBranch, phaseNumber, workflowName } = context;
  
  // 3. Detect file changes
  const changes = await detectChanges();
  
  if (changes.count === 0) {
    console.log('ℹ️  No file changes detected. Skipping commit.');
    return await switchToPhaseBranch(baseBranch, phaseNumber);
  }
  
  // 4. Show changes summary
  console.log(`\n📝 Changes detected:\n${changes.summary}`);
  
  // 5. Confirm commit (if configured)
  if (getConfig('git_prompt_before_commit')) {
    const shouldCommit = await prompt('Commit these changes? [Y/n]');
    if (!shouldCommit) return;
  }
  
  // 6. Stage all changes
  await runCommand('git add .');
  
  // 7. Generate commit message
  const commitMessage = generateCommitMessage(workflowName, phaseNumber, changes);
  
  // 8. Commit
  await runCommand(`git commit -m "${commitMessage}"`);
  console.log(`✅ Changes committed: ${commitMessage}`);
  
  // 9. Push to remote (if configured)
  if (getConfig('git_auto_push')) {
    const pushResult = await runCommand(`git push origin ${featureBranch}`);
    if (pushResult.success) {
      console.log(`✅ Pushed to origin/${featureBranch}`);
    } else {
      console.log(`⚠️  Could not push to remote. Commit remains local.`);
      console.log(`   Run: git push origin ${featureBranch}`);
    }
  }
  
  // 10. Prompt for PR creation
  if (getConfig('git_prompt_for_pr')) {
    await promptForPR(baseBranch, phaseNumber, featureBranch, workflowName);
  }
  
  // 11. Switch to phase branch
  if (getConfig('git_switch_to_phase_branch')) {
    await switchToPhaseBranch(baseBranch, phaseNumber);
  }
  
  // 12. Cleanup context
  cleanupWorkflowContext();
}

async function detectChanges() {
  // Get modified files
  const modified = await runCommand('git diff --name-only HEAD');
  
  // Get staged files
  const staged = await runCommand('git diff --staged --name-only');
  
  // Get untracked files
  const untracked = await runCommand('git ls-files --others --exclude-standard');
  
  const allFiles = [
    ...modified.stdout.split('\n').filter(Boolean),
    ...staged.stdout.split('\n').filter(Boolean),
    ...untracked.stdout.split('\n').filter(Boolean)
  ];
  
  const uniqueFiles = [...new Set(allFiles)];
  
  return {
    count: uniqueFiles.length,
    files: uniqueFiles,
    summary: uniqueFiles.map(f => `  • ${f}`).join('\n')
  };
}

function generateCommitMessage(workflowName, phaseNumber, changes) {
  const userName = getConfig('user_name');
  const template = getConfig('git_commit_message_template');
  
  // Determine phase name
  const phaseNames = {
    1: 'Analysis',
    2: 'Planning',
    3: 'Solutioning',
    4: 'Implementation'
  };
  const phaseName = phaseNames[phaseNumber] || 'Workflow';
  
  // Generate intelligent summary
  const summary = generateIntelligentSummary(workflowName, changes);
  
  // Apply template
  return template
    .replace('{phase}', phaseName)
    .replace('{workflow}', workflowName)
    .replace('{summary}', summary)
    .replace('{user_name}', userName);
}

function generateIntelligentSummary(workflowName, changes) {
  // Analyze file changes to create meaningful summary
  const { files } = changes;
  
  // Check for specific file patterns
  const hasDocs = files.some(f => f.includes('docs/') || f.endsWith('.md'));
  const hasCode = files.some(f => /\.(js|ts|jsx|tsx|py|java|cs)$/.test(f));
  const hasTests = files.some(f => /test|spec/.test(f));
  const hasConfig = files.some(f => /config|yaml|json/.test(f));
  
  // Workflow-specific summaries
  const summaries = {
    'brainstorming': `Generated ideas and project direction`,
    'create-prd': `Created PRD with ${files.length} artifacts`,
    'create-architecture': `Defined architecture and ADRs`,
    'create-epics-and-stories': `Created epics and story breakdown`,
    'dev-story': `Implemented story with ${hasTests ? 'tests' : 'code'}`,
    'code-review': `Reviewed and validated implementation`
  };
  
  return summaries[workflowName] || `Completed ${workflowName} workflow`;
}

async function promptForPR(baseBranch, phaseNumber, featureBranch, workflowName) {
  const phaseBranch = `${baseBranch}/${phaseNumber}`;
  
  console.log(`\n🔀 Pull Request Prompt`);
  console.log(`   From: ${featureBranch}`);
  console.log(`   Into: ${phaseBranch}`);
  
  const shouldCreatePR = await prompt(`\nCreate Pull Request into ${phaseBranch}? [Y/n]`);
  
  if (shouldCreatePR) {
    // Generate PR URL (GitHub example)
    const repoUrl = await getRemoteRepoUrl();
    if (repoUrl.includes('github.com')) {
      const prUrl = generateGitHubPRUrl(repoUrl, phaseBranch, featureBranch, workflowName);
      console.log(`\n🌐 Opening PR creation page...`);
      console.log(`   ${prUrl}`);
      
      // Open in browser (platform-specific)
      await openUrl(prUrl);
    } else {
      console.log(`\nℹ️  Create PR manually:`);
      console.log(`   Base: ${phaseBranch}`);
      console.log(`   Compare: ${featureBranch}`);
    }
  }
}

async function switchToPhaseBranch(baseBranch, phaseNumber) {
  const phaseBranch = `${baseBranch}/${phaseNumber}`;
  
  // Check if phase branch exists
  const branchExists = await runCommand(`git rev-parse --verify ${phaseBranch}`);
  
  if (branchExists.success) {
    // Switch to existing phase branch
    await runCommand(`git checkout ${phaseBranch}`);
    console.log(`\n✅ Switched to phase branch: ${phaseBranch}`);
  } else {
    // Create phase branch from base branch
    await runCommand(`git checkout ${baseBranch}`);
    await runCommand(`git checkout -b ${phaseBranch}`);
    console.log(`\n✅ Created and switched to phase branch: ${phaseBranch}`);
  }
}

function generateGitHubPRUrl(repoUrl, base, compare, workflowName) {
  // Extract owner/repo from git URL
  const match = repoUrl.match(/github\.com[:/](.+?)\.git/);
  const repo = match ? match[1] : '';
  
  const title = encodeURIComponent(`[Phase] ${workflowName}: Workflow completion`);
  const body = encodeURIComponent(`Automated PR from BMAD workflow: ${workflowName}`);
  
  return `https://github.com/${repo}/compare/${base}...${compare}?title=${title}&body=${body}`;
}
```

## Terminal Commands

### Detect Changes
```bash
# Modified files
git diff --name-only HEAD

# Staged files
git diff --staged --name-only

# Untracked files
git ls-files --others --exclude-standard
```

### Commit and Push
```bash
# Stage all changes
git add .

# Commit with message
git commit -m "message"

# Push to remote
git push origin <branch-name>
```

### Switch Branches
```bash
# Check if branch exists
git rev-parse --verify <branch-name>

# Create and switch
git checkout -b <branch-name>

# Switch to existing
git checkout <branch-name>
```

## User Experience

### Successful Completion
```
✅ Workflow completed: brainstorming

📝 Changes detected:
  • docs/brainstorming-report.md
  • _bmad-output/planning-artifacts/ideas.md

✅ Changes committed: [Analysis] brainstorming: Generated ideas and project direction - by Cris via BMAD
✅ Pushed to origin/main/1/brainstorming

🔀 Pull Request Prompt
   From: main/1/brainstorming
   Into: main/1

Create Pull Request into main/1? [Y/n] y

🌐 Opening PR creation page...
   https://github.com/crisweber2600/bmad/compare/main/1...main/1/brainstorming

✅ Switched to phase branch: main/1
```

### No Changes
```
✅ Workflow completed: code-review

ℹ️  No file changes detected. Skipping commit.

✅ Switched to phase branch: main/4
```

### Push Failure
```
✅ Changes committed: [Implementation] dev-story: Implemented story with tests - by Cris via BMAD
⚠️  Could not push to remote. Commit remains local.
   Run: git push origin main/4/dev-story

Continue anyway? [Y/n] y

✅ Switched to phase branch: main/4
```

## Configuration Options

From `core/config.yaml`:

```yaml
git_integration_enabled: true
git_auto_commit: true                  # Automatically commit changes
git_prompt_before_commit: false        # Ask before committing
git_auto_push: true                    # Automatically push to remote
git_prompt_for_pr: true                # Prompt for PR creation
git_switch_to_phase_branch: true       # Switch to phase branch after workflow
git_open_pr_in_browser: true           # Auto-open PR URL in browser
git_commit_message_template: "[{phase}] {workflow}: {summary} - by {user_name} via BMAD"
```

## Implementation Location

This logic is implemented in:
- **Task:** [core/tasks/git-post-workflow.xml](../../../core/tasks/git-post-workflow.xml)
- **Called by:** [core/tasks/workflow.xml](../../../core/tasks/workflow.xml) at workflow completion
- **Context storage:** `_bmad/_memory/.bmad-git-context.json` (cleaned up after execution)

## Error Handling

### Commit Failure
```
❌ Commit failed: <error message>

Your changes are staged but not committed.
Options:
1. Retry commit
2. Commit manually (git commit -m "message")
3. Skip commit

Choice: _
```

### Push Failure
```
⚠️  Push failed: <error message>

Your changes are committed locally but not pushed.
You can push later with: git push origin main/1/brainstorming

Continue? [Y/n] _
```

### PR Creation Issues
```
⚠️  Could not determine repository URL for PR creation.

Create PR manually:
  Base branch: main/1
  Compare branch: main/1/brainstorming

Continue? [Y/n] _
```
