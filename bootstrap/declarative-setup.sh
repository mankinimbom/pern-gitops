#!/bin/bash
set -e

# Declarative Setup Script for PERN GitOps
# This script applies all fixes that were previously done with ad-hoc kubectl commands

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🚀 Starting declarative PERN GitOps setup..."
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

echo

# 1. Apply ArgoCD Project with all necessary permissions
echo "📋 1. Applying ArgoCD Project configuration..."
kubectl apply -f "$REPO_ROOT/projects/appproject.yaml"
echo "✅ ArgoCD Project applied"
echo

# 2. Apply all other ArgoCD project resources
echo "📋 2. Applying ArgoCD project resources..."
kubectl apply -f "$REPO_ROOT/projects/"
echo "✅ ArgoCD project resources applied"
echo

# 3. Generate and apply secrets if GitHub PAT is provided
if [ "$SKIP_SECRETS" = false ]; then
    echo "🔐 3. Generating and applying secrets..."
    
    # Generate secrets
    cd "$REPO_ROOT/bootstrap/secrets"
    GITHUB_PAT="$GITHUB_PAT" ./generate-secrets.sh
    
    # Apply secrets
    kubectl apply -f /tmp/ghcr-image-pull-secrets.yaml
    kubectl apply -f /tmp/argocd-repo-secret.yaml
    
    # Clean up temporary files
    rm -f /tmp/ghcr-image-pull-secrets.yaml /tmp/argocd-repo-secret.yaml
    
    echo "✅ Secrets generated and applied"
else
    echo "⏭️  3. Skipping secret generation (GITHUB_PAT not provided)"
fi
echo

# 4. Restart ArgoCD components to pick up changes
echo "🔄 4. Restarting ArgoCD components..."
kubectl -n argocd rollout restart deployment/argocd-repo-server
kubectl -n argocd rollout restart deployment/argocd-application-controller
echo "✅ ArgoCD components restarted"
echo

# 5. Wait for ArgoCD to be ready
echo "⏳ 5. Waiting for ArgoCD to be ready..."
kubectl -n argocd rollout status deployment/argocd-repo-server --timeout=120s
kubectl -n argocd rollout status deployment/argocd-application-controller --timeout=120s
echo "✅ ArgoCD is ready"
echo

# 6. Apply the root application
echo "📱 6. Applying root application..."
kubectl apply -f "$REPO_ROOT/bootstrap/root-app.yaml"
echo "✅ Root application applied"
echo

# 7. Force refresh all applications
echo "🔄 7. Refreshing all applications..."
sleep 10  # Give ArgoCD time to discover the root app

# Get all applications and refresh them
APPS=$(kubectl -n argocd get applications -o name 2>/dev/null || true)
if [ -n "$APPS" ]; then
    for app in $APPS; do
        echo "   Refreshing $app..."
        kubectl -n argocd annotate "$app" argocd.argoproj.io/refresh=hard --overwrite || true
    done
    echo "✅ All applications refreshed"
else
    echo "⚠️  No applications found yet. They should appear shortly."
fi
echo

# 8. Check final status
echo "🔍 8. Checking final status..."
echo
echo "ArgoCD Applications:"
kubectl -n argocd get applications 2>/dev/null || echo "   No applications found yet"
echo
echo "Production Pods:"
kubectl get pods -n pern-app-production 2>/dev/null || echo "   Namespace not found yet"
echo
echo "Staging Pods:"
kubectl get pods -n pern-app-staging 2>/dev/null || echo "   Namespace not found yet"
echo

echo "🎉 Declarative setup complete!"
echo
echo "📋 Next steps:"
echo "   1. Monitor ArgoCD UI: https://argo-ui.ankinimbom.com/"
echo "   2. Check application sync status: kubectl -n argocd get applications"
echo "   3. Review pod status in environments"
echo
if [ "$SKIP_SECRETS" = true ]; then
    echo "⚠️  Remember to create secrets manually:"
    echo "   export GITHUB_PAT=your_token"
    echo "   cd $REPO_ROOT/bootstrap/secrets"
    echo "   ./generate-secrets.sh"
    echo "   kubectl apply -f /tmp/ghcr-image-pull-secrets.yaml"
    echo "   kubectl apply -f /tmp/argocd-repo-secret.yaml"
fi
