---
name: workflow-guide
description: Context-aware BMAD workflow guidance based on current lens
---

# Workflow Guide

**Goal:** Provide context-aware workflow guidance based on the user's current lens position in the BMAD workflow map.

Reference: https://docs.bmad-method.org/reference/workflow-map/

## What This Workflow Does

- Detects current lens and architectural context
- Maps lens position to BMAD workflow stages
- Identifies where user is in their workflow journey
- Suggests logical next steps based on context
- Provides links to relevant workflows and documentation

## Detection Logic

### Feature Lens (📍) - Active Development Context

When in Feature Lens, analyze:
- Git branch age (new vs established)
- Presence of story files in `_bmad-output/stories/`
- Presence of PRD/specs
- Commit history
- Open/merged PRs

**Workflow stages:**
1. **Discovery** → PRD exists? Issues linked?
2. **Story Creation** → Story files exist in output?
3. **Dev Story** → Implementation plan created?
4. **Implementation** → Commits on branch?
5. **PR/Review** → PR opened?
6. **Deploy** → PR merged?

### Microservice Lens (🏘️) - Service Architecture Context

When in Microservice Lens, check:
- API documentation
- Service boundaries defined
- Integration tests
- Dependency mapping

**Workflow stages:**
1. **Architecture Planning** → Service design docs?
2. **API Design** → OpenAPI/contracts defined?
3. **Implementation** → Core services implemented?
4. **Integration** → Cross-service communication tested?

### Service Lens (🗺️) - Service Portfolio Context

When in Service Lens, check:
- Service registry
- Cross-service dependencies
- Domain boundaries

**Workflow stages:**
1. **Service Planning** → Service charter defined?
2. **Boundary Definition** → Clear responsibilities?
3. **Team Alignment** → Ownership established?

### Domain Lens (🛰️) - Strategic Context

When in Domain Lens, check:
- Domain map exists
- Architecture documentation
- Strategic initiatives

**Workflow stages:**
1. **Strategic Planning** → Roadmap defined?
2. **Domain Modeling** → Bounded contexts clear?
3. **Architecture Review** → Patterns documented?

## Execution

### Step 1: Detect Current Lens

Run lens detection or use cached lens state:

```bash
# Current lens already in context from navigator activation
# Use: {current_lens}, {active_service}, {active_microservice}, {active_feature}
```

### Step 2: Gather Context Signals

**For Feature Lens:**

```bash
# Check for story files (legacy and current locations)
ls _bmad-output/stories/*{active_feature}*.md 2>/dev/null
ls _bmad-output/implementation-artifacts/*{active_feature}*.md 2>/dev/null

# Check branch age
git log --oneline {branch_name} --since="7 days ago" | wc -l

# Check for PRs (if GitHub CLI available)
if command -v gh >/dev/null 2>&1; then
  gh pr list --head {branch_name} --json state,title
else
  echo "gh CLI not available; skipping PR lookup"
fi

# Check for related issues
git log --format=%B | grep -E "#[0-9]+" | sort -u
```

**For Other Lenses:**
- Check for architecture docs
- Check for service definitions
- Check for domain maps

### Step 3: Determine Workflow Stage

Based on signals, determine current stage:

| Signal | Stage |
|--------|-------|
| No story file + new branch | **Discovery/Story Creation** |
| Story exists + no commits | **Dev Story/Planning** |
| Story + commits < 5 | **Implementation (Early)** |
| Story + commits > 5 + no PR | **Implementation (Ready for PR)** |
| Open PR | **Review** |
| Merged PR | **Deploy/Done** |

### Step 4: Generate Guidance

Format output as:

```markdown
## 📍 You Are Here: {stage_name}

**Current Context:**
- Lens: {lens_icon} {lens_name}
- {context_details}

**Workflow Position:** {stage_number}/{total_stages} - {stage_name}

**What You're Doing:**
{stage_description}

**Next Steps:**
1. {action_1}
2. {action_2}
3. {action_3}

**Relevant Workflows:**
- `{workflow_name_1}` - {description}
- `{workflow_name_2}` - {description}

**Reference:** https://docs.bmad-method.org/reference/workflow-map/#stage-{stage_id}
```

### Step 5: Offer Quick Actions

Based on stage, offer contextual quick actions:

**In Discovery/Story Creation:**
- "Create story for this feature? [Y/n]"
- "Link to existing issue/PRD? [Y/n]"

**In Implementation:**
- "Ready to create PR? [Y/n]"
- "Need to update dev story? [Y/n]"

**In Review:**
- "Check PR status? [Y/n]"
- "Address review comments? [Y/n]"

## Stage Definitions

### Feature Lens Stages

#### 1. Discovery
**Signals:** New branch, no story, no commits
**Actions:** 
- Research requirements
- Create story (`bmm create-story`)
- Link issues/PRDs

#### 2. Story Creation
**Signals:** Recent branch, no story file
**Actions:**
- Run `bmm create-story`
- Document acceptance criteria
- Identify dependencies

