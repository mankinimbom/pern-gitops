#!/bin/bash
set -e

# Comprehensive Declarative Setup Script for PERN GitOps
# This script applies all fixes that were previously done with ad-hoc kubectl commands

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🚀 Starting comprehensive PERN GitOps declarative setup..."
echo "Repository root: $REPO_ROOT"
echo

# Check prerequisites
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is required but not installed"
    exit 1
fi

if ! kubectl cluster-info &> /dev/null; then
    echo "❌ kubectl is not connected to a cluster"
    exit 1
fi

# Check if GitHub PAT is provided for secrets
if [ -z "$GITHUB_PAT" ]; then
    echo "⚠️  GITHUB_PAT not provided. Secrets will need to be created manually."
    echo "   Set GITHUB_PAT environment variable to auto-generate secrets."
    SKIP_SECRETS=true
else
    echo "✅ GitHub PAT provided for secret generation"
    SKIP_SECRETS=false
fi

GITHUB_USERNAME="${GITHUB_USERNAME:-mankinimbom}"
GITHUB_EMAIL="${GITHUB_EMAIL:-mankinimbom@users.noreply.github.com}"
REPO_URL="${REPO_URL:-https://github.com/mankinimbom/pern-gitops}"

echo "Configuration:"
echo "  GitHub Username: $GITHUB_USERNAME"
echo "  GitHub Email: $GITHUB_EMAIL"  
echo "  Repository URL: $REPO_URL"
echo

# 0. Pre-process secret templates if GitHub PAT is provided
if [ "$SKIP_SECRETS" = false ]; then
    echo "🔐 0. Pre-processing secret templates..."
    
    # Generate base64 auth for Docker config
    GITHUB_AUTH_B64=$(echo -n "$GITHUB_USERNAME:$GITHUB_PAT" | base64 -w 0)
    
    # Create temporary processed secret files
    mkdir -p /tmp/processed-secrets
    
    # Process GHCR secrets
    envsubst '${GITHUB_PAT} ${GITHUB_AUTH_B64}' < "$REPO_ROOT/apps/pern-app/base/secrets/ghcr-secrets.yaml" > /tmp/processed-secrets/ghcr-secrets.yaml
    
    # Process repository secret
    envsubst '${GITHUB_PAT}' < "$REPO_ROOT/projects/repository-secret.yaml" > /tmp/processed-secrets/repository-secret.yaml
    
    echo "✅ Secret templates processed"
else
    echo "⏭️  0. Skipping secret template processing (GITHUB_PAT not provided)"
fi
echo

# 1. Apply ArgoCD Repository Secret first (highest priority)
if [ "$SKIP_SECRETS" = false ]; then
    echo "🔐 1. Applying ArgoCD repository secret..."
    kubectl apply -f /tmp/processed-secrets/repository-secret.yaml
    echo "✅ ArgoCD repository secret applied"
else
    echo "⏭️  1. Skipping repository secret (manual setup required)"
fi
echo

# 2. Apply ArgoCD Project with all necessary permissions
echo "📋 2. Applying ArgoCD Project configuration..."
kubectl apply -f "$REPO_ROOT/projects/appproject.yaml"
echo "✅ ArgoCD Project applied"
echo

