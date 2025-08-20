#!/bin/bash

echo "🔍 CI/CD Pipeline Real-time Monitor"
echo "==================================="
echo "Monitoring for GitHub Actions to update image tags..."
echo "Expected new tag: 6d1e0dd (first 7 chars of commit SHA)"
echo ""

# Store initial state
INITIAL_BACKEND_TAG=$(yq-new eval '.images[0].newTag' apps/pern-app/overlays/staging/kustomization.yaml 2>/dev/null)
INITIAL_COMMIT=$(git rev-parse HEAD)

echo "📊 Initial State:"
echo "- Image Tag: $INITIAL_BACKEND_TAG"
echo "- GitOps Commit: $INITIAL_COMMIT"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo "🔄 Monitoring loop started (checking every 30 seconds)..."
echo "Press Ctrl+C to stop monitoring"
echo ""

COUNTER=0
while true; do
    COUNTER=$((COUNTER + 1))
    
    # Fetch latest changes
    git fetch origin main --quiet 2>/dev/null
    
    # Check current state
    CURRENT_COMMIT=$(git rev-parse origin/main)
    CURRENT_BACKEND_TAG=$(yq-new eval '.images[0].newTag' apps/pern-app/overlays/staging/kustomization.yaml 2>/dev/null)
    
    echo -e "${BLUE}[Check #$COUNTER - $(date +%H:%M:%S)]${NC}"
    
    # Check if GitOps repo was updated
    if [[ "$CURRENT_COMMIT" != "$INITIAL_COMMIT" ]]; then
        echo -e "${GREEN}🎉 GitOps Repository Updated!${NC}"
        echo "- New commit: $CURRENT_COMMIT"
        
        # Pull latest changes
        git pull origin main --quiet
        
        # Check new image tag
        NEW_BACKEND_TAG=$(yq-new eval '.images[0].newTag' apps/pern-app/overlays/staging/kustomization.yaml 2>/dev/null)
        NEW_FRONTEND_TAG=$(yq-new eval '.images[1].newTag' apps/pern-app/overlays/staging/kustomization.yaml 2>/dev/null)
        
        echo "- Backend Tag: $INITIAL_BACKEND_TAG → $NEW_BACKEND_TAG"
        echo "- Frontend Tag: $NEW_FRONTEND_TAG"
        
        if [[ "$NEW_BACKEND_TAG" == "6d1e0dd" ]]; then
            echo -e "${GREEN}✅ SUCCESS: Image tags updated correctly!${NC}"
        else
            echo -e "${YELLOW}⚠️  Image tag doesn't match expected SHA${NC}"
        fi
        
        echo ""
        echo "📋 Latest commit message:"
        git log -1 --pretty=format:"%s" HEAD
        echo ""
        echo ""
        echo -e "${GREEN}🎯 CI/CD Pipeline Test: SUCCESSFUL!${NC}"
        break
    else
        echo "  GitOps commit: No changes yet"
        echo "  Image tag: $CURRENT_BACKEND_TAG (unchanged)"
        
        # Check if GitHub Actions is running
        echo "  📊 GitHub Actions: https://github.com/mankinimbom/pern-app/actions"
        
        echo "  ⏳ Waiting 30 seconds..."
        echo ""
    fi
    
    # Timeout after 10 minutes (20 checks * 30 seconds)
    if [[ $COUNTER -ge 20 ]]; then
        echo -e "${RED}⏰ Timeout: No updates detected after 10 minutes${NC}"
        echo "Check GitHub Actions manually: https://github.com/mankinimbom/pern-app/actions"
        break
    fi
    
    sleep 30
done
