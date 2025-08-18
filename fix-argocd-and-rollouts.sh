#!/bin/bash

set -e

echo "🔧 Comprehensive ArgoCD and Rollout Fix"
echo "======================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Step 1: Clean up problematic ArgoCD deployments
log_info "Step 1: Cleaning up problematic ArgoCD deployments..."

# Delete the problematic deployments that are in CrashLoopBackOff
kubectl delete deployment argocd-applicationset-controller -n argocd --ignore-not-found=true
kubectl delete deployment argocd-notifications-controller -n argocd --ignore-not-found=true
kubectl delete deployment argocd-repo-server-7f84b9c7b9 -n argocd --ignore-not-found=true
kubectl delete deployment argocd-server-85dd67d6dd -n argocd --ignore-not-found=true

# Delete the StatefulSet that's problematic
kubectl delete statefulset argocd-application-controller -n argocd --ignore-not-found=true

log_info "Waiting for pods to terminate..."
sleep 30

# Step 2: Install ArgoCD CRDs if missing
log_info "Step 2: Installing ArgoCD CRDs..."
kubectl apply -k https://github.com/argoproj/argo-cd/manifests/crds?ref=stable || log_warn "CRDs installation had issues"

# Step 3: Install Argo Rollouts CRDs
log_info "Step 3: Installing Argo Rollouts CRDs..."
kubectl create namespace argo-rollouts --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml || log_warn "Rollouts installation had issues"

# Step 4: Reinstall ArgoCD cleanly
log_info "Step 4: Reinstalling ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
log_info "Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

# Step 5: Create application namespaces
log_info "Step 5: Creating application namespaces..."
kubectl create namespace pern-app-staging --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace pern-app-production --dry-run=client -o yaml | kubectl apply -f -

# Step 6: Apply the GitOps configurations
log_info "Step 6: Applying GitOps configurations..."
cd /home/sysadmin/pern/pern-gitops

# Apply the bootstrap root app
kubectl apply -f bootstrap/root-app.yaml

# Apply the AppProject
kubectl apply -f projects/appproject.yaml

# Apply the ApplicationSet
kubectl apply -f projects/applicationset.yaml

# Step 7: Wait for applications to sync
log_info "Step 7: Waiting for applications to sync..."
sleep 60

# Step 8: Check status
log_info "Step 8: Final status check..."

echo ""
echo "ArgoCD Pods:"
kubectl get pods -n argocd

echo ""
echo "Applications:"
kubectl get applications -n argocd

echo ""
echo "Rollouts in Staging:"
kubectl get rollouts -n pern-app-staging 2>/dev/null || log_warn "No rollouts in staging yet"

echo ""
echo "Rollouts in Production:"
kubectl get rollouts -n pern-app-production 2>/dev/null || log_warn "No rollouts in production yet"

echo ""
echo "Pods in Staging:"
kubectl get pods -n pern-app-staging 2>/dev/null || log_warn "No pods in staging yet"

echo ""
echo "Pods in Production:"
kubectl get pods -n pern-app-production 2>/dev/null || log_warn "No pods in production yet"

log_info "Fix completed! If applications are still syncing, wait a few more minutes."
log_info "You can check progress with: kubectl get applications -n argocd"
