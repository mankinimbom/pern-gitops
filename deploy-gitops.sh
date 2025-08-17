#!/bin/bash

# Production-Grade GitOps Deployment Script
# Deploys the complete PERN stack using ArgoCD with progressive delivery

set -e

echo "🚀 Starting Production-Grade GitOps Deployment..."
echo "=============================================="

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
print_status "Checking prerequisites..."

if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster"
    exit 1
fi

print_success "Prerequisites check passed"

# Check if ArgoCD is running
print_status "Checking ArgoCD installation..."
if kubectl get namespace argocd &> /dev/null; then
    print_success "ArgoCD namespace exists"
    
    if kubectl get pods -n argocd | grep -q "Running"; then
        print_success "ArgoCD pods are running"
    else
        print_warning "ArgoCD pods may not be ready yet"
    fi
else
    print_error "ArgoCD namespace not found. Please install ArgoCD first."
    exit 1
fi

# Install Argo Rollouts if not present
print_status "Checking Argo Rollouts installation..."
if ! kubectl get crd rollouts.argoproj.io &> /dev/null; then
    print_status "Installing Argo Rollouts..."
    kubectl create namespace argo-rollouts || true
    kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
    
    # Wait for Argo Rollouts to be ready
    print_status "Waiting for Argo Rollouts to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/argo-rollouts-controller -n argo-rollouts
    print_success "Argo Rollouts installed successfully"
else
    print_success "Argo Rollouts is already installed"
fi

# Phase 1: Apply core governance and analysis templates
print_status "Phase 1: Applying core governance and analysis templates..."

print_status "Applying AppProject..."
kubectl apply -f projects/appproject.yaml
print_success "AppProject applied"

print_status "Applying Analysis Templates..."
kubectl apply -f projects/analysis-template.yaml
print_success "Backend analysis templates applied"

kubectl apply -f projects/frontend-analysis-template.yaml
print_success "Frontend analysis templates applied"

# Phase 2: Apply ApplicationSet for multi-environment management
print_status "Phase 2: Applying ApplicationSet..."
kubectl apply -f projects/applicationset.yaml
print_success "ApplicationSet applied"

# Phase 3: Apply root application (App-of-Apps)
print_status "Phase 3: Applying Root Application..."
if [ -f "bootstrap/root-app.yaml" ]; then
    kubectl apply -f bootstrap/root-app.yaml
    print_success "Root application applied"
else
    print_warning "Root application file not found, skipping..."
fi

# Wait for applications to be created
print_status "Waiting for applications to be discovered and created..."
sleep 10

# Check application status
print_status "Checking application status..."
echo ""
echo "=== ArgoCD Applications ==="
kubectl get applications -n argocd

echo ""
echo "=== ArgoCD Application Status ==="
kubectl get applications -n argocd -o custom-columns="NAME:.metadata.name,SYNC:.status.sync.status,HEALTH:.status.health.status,REPO:.spec.source.repoURL"

echo ""
echo "=== Analysis Templates ==="
kubectl get analysistemplates -n argocd

echo ""
echo "=== AppProjects ==="
kubectl get appprojects -n argocd

print_success "Deployment completed!"

echo ""
echo "🎉 Production-Grade GitOps Deployment Summary:"
echo "=============================================="
echo "✅ AppProject with comprehensive RBAC applied"
echo "✅ Analysis templates for progressive delivery applied"  
echo "✅ ApplicationSet for multi-environment management applied"
echo "✅ Argo Rollouts installed and ready"
echo ""

print_status "Next Steps:"
echo "1. Monitor application sync status: kubectl get applications -n argocd"
echo "2. Check rollout status: kubectl get rollouts -n pern-app-production"
echo "3. View progressive delivery: kubectl argo rollouts get rollout <rollout-name> -n <namespace>"
echo "4. Access ArgoCD UI: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo ""

print_status "ArgoCD Login Info:"
echo "Username: admin"
echo "Password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
echo ""

print_success "🚀 Your production-grade GitOps pipeline is now active!"
