#!/bin/bash

echo "🔧 Force Rollout Creation by Direct Application"
echo "=============================================="

cd /home/sysadmin/pern/pern-gitops

echo "Step 1: Apply rollouts directly to staging..."
kubectl kustomize apps/pern-app/overlays/staging | grep -A 50 "kind: Rollout" | kubectl apply -f -

echo ""
echo "Step 2: Apply rollouts directly to production..."
kubectl kustomize apps/pern-app/overlays/production | grep -A 50 "kind: Rollout" | kubectl apply -f -

echo ""
echo "Step 3: Check rollout status..."
echo "Staging rollouts:"
kubectl get rollouts -n pern-app-staging

echo ""
echo "Production rollouts:"
kubectl get rollouts -n pern-app-production

echo ""
echo "Step 4: Fix HPA targets..."
kubectl get hpa --all-namespaces | grep "Rollout/"
