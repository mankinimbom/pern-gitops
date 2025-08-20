#!/bin/bash

echo "🔍 CI/CD Pipeline Monitoring - Real-Time Image Tag Updates"
echo "==========================================================="
echo ""
echo "📊 Monitoring GitHub Actions: https://github.com/mankinimbom/pern-app/actions"
echo "📊 Monitoring GitOps Repo: https://github.com/mankinimbom/pern-gitops/commits/main"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Get current image tags for comparison
get_current_tags() {
    if [[ -f "apps/pern-app/overlays/staging/kustomization.yaml" ]]; then
        local backend_tag=$(grep -A 2 "name: ghcr.io/mankinimbom/pern-backend" apps/pern-app/overlays/staging/kustomization.yaml | grep "newTag:" | awk '{print $2}')
        local frontend_tag=$(grep -A 2 "name: ghcr.io/mankinimbom/pern-frontend" apps/pern-app/overlays/staging/kustomization.yaml | grep "newTag:" | awk '{print $2}')
        echo "${backend_tag}"
    else
        echo "unknown"
    fi
}

# Monitor function
monitor_updates() {
    local initial_tag=$(get_current_tags)
    local check_count=0
    local max_checks=60  # Monitor for 10 minutes (60 * 10 seconds)
    
    echo -e "${BLUE}🎯 Initial image tag: ${YELLOW}$initial_tag${NC}"
    echo -e "${BLUE}⏳ Waiting for GitHub Actions to complete and update image tags...${NC}"
    echo ""
    
    while [[ $check_count -lt $max_checks ]]; do
        # Pull latest changes
        git fetch origin main >/dev/null 2>&1
        git pull origin main >/dev/null 2>&1
        
        local current_tag=$(get_current_tags)
        local timestamp=$(date '+%H:%M:%S')
        
        if [[ "$current_tag" != "$initial_tag" ]]; then
            echo -e "${GREEN}✅ [$timestamp] SUCCESS! Image tags updated!${NC}"
            echo -e "${GREEN}   New tag: ${YELLOW}$current_tag${NC}"
            echo ""
            echo -e "${PURPLE}📋 Updated Image Tags:${NC}"
            
            # Show all environment updates
            echo "   Base:"
            grep -A 1 "newTag:" apps/pern-app/base/kustomization.yaml | sed 's/^/     /'
            echo "   Staging:"
            grep -A 1 "newTag:" apps/pern-app/overlays/staging/kustomization.yaml | sed 's/^/     /'
            echo ""
            
            # Show latest commit
            echo -e "${PURPLE}📚 Latest GitOps Commit:${NC}"
            git log --oneline -1 | sed 's/^/     /'
            echo ""
            
            echo -e "${GREEN}🎉 CI/CD Pipeline Test SUCCESSFUL!${NC}"
            echo -e "${BLUE}🔧 ArgoCD should now sync the new images to Kubernetes${NC}"
            return 0
        else
            printf "\r${YELLOW}⏳ [$timestamp] Checking... (attempt $((check_count + 1))/$max_checks) Current tag: $current_tag${NC}"
        fi
        
        sleep 10
        ((check_count++))
    done
    
    echo ""
    echo -e "${RED}❌ Timeout: No image tag updates detected after 10 minutes${NC}"
    echo -e "${YELLOW}💡 Check GitHub Actions logs for potential issues${NC}"
    return 1
}

# Change to GitOps repo if needed
if [[ ! -d "apps/pern-app" ]]; then
    echo -e "${YELLOW}📂 Switching to GitOps repository...${NC}"
    cd /home/sysadmin/pern/pern-gitops
fi

# Start monitoring
monitor_updates

echo ""
echo -e "${BLUE}🔗 Useful Links:${NC}"
echo "   GitHub Actions: https://github.com/mankinimbom/pern-app/actions"
echo "   GitOps Commits: https://github.com/mankinimbom/pern-gitops/commits/main"
echo ""
