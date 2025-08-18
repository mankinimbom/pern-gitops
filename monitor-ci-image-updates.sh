#!/bin/bash

echo "🔍 CI/CD Image Update Monitoring Guide"
echo "======================================"
echo ""

echo "1. 📦 CHECK GITHUB CONTAINER REGISTRY:"
echo "======================================"
echo "Visit: https://github.com/mankinimbom/pern-app/pkgs/container/pern-backend"
echo "Visit: https://github.com/mankinimbom/pern-app/pkgs/container/pern-frontend"
echo ""
echo "Look for:"
echo "- Latest timestamps on images"
echo "- SHA-based tags (e.g., main-a1b2c3d)"
echo "- Date-based tags (e.g., 20250817-223045-a1b2c3d)"
echo ""

echo "2. 🏃 CHECK GITHUB ACTIONS WORKFLOW:"
echo "===================================="
echo "Visit: https://github.com/mankinimbom/pern-app/actions"
echo ""
echo "Monitor:"
echo "- Build job completion status"
echo "- 'Build and push Docker image' step logs"
echo "- Check for 'pushed' confirmations in logs"
echo ""

echo "3. 🎯 CHECK ARGOCD IMAGE UPDATER:"
echo "================================="
echo "kubectl logs -n argocd deployment/argocd-image-updater"
echo ""

echo "4. 📊 MONITOR IMAGE TAGS IN CLUSTER:"
echo "===================================="
echo "kubectl get rollouts --all-namespaces -o yaml | grep 'image:'"
echo ""

echo "5. 🔄 REAL-TIME MONITORING COMMANDS:"
echo "===================================="

cat << 'EOF'

# Check latest GitHub Actions run
gh run list --repo mankinimbom/pern-app --limit 5

# Check specific workflow run logs  
gh run view --repo mankinimbom/pern-app <RUN_ID> --log

# Monitor ArgoCD applications sync status
kubectl get applications -n argocd -w

# Check rollout image versions
kubectl get rollouts --all-namespaces -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.template.spec.containers[0].image}{"\n"}{end}'

# Watch for image changes in real-time
watch -n 10 'kubectl get rollouts --all-namespaces -o wide'

EOF

echo ""
echo "6. 🚨 AUTOMATED MONITORING SCRIPT:"
echo "=================================="

cat << 'MONITOR_SCRIPT'
#!/bin/bash
# Save as: monitor-image-updates.sh

echo "$(date): Checking for image updates..."

# Get current rollout images
CURRENT_BACKEND=$(kubectl get rollout backend -n pern-app-staging -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "Not found")
CURRENT_FRONTEND=$(kubectl get rollout frontend -n pern-app-staging -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "Not found")

echo "Current Backend Image: $CURRENT_BACKEND"
echo "Current Frontend Image: $CURRENT_FRONTEND"

# Check latest GitHub Actions run
if command -v gh &> /dev/null; then
    echo ""
    echo "Latest GitHub Actions runs:"
    gh run list --repo mankinimbom/pern-app --limit 3 --json status,conclusion,createdAt,displayTitle
fi

# Check ArgoCD sync status
echo ""
echo "ArgoCD Application Status:"
kubectl get applications -n argocd --no-headers | grep pern-app

MONITOR_SCRIPT

echo ""
echo "7. 🔔 SET UP NOTIFICATIONS:"
echo "=========================="
echo "Add to your GitHub repo's webhook settings:"
echo "- Slack/Discord notifications for successful builds"
echo "- Email notifications for failed builds"
echo ""

echo "8. 📈 VERIFY IMAGE UPDATE PIPELINE:"
echo "=================================="

cat << 'VERIFY_SCRIPT'
# Test the complete pipeline:

# 1. Make a small change to trigger CI
echo "# $(date)" >> README.md
git add README.md
git commit -m "test: trigger CI pipeline"
git push origin main

# 2. Watch the GitHub Actions
gh run watch --repo mankinimbom/pern-app

# 3. Monitor ArgoCD for sync
kubectl get applications -n argocd -w

# 4. Check rollout status
kubectl rollout status rollout/backend -n pern-app-staging
kubectl rollout status rollout/frontend -n pern-app-staging

VERIFY_SCRIPT

echo ""
echo "9. 🛠️ TROUBLESHOOTING:"
echo "====================="
echo "If images aren't updating:"
echo "- Check GitHub Actions permissions for GITHUB_TOKEN"
echo "- Verify ArgoCD Image Updater is running"
echo "- Check ArgoCD application sync policy"
echo "- Ensure rollouts have proper image update annotations"
echo ""

echo "🎯 Quick Status Check:"
echo "====================="
