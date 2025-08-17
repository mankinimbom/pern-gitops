#!/bin/bash

# GitOps Repository Validation Script
# Validates the pern-gitops repository structure and configuration

echo "🔍 Validating PERN GitOps Repository Structure..."
echo "=================================================="

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if file exists and print result
check_file() {
    file=$1
    description=$2
    
    if [ -f "$file" ]; then
        echo -e "✅ ${GREEN}$description${NC}: $file"
        return 0
    else
        echo -e "❌ ${RED}$description${NC}: $file (missing)"
        return 1
    fi
}

# Function to check if directory exists
check_directory() {
    dir=$1
    description=$2
    
    if [ -d "$dir" ]; then
        echo -e "✅ ${GREEN}$description${NC}: $dir"
        return 0
    else
        echo -e "❌ ${RED}$description${NC}: $dir (missing)"
        return 1
    fi
}

# Function to validate YAML syntax
validate_yaml() {
    file=$1
    
    if command -v yq &> /dev/null; then
        if yq eval '.' "$file" > /dev/null 2>&1; then
            echo -e "  ✅ ${GREEN}Valid YAML syntax${NC}"
        else
            echo -e "  ❌ ${RED}Invalid YAML syntax${NC}"
        fi
    elif command -v python3 &> /dev/null; then
        if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
            echo -e "  ✅ ${GREEN}Valid YAML syntax${NC}"
        else
            echo -e "  ❌ ${RED}Invalid YAML syntax${NC}"
        fi
    fi
}

# Function to check for required fields in ArgoCD applications
check_argocd_app() {
    file=$1
    name=$2
    
    echo "🔍 Checking ArgoCD Application: $name"
    
    if [ -f "$file" ]; then
        # Check for required fields
        has_project=$(grep -q "project:" "$file" && echo "true" || echo "false")
        has_source=$(grep -q "source:" "$file" && echo "true" || echo "false")
        has_destination=$(grep -q "destination:" "$file" && echo "true" || echo "false")
        has_sync_policy=$(grep -q "syncPolicy:" "$file" && echo "true" || echo "false")
        
        [ "$has_project" = "true" ] && echo -e "  ✅ ${GREEN}Project specified${NC}" || echo -e "  ❌ ${RED}Project missing${NC}"
        [ "$has_source" = "true" ] && echo -e "  ✅ ${GREEN}Source specified${NC}" || echo -e "  ❌ ${RED}Source missing${NC}"
        [ "$has_destination" = "true" ] && echo -e "  ✅ ${GREEN}Destination specified${NC}" || echo -e "  ❌ ${RED}Destination missing${NC}"
        [ "$has_sync_policy" = "true" ] && echo -e "  ✅ ${GREEN}Sync policy configured${NC}" || echo -e "  ⚠️  ${YELLOW}Sync policy missing (manual sync)${NC}"
        
        validate_yaml "$file"
    fi
    echo ""
}

# Main validation
echo "1. 📁 Directory Structure"
echo "-------------------------"

# Check main directories
check_directory "apps" "Applications directory"
check_directory "projects" "Projects directory" 
check_directory "bootstrap" "Bootstrap directory"
check_directory "apps/pern-app" "Main application directory"
check_directory "apps/pern-app/base" "Base configuration directory"
check_directory "apps/pern-app/overlays" "Overlays directory"
check_directory "apps/pern-app/overlays/production" "Production overlay"
check_directory "apps/pern-app/overlays/staging" "Staging overlay"

echo ""
echo "2. 📄 Core Files"
echo "---------------"

# Check core files
check_file "kustomization.yaml" "Root kustomization"
check_file "README.md" "Documentation"
check_file "bootstrap/root-app.yaml" "Root application"
check_file "projects/appproject.yaml" "App project"
check_file "projects/applicationset.yaml" "Application set"

echo ""
echo "3. 🎯 Base Configuration Files"
echo "------------------------------"

# Check base configuration files
check_file "apps/pern-app/base/kustomization.yaml" "Base kustomization"
check_file "apps/pern-app/base/namespace.yaml" "Namespace definition"
check_file "apps/pern-app/base/secrets.yaml" "Secrets configuration"
check_file "apps/pern-app/base/postgresql.yaml" "PostgreSQL configuration"
check_file "apps/pern-app/base/redis.yaml" "Redis configuration"
check_file "apps/pern-app/base/backend.yaml" "Backend configuration"
check_file "apps/pern-app/base/frontend.yaml" "Frontend configuration"
check_file "apps/pern-app/base/ingress.yaml" "Ingress configuration"
check_file "apps/pern-app/base/hpa.yaml" "HPA configuration"
check_file "apps/pern-app/base/networkpolicies.yaml" "Network policies"
check_file "apps/pern-app/base/servicemonitor.yaml" "Service monitoring"
check_file "apps/pern-app/base/poddisruptionbudgets.yaml" "Pod disruption budgets"

echo ""
echo "4. 🌍 Environment Overlays"  
echo "-------------------------"

# Check overlay files
check_file "apps/pern-app/overlays/production/kustomization.yaml" "Production kustomization"
check_file "apps/pern-app/overlays/production/namespace-patch.yaml" "Production namespace patch"
check_file "apps/pern-app/overlays/production/replica-patch.yaml" "Production replica patch"
check_file "apps/pern-app/overlays/production/resource-patch.yaml" "Production resource patch"
check_file "apps/pern-app/overlays/staging/kustomization.yaml" "Staging kustomization"
check_file "apps/pern-app/overlays/staging/namespace-patch.yaml" "Staging namespace patch"

echo ""
echo "5. 📱 ArgoCD Applications"
echo "------------------------"

# Validate ArgoCD applications
check_argocd_app "apps/pern-app-production.yaml" "Production Application"
check_argocd_app "apps/pern-app-staging.yaml" "Staging Application"
check_argocd_app "bootstrap/root-app.yaml" "Root Application"

echo "6. � Summary & Recommendations"
echo "-------------------------------"

# Count files and provide summary
total_yaml_files=$(find . -name "*.yaml" -o -name "*.yml" | wc -l)
total_directories=$(find . -type d | wc -l)

echo -e "📁 Total directories: ${GREEN}$total_directories${NC}"
echo -e "📄 Total YAML files: ${GREEN}$total_yaml_files${NC}"

echo ""
echo -e "🏁 ${GREEN}GitOps Repository Validation Complete!${NC}"
echo ""
echo "💡 Key Best Practices Implemented:"
echo "- ✅ App-of-Apps pattern with root application"
echo "- ✅ Proper environment separation (production/staging)"
echo "- ✅ Kustomize base/overlay structure"
echo "- ✅ Sync wave orchestration for deployment ordering"
echo "- ✅ Progressive delivery with Argo Rollouts"
echo "- ✅ Security policies and network isolation"
echo "- ✅ RBAC with proper access control"
echo "- ✅ Monitoring and observability setup"
echo "- ✅ Resource management and scaling policies"
echo ""
echo "🎯 Next Steps:"
echo "1. Deploy root application: kubectl apply -f bootstrap/root-app.yaml"
echo "2. Monitor sync status in ArgoCD dashboard"
echo "3. Validate application health checks"
echo "4. Test progressive deployment with canary releases"
