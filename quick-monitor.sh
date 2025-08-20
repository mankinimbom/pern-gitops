#!/bin/bash

echo "🔍 Monitoring CI/CD Image Tag Updates"
echo "======================================"
echo ""
echo "📊 GitHub Actions: https://github.com/mankinimbom/pern-app/actions"
echo "⏰ Started monitoring at: $(date)"
echo ""

# Get initial tag
INITIAL_TAG=$(grep -A 1 "newTag:" apps/pern-app/overlays/staging/kustomization.yaml | head -1 | awk '{print $2}')
echo "🎯 Initial tag: $INITIAL_TAG"
echo ""

for i in {1..20}; do
    echo "🔄 Check $i/20 - $(date '+%H:%M:%S')"
    
    # Pull latest changes
    git fetch origin main >/dev/null 2>&1
    git pull origin main >/dev/null 2>&1
    
    # Get current tag
    CURRENT_TAG=$(grep -A 1 "newTag:" apps/pern-app/overlays/staging/kustomization.yaml | head -1 | awk '{print $2}')
    
    if [[ "$CURRENT_TAG" != "$INITIAL_TAG" ]]; then
        echo ""
        echo "✅ SUCCESS! Image tags updated!"
        echo "   Old tag: $INITIAL_TAG"
        echo "   New tag: $CURRENT_TAG"
        echo ""
        echo "📋 Latest commit:"
        git log --oneline -1
        echo ""
        echo "🎉 CI/CD Pipeline is working correctly!"
        exit 0
    else
        echo "   Current tag: $CURRENT_TAG (no change yet)"
    fi
    
    sleep 30
done

echo ""
echo "⏰ Monitoring timeout after 10 minutes"
echo "💡 Check GitHub Actions for any issues"
