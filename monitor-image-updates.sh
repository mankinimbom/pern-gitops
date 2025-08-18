#!/bin/bash

echo "🔍 PERN Stack GitOps Image Update Monitor"
echo "========================================"
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

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "📊 CURRENT IMAGE TAG STATUS:"
echo "============================"

# Check staging kustomization
if [[ -f "/home/sysadmin/pern/pern-gitops/apps/pern-app/overlays/staging/kustomization.yaml" ]]; then
    log_info "Staging Environment:"
    echo "File: /home/sysadmin/pern/pern-gitops/apps/pern-app/overlays/staging/kustomization.yaml"
    grep -A 10 -B 2 "images:" /home/sysadmin/pern/pern-gitops/apps/pern-app/overlays/staging/kustomization.yaml || log_warn "No images section found in staging"
    echo ""
else
    log_error "Staging kustomization.yaml not found!"
fi

# Check production kustomization  
if [[ -f "/home/sysadmin/pern/pern-gitops/apps/pern-app/overlays/production/kustomization.yaml" ]]; then
    log_info "Production Environment:"
    echo "File: /home/sysadmin/pern/pern-gitops/apps/pern-app/overlays/production/kustomization.yaml"
    grep -A 10 -B 2 "images:" /home/sysadmin/pern/pern-gitops/apps/pern-app/overlays/production/kustomization.yaml || log_warn "No images section found in production"
    echo ""
else
    log_error "Production kustomization.yaml not found!"
fi

echo "🔄 RECENT GITOPS COMMITS (Image Updates):"
echo "========================================"

cd /home/sysadmin/pern/pern-gitops
log_info "Last 10 commits in pern-gitops repository:"
git log --oneline -10 --grep="Deploy to" --grep="update images" --grep="Update.*image" -i

echo ""
echo "📈 KUBERNETES ROLLOUT STATUS:"
echo "============================="

log_info "Current rollout image versions:"
echo ""
echo "Staging Environment:"
kubectl get rollouts -n pern-app-staging -o=jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.template.spec.containers[0].image}{"\n"}{end}' 2>/dev/null | column -t || log_warn "No staging rollouts found"

echo ""
echo "Production Environment:"
kubectl get rollouts -n pern-app-production -o=jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.template.spec.containers[0].image}{"\n"}{end}' 2>/dev/null | column -t || log_warn "No production rollouts found"

echo ""
echo "🎯 HOW TO MONITOR CI IMAGE UPDATES:"
echo "==================================="

echo "1. 📝 Watch GitHub Actions:"
echo "   https://github.com/mankinimbom/pern-app/actions"

echo ""
echo "2. 🔍 Monitor GitOps commits:"
echo "   cd /home/sysadmin/pern/pern-gitops"
echo "   git log --oneline --grep='Deploy to' -10"

echo ""
echo "3. 📊 Check image registries:"
echo "   # List recent tags"
echo "   docker images | grep pern"
echo "   # Or check GitHub Container Registry"
echo "   curl -H \"Authorization: token \$GITHUB_TOKEN\" https://api.github.com/user/packages/container/pern-frontend/versions"

echo ""
echo "4. 🎮 Monitor ArgoCD Applications:"
echo "   kubectl get applications -n argocd"
echo "   kubectl describe application pern-app-staging -n argocd"

echo ""
echo "5. 🚀 Watch Rollout Updates:"
echo "   kubectl get rollouts --all-namespaces -w"

echo ""
echo "6. 📱 Real-time monitoring (run in background):"
echo "   watch -n 30 '$0'"

echo ""
echo "✅ VERIFICATION CHECKLIST:"
echo "========================="
echo "□ GitHub Action completes successfully"
echo "□ New commit appears in pern-gitops repo with updated image tags"
echo "□ ArgoCD detects the GitOps change (OutOfSync -> Synced)"
echo "□ Kubernetes rollout shows new image version" 
echo "□ Rollout progresses through canary deployment stages"
echo "□ Application pods are running with new image"

echo ""
echo "🔧 TROUBLESHOOTING:"
echo "=================="
echo "• If GitHub Action fails: Check secrets.GITOPS_TOKEN permissions"
echo "• If commits don't appear: Verify GitHub Action push permissions"  
echo "• If ArgoCD doesn't sync: Check application sync policies"
echo "• If rollouts don't update: Verify ArgoCD is watching the correct Git path"

echo ""
echo "📊 Current Monitoring Status: $(date)"
