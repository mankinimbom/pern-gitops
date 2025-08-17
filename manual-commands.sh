#!/bin/bash

# Manual GitOps Deployment Commands
# Use this if you prefer to run commands manually

echo "📋 Production-Grade GitOps Deployment Commands"
echo "==============================================="
echo ""

echo "# 1. Install Argo Rollouts (if not already installed)"
echo "kubectl create namespace argo-rollouts"
echo "kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml"
echo ""

echo "# 2. Apply Core Governance"
echo "kubectl apply -f projects/appproject.yaml"
echo ""

echo "# 3. Apply Analysis Templates"
echo "kubectl apply -f projects/analysis-template.yaml"
echo "kubectl apply -f projects/frontend-analysis-template.yaml"
echo ""

echo "# 4. Apply ApplicationSet"
echo "kubectl apply -f projects/applicationset.yaml"
echo ""

echo "# 5. Apply Root Application (if exists)"
echo "kubectl apply -f bootstrap/root-app.yaml"
echo ""

echo "# 6. Monitoring Commands"
echo "kubectl get applications -n argocd"
echo "kubectl get appprojects -n argocd"
echo "kubectl get analysistemplates -n argocd"
echo "kubectl get rollouts -A"
echo ""

echo "# 7. ArgoCD Access"
echo "kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "# Username: admin"
echo "# Password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
