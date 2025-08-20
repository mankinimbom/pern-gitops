#!/bin/bash
set -e

# PERN GitOps Validation Script
# This script validates that all declarative configurations are properly set up

echo "🔍 PERN GitOps Configuration Validation"
echo "========================================"
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

check_file() {
    local file="$1"
    local description="$2"
    
    if [ -f "$file" ]; then
        echo -e "✅ ${GREEN}$description${NC}: $file"
    else
        echo -e "❌ ${RED}$description${NC}: $file (MISSING)"
        ((ERRORS++))
    fi
}

check_content() {
    local file="$1"
    local pattern="$2"
    local description="$3"
    
    if [ -f "$file" ] && grep -q "$pattern" "$file"; then
        echo -e "✅ ${GREEN}$description${NC}"
    else
        echo -e "❌ ${RED}$description${NC} (NOT FOUND in $file)"
        ((ERRORS++))
    fi
}

check_warning() {
    local file="$1"
    local pattern="$2"
    local description="$3"
    
    if [ -f "$file" ] && grep -q "$pattern" "$file"; then
        echo -e "⚠️  ${YELLOW}$description${NC}"
        ((WARNINGS++))
    fi
}

echo "📋 1. Checking Core GitOps Files"
echo "--------------------------------"
check_file "bootstrap/root-app.yaml" "Root Application"
check_file "bootstrap/declarative-setup.sh" "Declarative Setup Script"
check_file "projects/appproject.yaml" "ArgoCD Project"
check_file "projects/applicationset.yaml" "ApplicationSet"
echo

echo "📋 2. Checking Application Structure"
echo "-----------------------------------"
check_file "apps/pern-app/base/kustomization.yaml" "Base Kustomization"
check_file "apps/pern-app/base/backend.yaml" "Backend Rollout"
check_file "apps/pern-app/base/frontend.yaml" "Frontend Rollout"
check_file "apps/pern-app/base/secrets/ghcr-secrets.yaml" "GHCR Secret Template"
check_file "apps/pern-app/overlays/production/kustomization.yaml" "Production Overlay"
check_file "apps/pern-app/overlays/staging/kustomization.yaml" "Staging Overlay"
echo

echo "📋 3. Checking ArgoCD Project Permissions"
echo "-----------------------------------------"
check_content "projects/appproject.yaml" "kind: AppProject" "AppProject Permission"
check_content "projects/appproject.yaml" "kind: ApplicationSet" "ApplicationSet Permission"
check_content "projects/appproject.yaml" "kind: Application" "Application Permission"
check_content "projects/appproject.yaml" "kind: Rollout" "Rollout Permission"
check_content "projects/appproject.yaml" "kind: AnalysisTemplate" "AnalysisTemplate Permission"
check_content "projects/appproject.yaml" "kind: Secret" "Secret Permission"
echo

echo "📋 4. Checking Root Application Configuration"
echo "--------------------------------------------"
check_content "bootstrap/root-app.yaml" "path: projects" "Correct Path to Projects"
check_content "bootstrap/root-app.yaml" "project: pern-app" "Correct Project Reference"
check_content "bootstrap/root-app.yaml" "sync-wave.*-1" "Sync Wave Priority"
echo

echo "📋 5. Checking ApplicationSet Configuration"
echo "------------------------------------------"
check_content "projects/applicationset.yaml" "path: apps/pern-app/overlays/\\*" "Environment Discovery Pattern"
check_content "projects/applicationset.yaml" "project: pern-app" "Project Reference"
check_content "projects/applicationset.yaml" "namespace: 'pern-app-{{.path.basename}}'" "Dynamic Namespace"
echo

echo "📋 6. Checking Secret Configuration"
echo "----------------------------------"
check_content "apps/pern-app/base/secrets/ghcr-secrets.yaml" "kubernetes.io/dockerconfigjson" "GHCR Secret Type"
check_content "apps/pern-app/base/backend.yaml" "imagePullSecrets" "Backend ImagePullSecrets"
check_content "apps/pern-app/base/frontend.yaml" "imagePullSecrets" "Frontend ImagePullSecrets"
echo

echo "📋 7. Checking Rollout Configuration"
echo "-----------------------------------"
check_content "apps/pern-app/base/backend.yaml" "kind: Rollout" "Backend Rollout"
check_content "apps/pern-app/base/frontend.yaml" "kind: Rollout" "Frontend Rollout"
check_content "apps/pern-app/base/backend.yaml" "strategy:" "Backend Canary Strategy"
check_content "apps/pern-app/base/frontend.yaml" "strategy:" "Frontend Canary Strategy"
echo

echo "📋 8. Checking Image Configuration"
echo "---------------------------------"
check_content "apps/pern-app/base/kustomization.yaml" "ghcr.io/mankinimbom/pern-backend" "Backend Image"
check_content "apps/pern-app/base/kustomization.yaml" "ghcr.io/mankinimbom/pern-frontend" "Frontend Image"
check_content "apps/pern-app/overlays/production/kustomization.yaml" "newTag:" "Production Image Tags"
check_content "apps/pern-app/overlays/staging/kustomization.yaml" "newTag:" "Staging Image Tags"
echo

echo "📋 9. Checking Template Variables"
echo "--------------------------------"
check_warning "apps/pern-app/base/secrets/ghcr-secrets.yaml" "\\${GITHUB_PAT}" "Template Variables in GHCR Secret"
echo

echo "📋 10. Checking Documentation"
echo "----------------------------"
check_file "docs/declarative-fixes.md" "Declarative Fixes Documentation"
check_file "bootstrap/secrets/README.md" "Secret Management Documentation"
check_file "README.md" "Main README"
echo

echo "=========================================="
echo "🔍 Validation Summary"
echo "=========================================="

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "🎉 ${GREEN}Perfect! All configurations are properly set up.${NC}"
    echo "   Ready for declarative deployment!"
elif [ $ERRORS -eq 0 ]; then
    echo -e "✅ ${GREEN}Good! No critical errors found.${NC}"
    echo -e "⚠️  ${YELLOW}$WARNINGS warning(s) found - these are expected for template files.${NC}"
else
    echo -e "❌ ${RED}$ERRORS error(s) found that need to be fixed.${NC}"
    if [ $WARNINGS -gt 0 ]; then
        echo -e "⚠️  ${YELLOW}$WARNINGS warning(s) also found.${NC}"
    fi
fi

echo
echo "📋 Next Steps:"
echo "1. Fix any errors shown above"
echo "2. Run: export GITHUB_PAT=your_token"
echo "3. Run: ./bootstrap/declarative-setup.sh"
echo "4. Monitor: kubectl -n argocd get applications"

exit $ERRORS
