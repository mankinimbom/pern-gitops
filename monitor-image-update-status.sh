#!/bin/bash

echo "🔍 GitHub Actions & ArgoCD Image Update Status Check"
echo "=================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check image tags
check_image_tags() {
    local env=$1
    local file_path=$2
    
    echo -e "${BLUE}📋 $env Environment Image Tags:${NC}"
    
    if [[ -f "$file_path" ]]; then
        backend_tag=$(yq-new eval '.images[0].newTag' "$file_path" 2>/dev/null || echo "ERROR")
        frontend_tag=$(yq-new eval '.images[1].newTag' "$file_path" 2>/dev/null || echo "ERROR")
        
        echo "  Backend:  $backend_tag"
        echo "  Frontend: $frontend_tag"
        
        if [[ "$backend_tag" == "$frontend_tag" && "$backend_tag" != "ERROR" ]]; then
            echo -e "  ${GREEN}✅ Tags are synchronized${NC}"
        else
            echo -e "  ${RED}❌ Tags are not synchronized${NC}"
        fi
    else
        echo -e "  ${RED}❌ File not found: $file_path${NC}"
    fi
    echo ""
}

# Check current working directory
if [[ ! -d "apps/pern-app" ]]; then
    echo -e "${RED}❌ Error: Run this script from pern-gitops repository root${NC}"
    exit 1
fi

# Check if new yq is available, install if not
if [[ ! -f "/usr/local/bin/yq-new" ]]; then
    echo -e "${YELLOW}📦 Installing mikefarah/yq...${NC}"
    sudo wget -qO /usr/local/bin/yq-new https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
    sudo chmod +x /usr/local/bin/yq-new
fi

echo -e "${BLUE}🚀 Current Image Tag Status:${NC}"
echo "=============================="

# Check all environments
check_image_tags "Base" "apps/pern-app/base/kustomization.yaml"
check_image_tags "Staging" "apps/pern-app/overlays/staging/kustomization.yaml"
check_image_tags "Production" "apps/pern-app/overlays/production/kustomization.yaml"

# Check last commits for image updates
echo -e "${BLUE}📚 Recent GitOps Commits:${NC}"
echo "========================="
git log --oneline --grep="🚀" -n 5
echo ""

# Check ArgoCD application status if kubectl is available
if command -v kubectl &> /dev/null; then
    echo -e "${BLUE}🔧 ArgoCD Application Status:${NC}"
    echo "============================"
    
    staging_status=$(kubectl get application pern-app-staging -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "NOT_FOUND")
    production_status=$(kubectl get application pern-app-production -n argocd -o jsonpath='{.status.sync.status}' 2>/dev/null || echo "NOT_FOUND")
    
    echo "  Staging:    $staging_status"
    echo "  Production: $production_status"
    echo ""
    
    if [[ "$staging_status" == "Synced" ]]; then
        echo -e "  ${GREEN}✅ Staging is synced${NC}"
    else
        echo -e "  ${YELLOW}⏳ Staging may need manual sync${NC}"
    fi
    
    if [[ "$production_status" == "Synced" ]]; then
        echo -e "  ${GREEN}✅ Production is synced${NC}"
    else
        echo -e "  ${YELLOW}⏳ Production may need manual sync${NC}"
    fi
fi

echo ""
echo -e "${GREEN}🎯 Next Steps:${NC}"
echo "============="
echo "1. Make a code change in pern-app repository"
echo "2. Push to main branch to trigger GitHub Actions"
echo "3. Watch for new commit in this repository with updated image tags"
echo "4. Run this script again to verify updates"
echo ""
echo -e "${BLUE}📊 Monitor GitHub Actions:${NC}"
echo "https://github.com/mankinimbom/pern-app/actions"
echo ""
echo -e "${BLUE}📊 Monitor GitOps Repository:${NC}"
echo "https://github.com/mankinimbom/pern-gitops/commits/main"
