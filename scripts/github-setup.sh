#!/bin/bash

# GitHub Repository Setup Script
# This script helps you create and push to a new GitHub repository

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 VPN Deployment System - GitHub Setup${NC}"
echo -e "${BLUE}=======================================${NC}"

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo -e "${RED}❌ Not in a git repository. Please run 'git init' first.${NC}"
    exit 1
fi

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}⚠️  GitHub CLI (gh) not found. Please install it first:${NC}"
    echo "   macOS: brew install gh"
    echo "   Ubuntu: sudo apt install gh"
    echo "   Or visit: https://cli.github.com/"
    echo ""
    echo -e "${BLUE}Alternative: Create repository manually on GitHub and add remote:${NC}"
    echo "   git remote add origin https://github.com/USERNAME/REPO_NAME.git"
    echo "   git push -u origin main"
    exit 1
fi

# Get repository details
echo -e "${YELLOW}📝 Repository Configuration${NC}"
read -p "Repository name (default: vpn-deployment-system): " REPO_NAME
REPO_NAME=${REPO_NAME:-vpn-deployment-system}

read -p "Repository description (default: WireGuard VPN deployment system for dental software clients): " REPO_DESC
REPO_DESC=${REPO_DESC:-"WireGuard VPN deployment system for dental software clients"}

read -p "Make repository public? (y/N): " MAKE_PUBLIC
if [[ $MAKE_PUBLIC =~ ^[Yy]$ ]]; then
    VISIBILITY="--public"
else
    VISIBILITY="--private"
fi

echo ""
echo -e "${BLUE}🔍 Repository Details:${NC}"
echo -e "   Name: ${GREEN}$REPO_NAME${NC}"
echo -e "   Description: ${GREEN}$REPO_DESC${NC}"
echo -e "   Visibility: ${GREEN}$([ "$VISIBILITY" = "--public" ] && echo "Public" || echo "Private")${NC}"
echo ""

read -p "Create repository? (Y/n): " CONFIRM
if [[ $CONFIRM =~ ^[Nn]$ ]]; then
    echo -e "${YELLOW}❌ Repository creation cancelled.${NC}"
    exit 0
fi

# Check if already authenticated with GitHub
if ! gh auth status &>/dev/null; then
    echo -e "${YELLOW}🔐 GitHub authentication required${NC}"
    gh auth login
fi

# Create the repository
echo -e "${YELLOW}📦 Creating GitHub repository...${NC}"
gh repo create "$REPO_NAME" $VISIBILITY --description "$REPO_DESC" --source=. --push

# Set up branch protection (if public)
if [[ $VISIBILITY == "--public" ]]; then
    echo -e "${YELLOW}🛡️  Setting up branch protection...${NC}"
    gh api repos/:owner/$REPO_NAME/branches/main/protection \
        --method PUT \
        --field required_status_checks='{"strict":true,"contexts":["test"]}' \
        --field enforce_admins=true \
        --field required_pull_request_reviews='{"required_approving_review_count":1}' \
        --field restrictions=null \
        2>/dev/null || echo -e "${YELLOW}⚠️  Could not set up branch protection (may require admin permissions)${NC}"
fi

# Add topics/tags
echo -e "${YELLOW}🏷️  Adding repository topics...${NC}"
gh api repos/:owner/$REPO_NAME/topics \
    --method PUT \
    --field names='["vpn","wireguard","dental-software","hipaa","healthcare","python","flask","automation","security"]' \
    2>/dev/null || true

echo -e "${GREEN}✅ Repository setup complete!${NC}"
echo -e "${GREEN}=========================${NC}"
echo ""
echo -e "${BLUE}📍 Repository URL:${NC}"
gh repo view --web --json url --jq .url

echo ""
echo -e "${BLUE}🚀 Next Steps:${NC}"
echo -e "   1. Review your repository on GitHub"
echo -e "   2. Update README.md with your specific GitHub URLs"
echo -e "   3. Configure any additional settings (collaborators, webhooks, etc.)"
echo -e "   4. Start using the VPN deployment system!"

echo ""
echo -e "${BLUE}📋 Available Commands:${NC}"
echo -e "   • ${GREEN}python vpn.py info${NC}        - Show system information"
echo -e "   • ${GREEN}python vpn.py dashboard${NC}   - Launch web management UI"
echo -e "   • ${GREEN}./scripts/setup-server.sh${NC} - Set up VPN server"

echo ""
echo -e "${GREEN}🎉 Your VPN deployment system is ready for Dr. Jeff Kover and future clients!${NC}"
