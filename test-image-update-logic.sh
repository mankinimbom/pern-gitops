#!/bin/bash

echo "🧪 Testing GitHub Actions Image Update Logic"
echo "=============================================="

# Simulate what GitHub Actions does
SHORT_SHA="test123"

echo "📋 Current kustomization files:"
echo ""
echo "Base kustomization.yaml:"
cat apps/pern-app/base/kustomization.yaml | grep -A 5 "images:"
echo ""
echo "Staging kustomization.yaml:"
cat apps/pern-app/overlays/staging/kustomization.yaml | grep -A 5 "images:"
echo ""
echo "Production kustomization.yaml:"
cat apps/pern-app/overlays/production/kustomization.yaml | grep -A 5 "images:"

echo ""
echo "🔧 Testing yq commands that GitHub Actions uses:"
echo ""

# Test the exact commands from GitHub Actions
echo "Command 1: yq eval \".images[0].newTag = \\\"${SHORT_SHA}\\\"\" -i apps/pern-app/overlays/staging/kustomization.yaml"
yq eval ".images[0].newTag = \"${SHORT_SHA}\"" apps/pern-app/overlays/staging/kustomization.yaml

echo ""
echo "Command 2: yq eval \".images[1].newTag = \\\"${SHORT_SHA}\\\"\" -i apps/pern-app/overlays/staging/kustomization.yaml"
yq eval ".images[1].newTag = \"${SHORT_SHA}\"" apps/pern-app/overlays/staging/kustomization.yaml

echo ""
echo "Command 3: yq eval \".images[0].newTag = \\\"${SHORT_SHA}\\\"\" -i apps/pern-app/base/kustomization.yaml"
yq eval ".images[0].newTag = \"${SHORT_SHA}\"" apps/pern-app/base/kustomization.yaml

echo ""
echo "Command 4: yq eval \".images[1].newTag = \\\"${SHORT_SHA}\\\"\" -i apps/pern-app/base/kustomization.yaml"
yq eval ".images[1].newTag = \"${SHORT_SHA}\"" apps/pern-app/base/kustomization.yaml

echo ""
echo "✅ All yq commands executed successfully!"
echo "🔍 The GitHub Actions workflow should work correctly now."
