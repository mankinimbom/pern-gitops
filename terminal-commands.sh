# 🎯 COMMANDS TO RUN IN YOUR SEPARATE TERMINAL
# ===========================================

# 1. MONITOR CI/CD PIPELINE IN REAL-TIME
# ======================================
# Navigate to GitOps repository
cd /home/sysadmin/pern/pern-gitops

# Watch for GitOps updates (runs every 15 seconds)
watch -n 15 'git fetch origin --quiet && echo "=== Latest Deployment Commits ===" && git log origin/main --oneline --grep="Deploy to" -5 && echo "" && echo "=== Current Image Tags ===" && grep -A 2 "images:" apps/pern-app/overlays/*/kustomization.yaml'

# Alternative: Monitor pipeline status
./monitor-full-pipeline.sh

# Alternative: Watch image updates only
watch -n 30 './monitor-image-updates.sh'

# 2. MONITOR KUBERNETES RESOURCES
# ===============================
# Watch ArgoCD applications
kubectl get applications -n argocd -w

# Monitor rollouts across all namespaces  
kubectl get rollouts --all-namespaces -w

# Watch pods in staging environment
kubectl get pods -n pern-app-staging -w

# Watch pods in production environment
kubectl get pods -n pern-app-production -w

# 3. TRIGGER CI PIPELINE TEST
# ===========================
# Go to the app repository
cd /home/sysadmin/pern/pern-app

# Run the interactive CI test
/home/sysadmin/pern/pern-gitops/trigger-ci-test.sh

# Alternative: Manual trigger
echo "# Test CI - $(date)" >> README.md
git add README.md  
git commit -m "test: trigger CI pipeline $(date +%H%M%S)"
git push origin main

# 4. MONITOR GITHUB ACTIONS (if GitHub CLI installed)
# ==================================================
# Watch latest workflow runs
gh run list --repo mankinimbom/pern-app --limit 5

# Watch specific workflow run
gh run watch --repo mankinimbom/pern-app

# 5. CHECK CURRENT STATUS
# ======================
# Quick status check
cd /home/sysadmin/pern/pern-gitops && ./confirm-ci-working.sh

# Check rollout images
kubectl get rollouts --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,IMAGE:.spec.template.spec.containers[0].image

# Check ArgoCD sync status
kubectl get applications -n argocd -o custom-columns=NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status

# 6. FORCE ARGOCD SYNC (if needed)
# ================================
# Sync staging application
kubectl patch application pern-app-staging -n argocd --type merge --patch='{"operation":{"sync":{}}}'

# Sync production application  
kubectl patch application pern-app-production -n argocd --type merge --patch='{"operation":{"sync":{}}}'

# 7. USEFUL ONE-LINERS
# ====================
# Check if new commits appeared in GitOps repo
git log --oneline --since="5 minutes ago" --grep="Deploy to"

# Compare app repo commit vs GitOps image tag
cd /home/sysadmin/pern/pern-app && APP_COMMIT=$(git rev-parse HEAD | cut -c1-8) && cd /home/sysadmin/pern/pern-gitops && GITOPS_TAG=$(grep 'newTag:' apps/pern-app/overlays/staging/kustomization.yaml | head -1 | awk '{print $2}' | cut -c1-8) && echo "App commit: $APP_COMMIT | GitOps tag: $GITOPS_TAG"

# Check image registry for latest tags (requires docker login)
docker images | grep pern

# 8. TROUBLESHOOTING COMMANDS
# ===========================
# Check ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller --tail=50

# Check if rollouts exist
kubectl get rollouts --all-namespaces

# Describe problematic rollout
kubectl describe rollout backend -n pern-app-staging

# Check events in namespace
kubectl get events -n pern-app-staging --sort-by='.lastTimestamp'
