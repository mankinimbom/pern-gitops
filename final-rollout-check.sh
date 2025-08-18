#!/bin/bash

echo "🔧 Final Rollout Sync and Verification"
echo "====================================="

# Get ArgoCD admin password
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD Admin Password: $ARGOCD_PASSWORD"

# Login to ArgoCD (if CLI is available)
if command -v argocd &> /dev/null; then
    echo "Logging into ArgoCD..."
    argocd login localhost:8080 --username admin --password "$ARGOCD_PASSWORD" --insecure || echo "CLI login skipped"
fi

echo ""
echo "Step 1: Force syncing applications..."

# Sync applications using kubectl patch (works without CLI)
kubectl patch application pern-app-staging -n argocd --type merge --patch='{"operation":{"sync":{}}}'
kubectl patch application pern-app-production -n argocd --type merge --patch='{"operation":{"sync":{}}}'

# Wait for sync to complete
echo "Waiting for applications to sync..."
sleep 30

echo ""
echo "Step 2: Check rollouts status..."

echo "Rollouts in Staging:"
kubectl get rollouts -n pern-app-staging 2>/dev/null || echo "No rollouts found in staging"

echo ""
echo "Rollouts in Production:"
kubectl get rollouts -n pern-app-production 2>/dev/null || echo "No rollouts found in production"

echo ""
echo "Step 3: Check pods status..."

echo "Pods in Staging:"
kubectl get pods -n pern-app-staging 2>/dev/null || echo "No pods found in staging"

echo ""
echo "Pods in Production:"
kubectl get pods -n pern-app-production 2>/dev/null || echo "No pods found in production"

echo ""
echo "Step 4: Application Status:"
kubectl get applications -n argocd

echo ""
echo "Step 5: If rollouts are still missing, try manual resource sync..."

# Try to sync specific resources
for namespace in pern-app-staging pern-app-production; do
    echo "Checking namespace: $namespace"
    if kubectl get namespace $namespace &>/dev/null; then
        echo "✓ Namespace exists"
        
        # Check if applications are trying to create rollouts
        kubectl get events -n $namespace --sort-by='.lastTimestamp' | tail -10 || echo "No recent events"
    else
        echo "✗ Namespace missing"
    fi
done

echo ""
echo "🎯 Summary:"
echo "- ArgoCD applications are configured"
echo "- Use 'kubectl get applications -n argocd' to monitor sync status" 
echo "- Use 'kubectl get rollouts --all-namespaces' to check rollout creation"
echo "- If rollouts are still missing, check application logs in ArgoCD UI"
