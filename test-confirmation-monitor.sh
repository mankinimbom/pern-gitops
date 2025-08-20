#!/bin/bash

echo "🔍 CI/CD Test 2: Monitoring Image Tag Updates"
echo "=============================================="
echo ""
echo "📊 Expected new tag: a6c096d (from latest commit)"
echo "🎯 Current tag: fbaebdb"
echo "⏰ Started: $(date '+%H:%M:%S')"
echo ""

cd /home/sysadmin/pern/pern-gitops

EXPECTED_TAG="a6c096d"
CURRENT_TAG="fbaebdb"

for i in {1..24}; do  # Monitor for 12 minutes (24 * 30 seconds)
    printf "\r🔄 Check %2d/24 - %s - " "$i" "$(date '+%H:%M:%S')"
    
    # Pull latest changes quietly
    git fetch origin main >/dev/null 2>&1
    git pull origin main >/dev/null 2>&1
    
    # Get current tag from staging
    NEW_TAG=$(grep -A 2 "name: ghcr.io/mankinimbom/pern-backend" apps/pern-app/overlays/staging/kustomization.yaml | grep "newTag:" | awk '{print $2}')
    
    if [[ "$NEW_TAG" == "$EXPECTED_TAG" ]]; then
        echo ""
        echo ""
        echo "✅ SUCCESS! Image tag updated correctly!"
        echo "   Previous: $CURRENT_TAG"
        echo "   Current:  $NEW_TAG"
        echo "   Expected: $EXPECTED_TAG ✓"
        echo ""
        echo "📋 GitOps commit:"
        git log --oneline -1 | sed 's/^/   /'
        echo ""
        echo "🎉 CI/CD Pipeline confirmed working consistently!"
        echo ""
        echo "📊 Full verification:"
        echo "   Base:    $(grep -A 2 'name: ghcr.io/mankinimbom/pern-backend' apps/pern-app/base/kustomization.yaml | grep 'newTag:' | awk '{print $2}')"
        echo "   Staging: $(grep -A 2 'name: ghcr.io/mankinimbom/pern-backend' apps/pern-app/overlays/staging/kustomization.yaml | grep 'newTag:' | awk '{print $2}')"
        exit 0
    elif [[ "$NEW_TAG" != "$CURRENT_TAG" ]]; then
        echo "Tag changed: $NEW_TAG (waiting for $EXPECTED_TAG)"
        CURRENT_TAG="$NEW_TAG"
    else
        printf "Still $CURRENT_TAG"
    fi
    
    sleep 30
done

echo ""
echo ""
echo "⏰ Timeout after 12 minutes"
echo "💡 Current tag: $NEW_TAG"
echo "💡 Expected: $EXPECTED_TAG"
