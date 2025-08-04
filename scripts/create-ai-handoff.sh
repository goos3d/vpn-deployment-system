#!/bin/bash

# AI Handoff Branch Creator
# Usage: ./create-ai-handoff.sh "task-description" "target-environment"

set -e

# Configuration
REPO_NAME="vpn-deployment-system"
BRANCH_PREFIX="ai-handoff"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Arguments
TASK_DESCRIPTION="${1:-generic-task}"
TARGET_ENV="${2:-remote-server}"

# Sanitize task description for branch name
TASK_CLEAN=$(echo "$TASK_DESCRIPTION" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')
BRANCH_NAME="${BRANCH_PREFIX}-${TASK_CLEAN}-${TIMESTAMP}"

echo "🤖 Creating AI Handoff Branch: $BRANCH_NAME"

# Create and switch to new branch
git checkout -b "$BRANCH_NAME"

# Create instruction template
cat > AI_HANDOFF_INSTRUCTIONS.md << EOF
# AI Handoff Instructions

## 🎯 Mission Brief
**Objective**: $TASK_DESCRIPTION
**Priority**: High
**Target Environment**: $TARGET_ENV
**Created**: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

## 🖥️ Environment Details
- **Target System**: [Specify OS and version]
- **Access Method**: [RDP/SSH/Local]
- **Credentials**: [Reference to secure location]
- **Working Directory**: [Specify path]

## 📝 Detailed Tasks

### Task 1: [Title]
**Purpose**: [Why this task is needed]
**Commands**:
\`\`\`bash
# Add exact commands here
\`\`\`
**Expected Output**: [What success looks like]
**Validation**: [How to verify it worked]

## 📁 Files to Handle
- **Create**: \`path/to/new-file\` - [purpose]
- **Modify**: \`path/to/existing-file\` - [specific changes]

## 🧪 Testing Requirements
1. [Test step 1]
2. [Test step 2]

## ✅ Success Criteria
- [ ] Task 1 completed successfully
- [ ] All tests pass
- [ ] No errors in logs

## 🚨 Troubleshooting
- **If Error X**: Try solution Y
- **If Issue Z**: Check logs at /path

## 📊 Required Reporting
Please document in AI_HANDOFF_STATUS.md:
- Commands executed and outputs
- Any errors and resolutions
- System information gathered
- Recommendations for improvement
EOF

# Create empty status file for remote AI
cat > AI_HANDOFF_STATUS.md << EOF
# AI Handoff Status Report

**Status**: PENDING EXECUTION
**Created**: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

## 📋 Execution Summary
- **Start Time**: [To be filled by remote AI]
- **End Time**: [To be filled by remote AI]
- **Environment**: $TARGET_ENV

## Task Completion
[To be updated by remote AI during execution]

## Issues Encountered
[To be documented by remote AI]

## Results
[To be provided by remote AI]
EOF

# Add files to git
git add AI_HANDOFF_INSTRUCTIONS.md AI_HANDOFF_STATUS.md

echo "📝 Created instruction and status templates"
echo "📋 Please edit AI_HANDOFF_INSTRUCTIONS.md with specific task details"
echo "🚀 When ready, run: git commit -m '🤖 AI Handoff: $TASK_DESCRIPTION' && git push origin $BRANCH_NAME"
echo ""
echo "Branch created: $BRANCH_NAME"
EOF