#### 3. Dev Story
**Signals:** Story exists, minimal commits
**Actions:**
- Create implementation plan (`bmm dev-story`)
- Break down tasks
- Estimate effort

#### 4. Implementation (Early)
**Signals:** Story + dev story exist, few commits
**Actions:**
- Write tests
- Implement features
- Commit regularly with descriptive messages

#### 5. Implementation (Ready for PR)
**Signals:** Significant commits, tests passing, ready for review
**Actions:**
- Run final tests
- Update documentation
- Create PR with story context

#### 6. Review
**Signals:** PR open
**Actions:**
- Address review feedback
- Update PR based on comments
- Ensure CI/CD passes

#### 7. Deploy
**Signals:** PR merged or deployment pending
**Actions:**
- Monitor deployment
- Verify in staging/production
- Update story status to done

## Output Format

Return structured guidance object:

```yaml
lens: feature
stage: implementation_early
stage_number: 4
total_stages: 7
confidence: high

context:
  feature: oauth-refresh-tokens
  microservice: auth-api
  service: identity
  branch: feature/auth-api/oauth-refresh-tokens
  age_days: 3
  commits: 8
  story_exists: true
  pr_exists: false

guidance:
  title: "Implementation (Early Stage)"
  description: "You're actively building the oauth-refresh-tokens feature"
  next_steps:
    - "Continue implementation following your dev story"
    - "Write tests for new refresh token logic"
    - "Commit with descriptive messages (reference story #123)"
  
  workflows:
    - name: "dev-story"
      description: "Update implementation plan if scope changes"
      path: "_bmad/bmm/workflows/dev-story/workflow.md"
    - name: "create-pr"
      description: "Create PR when ready for review"
      command: "gh pr create"

  reference_url: "https://docs.bmad-method.org/reference/workflow-map/#implementation"
  
  quick_actions:
    - label: "Update dev story"
      command: "bmm dev-story"
    - label: "Ready for PR?"
      command: "lens workflow-guide --check-pr-ready"
```

## Integration Points

### With lens-detect
- Runs after lens detection in navigator activation
- Uses lens variables

### With context-load
- Adds workflow guidance to loaded context
- Displays in status summary

### With BMM workflows
- Provides seamless transitions to BMM workflows
- Pre-populates context for story creation

## Configuration

Configurable in `_lens/lens-config.yaml`:

```yaml
workflow_guidance:
  enabled: true
  auto_show: true  # Show guidance on lens switch
  verbosity: smart  # silent | smart | verbose
  quick_actions_enabled: true
```

## Example Outputs

### Example 1: Feature Lens - Early Implementation

```
📍 You Are Here: Implementation (Early Stage)

Current Context:
- Lens: 📍 Feature
- Feature: oauth-refresh-tokens
- Microservice: auth-api → Service: identity
- Branch: feature/auth-api/oauth-refresh-tokens (3 days old)
- 8 commits | Story exists ✓ | No PR yet

Workflow Position: 4/7 - Implementation

What You're Doing:
You're actively building the oauth-refresh-tokens feature. You have a story 
and dev plan, and you're making steady progress with commits.

Next Steps:
1. Continue implementation following your dev story
2. Write tests for new refresh token logic  
3. Commit with descriptive messages (reference story #123)
4. When ready, create PR: `gh pr create`

Relevant Workflows:
- `dev-story` - Update implementation plan if scope changes
- `impact-analysis` - Check cross-service impacts before PR

Reference: https://docs.bmad-method.org/reference/workflow-map/#implementation
```

### Example 2: Feature Lens - Ready for PR

```
📍 You Are Here: Ready for Pull Request

Current Context:
- Lens: 📍 Feature  
- Feature: oauth-refresh-tokens
- 15 commits | Story complete ✓ | Tests passing ✓

Workflow Position: 5/7 - Implementation Complete

What You're Doing:
Your feature is implemented with good commit history. Tests are passing.
Time to get this reviewed!

Next Steps:
1. ✅ Review your changes: `git diff main...HEAD`
2. ✅ Create PR: `gh pr create --fill`
3. Link PR to story #123
4. Request review from @team

Quick Action: [Create PR Now] [Review Changes First]

Reference: https://docs.bmad-method.org/reference/workflow-map/#pull-request
```

### Example 3: Domain Lens - Strategic Planning

```
🛰️ You Are Here: Strategic Planning

Current Context:
- Lens: 🛰️ Domain
- Branch: main
- 3 active services | 8 microservices

Workflow Position: Domain-level planning

What You're Doing:
You're in domain view, perfect for strategic planning and architecture
decisions that affect multiple services.

Suggested Actions:
1. Review domain map: `lens map`
2. Plan new service boundaries
3. Document cross-cutting concerns
4. Review architecture decisions

Relevant Workflows:
- `domain-map` - Update domain overview
- `new-service` - Plan new bounded context
- `impact-analysis` - Assess changes across services

Reference: https://docs.bmad-method.org/reference/workflow-map/#domain-planning
```

---

**LENS Workflow Guide** - Know where you are, know what's next.
