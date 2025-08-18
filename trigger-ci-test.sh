#!/bin/bash

echo "🧪 LIVE TEST: Triggering CI to Update Images"
echo "============================================"
echo "$(date)"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Go to pern-app repository
cd /home/sysadmin/pern/pern-app

log_info "Current location: $(pwd)"
log_info "Current branch: $(git branch --show-current)"

# Record current state
CURRENT_COMMIT=$(git rev-parse HEAD | cut -c1-8)
log_info "Current commit: $CURRENT_COMMIT"

# Get current GitOps state
cd /home/sysadmin/pern/pern-gitops
CURRENT_GITOPS_TAG=$(grep 'newTag:' apps/pern-app/overlays/staging/kustomization.yaml | head -1 | awk '{print $2}' | cut -c1-8)
log_info "Current GitOps image tag: $CURRENT_GITOPS_TAG"

# Go back to pern-app
cd /home/sysadmin/pern/pern-app

echo ""
echo "🎯 STEP 1: Make a small change to trigger CI"
echo "============================================"

# Add a test comment to README
TEST_MESSAGE="CI test triggered at $(date '+%Y-%m-%d %H:%M:%S')"
echo "# $TEST_MESSAGE" >> README.md

log_info "Added test line to README.md"
echo "Change made: $TEST_MESSAGE"

echo ""
echo "🎯 STEP 2: Commit and push the change"
echo "====================================="

git add README.md
git commit -m "test: trigger CI image update pipeline - $(date +%Y%m%d-%H%M%S)"

NEW_COMMIT=$(git rev-parse HEAD | cut -c1-8)
log_success "New commit created: $NEW_COMMIT"

echo ""
log_warn "READY TO PUSH! This will trigger GitHub Actions CI/CD pipeline."
log_warn "The workflow will:"
log_warn "1. Build new Docker images with tag: $NEW_COMMIT"  
log_warn "2. Push images to GitHub Container Registry"
log_warn "3. Update pern-gitops repository with new image tags"
echo ""

read -p "Press Enter to push and trigger CI, or Ctrl+C to cancel..."

git push origin main

log_success "Code pushed! GitHub Actions CI/CD pipeline should now be running."

echo ""
echo "🔍 MONITORING INSTRUCTIONS:"
echo "=========================="
echo ""
echo "1. 📊 Watch GitHub Actions:"
echo "   https://github.com/mankinimbom/pern-app/actions"
echo ""
echo "2. 🔄 Monitor GitOps updates (run in separate terminal):"
echo "   cd /home/sysadmin/pern/pern-gitops"
echo "   watch -n 15 'git pull origin main --quiet && echo \"Latest commits:\" && git log --oneline --grep=\"Deploy to\" -2'"
echo ""
echo "3. ✅ Verify image tag updates:"
echo "   cd /home/sysadmin/pern/pern-gitops"
echo "   grep 'newTag:' apps/pern-app/overlays/*/kustomization.yaml"
echo ""
echo "🎯 EXPECTED RESULTS:"
echo "==================="
echo "• New commit in pern-gitops with message: '🚀 Deploy to staging: update images to $NEW_COMMIT'"
echo "• Image tags in kustomization.yaml files updated to: $NEW_COMMIT"
echo "• ArgoCD applications detect changes and sync"
echo ""

if command -v gh &> /dev/null; then
    echo "🎬 Watch workflow in terminal:"
    echo "   gh run watch --repo mankinimbom/pern-app"
    echo ""
else
    log_warn "Install GitHub CLI to watch workflow: sudo apt install gh"
fi

log_success "CI trigger test initiated! Monitor the links above to see the pipeline in action."
