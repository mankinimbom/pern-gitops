#!/bin/bash

echo "🔍 MONITORING CI/CD FROM CORRECT REPOSITORIES"
echo "============================================="
echo "$(date)"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

echo "📂 REPOSITORY STRUCTURE:"
echo "======================="
echo "1. 🏗️  CI/CD Source: /home/sysadmin/pern/pern-app"
echo "   - Contains: .github/workflows/ci-cd.yml"
echo "   - Triggers: On push to main branch"
echo "   - Actions: Build images → Push to registry → Update GitOps repo"
echo ""
echo "2. 📋 GitOps Config: /home/sysadmin/pern/pern-gitops" 
echo "   - Contains: Kubernetes manifests and kustomization files"
echo "   - Updated by: GitHub Actions from pern-app repository"
echo "   - Used by: ArgoCD to deploy to Kubernetes"
echo ""

echo "🔄 HOW CI UPDATES IMAGES:"
echo "========================"
echo "1. Developer pushes code to pern-app repository"
echo "2. GitHub Actions workflow (.github/workflows/ci-cd.yml) triggers"
echo "3. Workflow builds Docker images with SHA-based tags"
echo "4. Images are pushed to GitHub Container Registry"
echo "5. Workflow clones pern-gitops repository"
echo "6. Updates kustomization.yaml files with new image tags"
echo "7. Commits and pushes changes back to pern-gitops"
echo "8. ArgoCD detects changes and syncs to Kubernetes"
echo ""

echo "📊 CURRENT STATUS CHECK:"
echo "========================"

log_info "Checking pern-app repository (CI/CD source):"
cd /home/sysadmin/pern/pern-app
echo "📍 Current location: $(pwd)"
echo "🔗 GitHub repo: https://github.com/mankinimbom/pern-app"
echo "🎬 GitHub Actions: https://github.com/mankinimbom/pern-app/actions"
echo "📝 Last commit:"
git log --oneline -1
echo ""

log_info "Checking pern-gitops repository (ArgoCD config):"
cd /home/sysadmin/pern/pern-gitops  
echo "📍 Current location: $(pwd)"
echo "🔗 GitHub repo: https://github.com/mankinimbom/pern-gitops"
echo "📝 Recent image update commits:"
git log --oneline --grep="Deploy to" -5 2>/dev/null || echo "No deployment commits found"
echo ""

echo "🎯 CURRENT IMAGE TAGS:"
echo "====================="
log_info "Staging environment:"
if [[ -f "apps/pern-app/overlays/staging/kustomization.yaml" ]]; then
    grep -A 4 "images:" apps/pern-app/overlays/staging/kustomization.yaml
else
    log_warn "Staging kustomization.yaml not found"
fi

echo ""
log_info "Production environment:"
if [[ -f "apps/pern-app/overlays/production/kustomization.yaml" ]]; then
    grep -A 4 "images:" apps/pern-app/overlays/production/kustomization.yaml  
else
    log_warn "Production kustomization.yaml not found"
fi

echo ""
echo "🧪 TO TEST CI IMAGE UPDATES:"
echo "============================"

cat << 'TEST_COMMANDS'
# 1. Go to the CI/CD repository
cd /home/sysadmin/pern/pern-app

# 2. Make a small change to trigger CI
echo "# Test CI trigger - $(date)" >> README.md
git add README.md
git commit -m "test: trigger CI image update pipeline"
git push origin main

# 3. Monitor the workflow
echo "🔍 Monitor at: https://github.com/mankinimbom/pern-app/actions"

# 4. Watch for GitOps updates (run in separate terminal)
cd /home/sysadmin/pern/pern-gitops
watch -n 10 'git pull origin main --quiet && echo "Latest deployment commits:" && git log --oneline --grep="Deploy to" -3'

# 5. Check updated image tags
grep -A 4 "images:" apps/pern-app/overlays/*/kustomization.yaml

TEST_COMMANDS

echo ""
echo "📱 REAL-TIME MONITORING COMMANDS:"
echo "================================="
echo ""
echo "Monitor GitHub Actions (CLI):"
echo "cd /home/sysadmin/pern/pern-app"
if command -v gh &> /dev/null; then
    echo "gh run list --limit 5"
    echo "gh run watch"
else
    echo "# Install GitHub CLI first: sudo apt install gh"
fi

echo ""
echo "Monitor GitOps updates:"
echo "cd /home/sysadmin/pern/pern-gitops"
echo "watch -n 15 'git fetch origin && git log origin/main --oneline --grep=\"Deploy to\" -5'"

echo ""
echo "Monitor ArgoCD applications:"
echo "kubectl get applications -n argocd -w"

echo ""
echo "Monitor rollouts:"
echo "kubectl get rollouts --all-namespaces -w"

echo ""
echo "✅ VERIFICATION CHECKLIST:"
echo "========================="
echo "□ Push to pern-app triggers GitHub Actions workflow"
echo "□ GitHub Actions build-and-push job completes successfully"  
echo "□ GitHub Actions deploy-staging job updates pern-gitops repo"
echo "□ New commit appears in pern-gitops with updated image tags"
echo "□ ArgoCD detects changes and syncs applications"
echo "□ Kubernetes rollouts show new image versions"
echo "□ Pods are running with updated images"

echo ""
log_success "The CI/CD pipeline updates images from pern-app → pern-gitops → ArgoCD → Kubernetes"
echo "🎯 Primary monitoring point: https://github.com/mankinimbom/pern-app/actions"
