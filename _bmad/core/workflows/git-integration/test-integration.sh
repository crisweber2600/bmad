#!/usr/bin/env bash
# Git Integration Test Script
# Tests the BMAD git integration workflow

set -u

echo "🧪 BMAD Git Integration Test Suite"
echo "===================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
pass() {
    echo -e "${GREEN}✓${NC} $1"
    TESTS_PASSED=$((TESTS_PASSED+1))
    return 0
}

fail() {
    echo -e "${RED}✗${NC} $1"
    TESTS_FAILED=$((TESTS_FAILED+1))
    return 0
}

info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

warn() {
    echo -e "${YELLOW}!${NC} $1"
}

# Test 1: Check if git is available
echo "Test 1: Git availability"
if command -v git &> /dev/null; then
    pass "Git command found"
else
    fail "Git command not found"
    exit 1
fi

# Test 2: Check if we're in a git repository
echo ""
echo "Test 2: Git repository check"
if git rev-parse --git-dir &> /dev/null; then
    pass "Inside git repository"
else
    fail "Not in a git repository"
    info "Run: git init"
    exit 1
fi

# Test 3: Check current branch
echo ""
echo "Test 3: Current branch detection"
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ -n "$CURRENT_BRANCH" ]; then
    pass "Current branch: $CURRENT_BRANCH"
else
    fail "Could not detect current branch"
fi

# Test 4: Check if config file exists
echo ""
echo "Test 4: Configuration file"
if [ -f "_bmad/core/config.yaml" ]; then
    pass "Config file exists"
else
    fail "Config file not found: _bmad/core/config.yaml"
    exit 1
fi

# Test 5: Check if git integration is enabled
echo ""
echo "Test 5: Git integration enabled"
if grep -q "git_integration_enabled: true" "_bmad/core/config.yaml"; then
    pass "Git integration is enabled"
else
    fail "Git integration is disabled or not configured"
    info "Set git_integration_enabled: true in _bmad/core/config.yaml"
fi

# Test 6: Check if git-integration workflow exists
echo ""
echo "Test 6: Git integration workflow files"
if [ -d "_bmad/core/workflows/git-integration" ]; then
    pass "Git integration folder exists"
    
    if [ -f "_bmad/core/workflows/git-integration/workflow.md" ]; then
        pass "  - workflow.md found"
    else
        fail "  - workflow.md missing"
    fi
    
    if [ -f "_bmad/core/workflows/git-integration/pre-workflow-hook.md" ]; then
        pass "  - pre-workflow-hook.md found"
    else
        fail "  - pre-workflow-hook.md missing"
    fi
    
    if [ -f "_bmad/core/workflows/git-integration/post-workflow-hook.md" ]; then
        pass "  - post-workflow-hook.md found"
    else
        fail "  - post-workflow-hook.md missing"
    fi
    
    if [ -f "_bmad/core/workflows/git-integration/README.md" ]; then
        pass "  - README.md found"
    else
        fail "  - README.md missing"
    fi

    if [ -f "_bmad/core/workflows/git-integration/phase-map.yaml" ]; then
        pass "  - phase-map.yaml found"
    else
        fail "  - phase-map.yaml missing"
    fi

    if [ -f "_bmad/core/workflows/git-integration/test-integration.sh" ]; then
        pass "  - test-integration.sh found"
    else
        fail "  - test-integration.sh missing"
    fi

    if [ -f "_bmad/core/tasks/git-pre-workflow.xml" ]; then
        pass "  - git-pre-workflow.xml found"
    else
        fail "  - git-pre-workflow.xml missing"
    fi

    if [ -f "_bmad/core/tasks/git-post-workflow.xml" ]; then
        pass "  - git-post-workflow.xml found"
    else
        fail "  - git-post-workflow.xml missing"
    fi
else
    fail "Git integration folder not found: _bmad/core/workflows/git-integration"
fi

# Test 7: Simulate branch creation
echo ""
echo "Test 7: Branch creation simulation"
TEST_BRANCH="${CURRENT_BRANCH}/test/git-integration-test"
info "Creating test branch: $TEST_BRANCH"

if git checkout -b "$TEST_BRANCH" &> /dev/null; then
    pass "Test branch created successfully"

    # Switch back to original branch
    git checkout "$CURRENT_BRANCH" &> /dev/null

    # Delete test branch
    git branch -D "$TEST_BRANCH" &> /dev/null
    pass "Test branch cleaned up"
else
    warn "Could not create test branch (working directory may be dirty or branch exists)"
fi

# Test 8: Check if remote exists
echo ""
echo "Test 8: Remote repository"
if git remote -v | grep -q "origin"; then
    REMOTE_URL=$(git remote get-url origin)
    pass "Remote 'origin' configured: $REMOTE_URL"
else
    warn "No remote 'origin' configured (push/PR checks may fail)"
    info "Configure with: git remote add origin <url>"
fi

# Test 9: Check for uncommitted changes
echo ""
echo "Test 9: Working directory status"
if git diff --quiet && git diff --staged --quiet; then
    pass "Working directory is clean"
else
    warn "Uncommitted changes detected"
    info "Current changes:"
    git status --short | sed 's/^/     /'
fi

# Test 10: Phase mapping test
echo ""
echo "Test 10: Phase mapping validation"
declare -A phase_map=(
    ["brainstorming"]=1
    ["create-prd"]=2
    ["create-architecture"]=3
    ["dev-story"]=4
)

ALL_PHASES_OK=true
for workflow in "${!phase_map[@]}"; do
    phase=${phase_map[$workflow]}
    echo "  - $workflow → Phase $phase"
done
pass "Phase mapping defined"

# Summary
echo ""
echo "===================================="
echo "Test Summary"
echo "===================================="
echo -e "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo ""
    echo "Git integration is ready to use."
    echo ""
    echo "Next steps:"
    echo "1. Run any BMAD workflow"
    echo "2. Git integration will automatically:"
    echo "   - Create feature branch"
    echo "   - Commit changes after workflow"
    echo "   - Push to remote"
    echo "   - Prompt for PR creation"
    echo "   - Switch to phase branch"
    exit 0
else
    echo -e "${RED}✗ Some tests failed${NC}"
    echo ""
    echo "Please fix the issues above before using git integration."
    exit 1
fi
