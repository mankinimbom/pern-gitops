#!/bin/bash

echo "🧪 CI/CD IMAGE UPDATE VERIFICATION TEST"
echo "======================================="
echo ""

echo "📊 STEP 1: Current Status Analysis"
echo "=================================="

echo ""
echo "Rollout Images Currently Deployed:"
echo "-----------------------------------"
kubectl get rollouts --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,IMAGE:.spec.template.spec.containers[0].image,READY:.status.readyReplicas,DESIRED:.spec.replicas 2>/dev/null || echo "No rollouts found"

echo ""
echo "ArgoCD Applications Status:"
echo "---------------------------"
kubectl get applications -n argocd -o custom-columns=NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status,REVISION:.status.sync.revision

echo ""
echo "📋 STEP 2: Manual Image Update Test"
echo "==================================="

# Check if we have access to GitHub CLI
if command -v gh &> /dev/null; then
    echo "GitHub CLI detected - checking latest workflow runs..."
    gh run list --repo mankinimbom/pern-app --limit 3 --json status,conclusion,createdAt,displayTitle,databaseId 2>/dev/null || echo "GitHub CLI not authenticated or repo access issue"
else
    echo "⚠️  GitHub CLI (gh) not installed - cannot check workflow runs directly"
    echo "   Install with: curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg"
fi

echo ""
echo "🔄 STEP 3: Trigger Test Build"
echo "============================="

cat << 'TEST_BUILD'
# To test if CI updates images:

cd /home/sysadmin/pern/pern-app

# Make a small change that will trigger CI
echo "# Test CI trigger - $(date)" >> README.md

# Commit and push
git add README.md
git commit -m "test: trigger CI image build pipeline - $(date +%Y%m%d-%H%M%S)"
git push origin main

# Then monitor:
# 1. GitHub Actions: https://github.com/mankinimbom/pern-app/actions
# 2. Watch for new images: 
#    - https://github.com/mankinimbom/pern-app/pkgs/container/pern-backend
#    - https://github.com/mankinimbom/pern-app/pkgs/container/pern-frontend

TEST_BUILD

echo ""
echo "⏱️  STEP 4: Real-time Monitoring Commands"
echo "========================================"

echo ""
echo "Monitor ArgoCD applications (run in separate terminal):"
echo "kubectl get applications -n argocd -w"
echo ""

echo "Monitor rollout changes (run in separate terminal):"
echo "watch -n 5 'kubectl get rollouts --all-namespaces -o wide'"
echo ""

echo "Check ArgoCD logs for image updates:"
echo "kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller --tail=50 -f"

echo ""
echo "🔍 STEP 5: Image Update Detection"
echo "================================="

cat << 'IMAGE_CHECK_SCRIPT'
#!/bin/bash
# Save this as check-image-updates.sh

echo "Current images in rollouts:"

# Function to get image for a rollout
get_image() {
    local namespace=$1
    local name=$2
    kubectl get rollout $name -n $namespace -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "Not found"
}

# Check staging
echo "Staging Backend:  $(get_image pern-app-staging backend)"
echo "Staging Frontend: $(get_image pern-app-staging frontend)"

# Check production  
echo "Production Backend:  $(get_image pern-app-production backend)"
echo "Production Frontend: $(get_image pern-app-production frontend)"

# Check when these were last updated
echo ""
echo "Last rollout updates:"
kubectl get rollouts --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,LAST-UPDATE:.metadata.creationTimestamp 2>/dev/null

IMAGE_CHECK_SCRIPT

echo ""
echo "🚨 STEP 6: Expected Image Tag Formats"
echo "====================================="

echo "Based on your CI/CD workflow, new images should have tags like:"
echo "- main-1a2b3c4 (SHA-based)"
echo "- 20250817-223045-1a2b3c4 (date + SHA)"  
echo "- latest (for main branch)"
echo ""

echo "🎯 STEP 7: Verify ArgoCD Image Updater (if installed)"
echo "==================================================="

# Check if ArgoCD Image Updater exists
if kubectl get deployment argocd-image-updater -n argocd &>/dev/null; then
    echo "✅ ArgoCD Image Updater is installed"
    echo ""
    echo "Check logs:"
    echo "kubectl logs -n argocd deployment/argocd-image-updater --tail=20"
    echo ""
    echo "Image Updater config:"
    kubectl get configmap argocd-image-updater-config -n argocd -o yaml 2>/dev/null || echo "No image updater config found"
else
    echo "❌ ArgoCD Image Updater is NOT installed"
    echo ""
    echo "To install ArgoCD Image Updater:"
    echo "kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj-labs/argocd-image-updater/stable/manifests/install.yaml"
    echo ""
    echo "Your rollouts will need annotations like:"
    echo 'argocd-image-updater.argoproj.io/image-list: backend=ghcr.io/mankinimbom/pern-backend'
fi

echo ""
echo "🎉 TEST COMPLETE!"
echo "================"
echo "Run the commands above to monitor your CI/CD image update pipeline."
