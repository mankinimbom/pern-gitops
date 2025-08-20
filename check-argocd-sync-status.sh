#!/bin/bash

echo "🔍 ArgoCD Sync Status Comprehensive Check"
echo "========================================="
echo ""

# Check current ArgoCD application status
echo "📋 ArgoCD Application Status:"
kubectl get application pern-app-staging -n argocd
echo ""

# Check current GitOps revision
echo "📚 Current GitOps Revision:"
cd /home/sysadmin/pern/pern-gitops
CURRENT_COMMIT=$(git rev-parse HEAD)
echo "Local: $CURRENT_COMMIT"
ARGOCD_REVISION=$(kubectl get application pern-app-staging -n argocd -o jsonpath='{.status.sync.revision}')
echo "ArgoCD: $ARGOCD_REVISION"
echo ""

# Check expected vs actual image tags
echo "🎯 Expected Image Tags (from kustomization.yaml):"
grep -A 1 "newTag:" apps/pern-app/overlays/staging/kustomization.yaml
echo ""

echo "🔍 Actual Image Tags (from deployed rollouts):"
echo "Backend:"
kubectl get rollout backend -n pern-app-staging -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "  No rollout found"
echo ""
echo "Frontend:"
kubectl get rollout frontend -n pern-app-staging -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "  No rollout found"
echo ""

# Check pod status
echo "🚀 Pod Status:"
kubectl get pods -n pern-app-staging
echo ""

# Check rollout status
echo "📊 Rollout Status:"
kubectl get rollouts -n pern-app-staging
echo ""

# Check if there's an ongoing sync operation
echo "⚙️  ArgoCD Operation Status:"
OPERATION_PHASE=$(kubectl get application pern-app-staging -n argocd -o jsonpath='{.status.operationState.phase}' 2>/dev/null)
if [[ -n "$OPERATION_PHASE" ]]; then
    echo "  Operation phase: $OPERATION_PHASE"
    OPERATION_MESSAGE=$(kubectl get application pern-app-staging -n argocd -o jsonpath='{.status.operationState.message}' 2>/dev/null)
    echo "  Message: $OPERATION_MESSAGE"
else
    echo "  No operation running"
fi
echo ""

echo "💡 Recommendations:"
if [[ "$CURRENT_COMMIT" == "$ARGOCD_REVISION" ]]; then
    echo "✅ ArgoCD is looking at the correct revision"
    echo "🔧 If images are still old, try: kubectl rollout restart deployment/rollout -n pern-app-staging"
else
    echo "❌ ArgoCD revision mismatch - force refresh needed"
    echo "🔧 Try: kubectl patch application pern-app-staging -n argocd --type merge --patch '{\"operation\":{\"sync\":{\"revision\":\"HEAD\"}}}'"
fi