# 3. Apply all other ArgoCD project resources (ApplicationSet, AnalysisTemplates, etc.)
echo "📋 3. Applying ArgoCD project resources..."
for file in "$REPO_ROOT/projects"/*.yaml; do
    if [ "$(basename "$file")" != "appproject.yaml" ] && [ "$(basename "$file")" != "repository-secret.yaml" ]; then
        echo "   Applying $(basename "$file")..."
        kubectl apply -f "$file"
    fi
done
echo "✅ ArgoCD project resources applied"
echo

# 4. Apply GHCR image pull secrets if GitHub PAT is provided
if [ "$SKIP_SECRETS" = false ]; then
    echo "🔐 4. Applying GHCR image pull secrets..."
    
    # Create namespaces first if they don't exist
    kubectl create namespace pern-app-production --dry-run=client -o yaml | kubectl apply -f -
    kubectl create namespace pern-app-staging --dry-run=client -o yaml | kubectl apply -f -
    
    # Apply the processed secrets
    kubectl apply -f /tmp/processed-secrets/ghcr-secrets.yaml
    
    echo "✅ GHCR image pull secrets applied"
else
    echo "⏭️  4. Skipping GHCR secrets (manual setup required)"
fi
echo

# 5. Restart ArgoCD components to pick up changes
echo "🔄 5. Restarting ArgoCD components..."
kubectl -n argocd rollout restart deployment/argocd-repo-server
kubectl -n argocd rollout restart deployment/argocd-application-controller
echo "✅ ArgoCD components restarted"
echo

# 6. Wait for ArgoCD to be ready
echo "⏳ 6. Waiting for ArgoCD to be ready..."
kubectl -n argocd rollout status deployment/argocd-repo-server --timeout=120s
kubectl -n argocd rollout status deployment/argocd-application-controller --timeout=120s
echo "✅ ArgoCD is ready"
echo

# 7. Apply the root application
echo "📱 7. Applying root application..."
kubectl apply -f "$REPO_ROOT/bootstrap/root-app.yaml"
echo "✅ Root application applied"
echo

# 8. Wait for applications to be discovered and then refresh them
echo "🔄 8. Waiting for applications to be discovered and refreshing..."
sleep 15  # Give ArgoCD time to discover applications from ApplicationSet

# Get all applications and refresh them
APPS=$(kubectl -n argocd get applications -o name 2>/dev/null || true)
if [ -n "$APPS" ]; then
    for app in $APPS; do
        app_name=$(echo "$app" | sed 's|applications.argoproj.io/||')
        echo "   Refreshing $app_name..."
        kubectl -n argocd annotate "$app" argocd.argoproj.io/refresh=hard --overwrite || true
        # Also trigger sync
        kubectl -n argocd patch "$app" --type='merge' -p='{"operation":{"sync":{"revision":"HEAD","prune":true,"dryRun":false}}}' || true
    done
    echo "✅ All applications refreshed and synced"
else
    echo "⚠️  No applications found yet. They should appear shortly."
fi
echo

# 9. Wait for sync to complete
echo "⏳ 9. Waiting for initial sync to complete..."
sleep 30
echo

# 10. Check final status
echo "🔍 10. Checking final status..."
echo
echo "=== ArgoCD Applications ==="
kubectl -n argocd get applications 2>/dev/null || echo "   No applications found yet"
echo
echo "=== Production Environment ==="
kubectl get pods -n pern-app-production 2>/dev/null || echo "   Namespace not found yet"
echo
echo "=== Staging Environment ==="
kubectl get pods -n pern-app-staging 2>/dev/null || echo "   Namespace not found yet"
echo
echo "=== Image Pull Secrets ==="
kubectl get secrets -n pern-app-production | grep ghcr 2>/dev/null || echo "   Production GHCR secret not found"
kubectl get secrets -n pern-app-staging | grep ghcr 2>/dev/null || echo "   Staging GHCR secret not found"
echo
echo "=== Repository Secret ==="
kubectl get secrets -n argocd | grep pern-gitops 2>/dev/null || echo "   Repository secret not found"
echo

# Cleanup temporary files
if [ "$SKIP_SECRETS" = false ]; then
    rm -rf /tmp/processed-secrets
    echo "✅ Temporary files cleaned up"
fi

echo "🎉 Comprehensive declarative setup complete!"
echo
echo "📋 Next steps:"
echo "   1. Monitor ArgoCD UI: https://argo-ui.ankinimbom.com/"
echo "   2. Check application sync status: kubectl -n argocd get applications"
echo "   3. Review pod status in environments"
echo "   4. Check rollout status: kubectl argo rollouts list -A"
echo
if [ "$SKIP_SECRETS" = true ]; then
    echo "⚠️  Remember to create secrets manually:"
    echo "   export GITHUB_PAT=your_token"
    echo "   $0"
    echo "   # Or use the manual commands documented in the repository"
fi

echo
echo "🔧 To troubleshoot any issues:"
echo "   kubectl -n argocd get applications -o wide"
echo "   kubectl -n argocd describe application <app-name>"
echo "   kubectl -n argocd logs -l app.kubernetes.io/name=argocd-application-controller"
