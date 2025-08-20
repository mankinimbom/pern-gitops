#!/bin/bash

echo "🧪 Testing GitHub Actions Image Update with Correct yq"
echo "====================================================="

# Install the correct yq version like GitHub Actions does
echo "📦 Installing mikefarah/yq (Go version)..."
sudo wget -qO /usr/local/bin/yq-new https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq-new

# Test with new yq
SHORT_SHA="test456"
echo ""
echo "🔧 Testing with new yq version:"
echo "Version: $(/usr/local/bin/yq-new --version)"

echo ""
echo "📋 Current image tags:"
echo "Staging backend: $(/usr/local/bin/yq-new eval '.images[0].newTag' apps/pern-app/overlays/staging/kustomization.yaml)"
echo "Staging frontend: $(/usr/local/bin/yq-new eval '.images[1].newTag' apps/pern-app/overlays/staging/kustomization.yaml)"

echo ""
echo "🔧 Simulating GitHub Actions update commands:"

# Create backup copies
cp apps/pern-app/overlays/staging/kustomization.yaml apps/pern-app/overlays/staging/kustomization.yaml.backup
cp apps/pern-app/base/kustomization.yaml apps/pern-app/base/kustomization.yaml.backup

# Test the exact commands from GitHub Actions
echo "Updating staging with new tag: ${SHORT_SHA}"
/usr/local/bin/yq-new eval ".images[0].newTag = \"${SHORT_SHA}\"" -i apps/pern-app/overlays/staging/kustomization.yaml
/usr/local/bin/yq-new eval ".images[1].newTag = \"${SHORT_SHA}\"" -i apps/pern-app/overlays/staging/kustomization.yaml

echo "Updating base with new tag: ${SHORT_SHA}"
/usr/local/bin/yq-new eval ".images[0].newTag = \"${SHORT_SHA}\"" -i apps/pern-app/base/kustomization.yaml
/usr/local/bin/yq-new eval ".images[1].newTag = \"${SHORT_SHA}\"" -i apps/pern-app/base/kustomization.yaml

echo ""
echo "📋 Updated image tags:"
echo "Staging backend: $(/usr/local/bin/yq-new eval '.images[0].newTag' apps/pern-app/overlays/staging/kustomization.yaml)"
echo "Staging frontend: $(/usr/local/bin/yq-new eval '.images[1].newTag' apps/pern-app/overlays/staging/kustomization.yaml)"
echo "Base backend: $(/usr/local/bin/yq-new eval '.images[0].newTag' apps/pern-app/base/kustomization.yaml)"
echo "Base frontend: $(/usr/local/bin/yq-new eval '.images[1].newTag' apps/pern-app/base/kustomization.yaml)"

echo ""
echo "🔄 Restoring original files..."
mv apps/pern-app/overlays/staging/kustomization.yaml.backup apps/pern-app/overlays/staging/kustomization.yaml
mv apps/pern-app/base/kustomization.yaml.backup apps/pern-app/base/kustomization.yaml

echo ""
echo "✅ Test completed! GitHub Actions image update mechanism should work correctly."
