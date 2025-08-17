#!/bin/bash

# Production-Grade PERN Stack GitOps Deployment Script
# This script implements enterprise-grade deployment practices

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITOPS_REPO="https://github.com/mankinimbom/pern-gitops"
ARGOCD_NAMESPACE="argocd"
ENVIRONMENTS=("staging" "production")
REQUIRED_TOOLS=("kubectl" "argocd" "helm")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    for tool in "${REQUIRED_TOOLS[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "$tool is required but not installed"
            exit 1
        fi
    done
    
    # Check kubectl cluster connection
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
    
    # Check ArgoCD CLI connection
    if ! argocd cluster list &> /dev/null; then
        log_warning "ArgoCD CLI not connected. Run: argocd login https://argo-ui.ankinimbom.com"
    fi
    
    log_success "Prerequisites check completed"
}

# Deploy ArgoCD with HA configuration
deploy_argocd_ha() {
    log_info "Deploying ArgoCD in HA mode..."
    
    # Create namespace
    kubectl create namespace "$ARGOCD_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
    
    # Apply ArgoCD HA configuration
    local argocd_ha_file="/home/rancher/pern/pern-app/k8s/argocd/argocd-ha.yaml"
    if [[ -f "$argocd_ha_file" ]]; then
        kubectl apply -f "$argocd_ha_file"
    else
        log_error "ArgoCD HA configuration file not found at: $argocd_ha_file"
        exit 1
    fi
    
    # Wait for ArgoCD to be ready
    log_info "Waiting for ArgoCD components to be ready..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n "$ARGOCD_NAMESPACE" --timeout=300s
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-application-controller -n "$ARGOCD_NAMESPACE" --timeout=300s
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-repo-server -n "$ARGOCD_NAMESPACE" --timeout=300s
    
    log_success "ArgoCD HA deployment completed"
}

# Deploy AppProject with security configurations
deploy_appproject() {
    log_info "Deploying PERN AppProject with security configurations..."
    
    kubectl apply -f "$SCRIPT_DIR/projects/appproject.yaml"
    
    # Wait for AppProject to be ready
    until kubectl get appproject pern-app -n "$ARGOCD_NAMESPACE" &> /dev/null; do
        log_info "Waiting for AppProject to be created..."
        sleep 5
    done
    
    log_success "AppProject deployed successfully"
}

# Deploy ApplicationSet
deploy_applicationset() {
    log_info "Deploying ApplicationSet for multi-environment management..."
    
    kubectl apply -f "$SCRIPT_DIR/projects/applicationset.yaml"
    
    # Wait for ApplicationSet to be ready
    until kubectl get applicationset pern-app-set -n "$ARGOCD_NAMESPACE" &> /dev/null; do
        log_info "Waiting for ApplicationSet to be created..."
        sleep 5
    done
    
    log_success "ApplicationSet deployed successfully"
}

# Deploy analysis templates
deploy_analysis_templates() {
    log_info "Deploying Analysis Templates for automated rollout validation..."
    
    # Create namespaces for environments
    for env in "${ENVIRONMENTS[@]}"; do
        kubectl create namespace "pern-app-$env" --dry-run=client -o yaml | kubectl apply -f -
    done
    
    # Deploy analysis templates
    kubectl apply -f "$SCRIPT_DIR/projects/analysis-template.yaml"
    kubectl apply -f "$SCRIPT_DIR/projects/manual-approval-template.yaml"
    
    log_success "Analysis Templates deployed successfully"
}

# Deploy root application
deploy_root_application() {
    log_info "Deploying Root Application for GitOps bootstrap..."
    
    kubectl apply -f "$SCRIPT_DIR/bootstrap/root-app.yaml"
    
    # Wait for root application to sync
    log_info "Waiting for Root Application to sync..."
    sleep 30
    
    # Check application status
    argocd app sync pern-app-root --force || log_warning "Root application sync may have issues"
    
    log_success "Root Application deployed successfully"
}

# Validate deployment
validate_deployment() {
    log_info "Validating deployment..."
    
    # Check ArgoCD applications
    local app_count=$(argocd app list --output name | grep -c "pern-app" || echo "0")
    if [[ $app_count -gt 0 ]]; then
        log_success "Found $app_count PERN applications in ArgoCD"
    else
        log_error "No PERN applications found in ArgoCD"
        return 1
    fi
    
    # Check application health
    for env in "${ENVIRONMENTS[@]}"; do
        local app_name="pern-app-$env"
        if argocd app get "$app_name" &> /dev/null; then
            local health=$(argocd app get "$app_name" -o json | jq -r '.status.health.status // "Unknown"')
            local sync=$(argocd app get "$app_name" -o json | jq -r '.status.sync.status // "Unknown"')
            
            if [[ "$health" == "Healthy" && "$sync" == "Synced" ]]; then
                log_success "Application $app_name is Healthy and Synced"
            else
                log_warning "Application $app_name status: Health=$health, Sync=$sync"
            fi
        else
            log_warning "Application $app_name not found"
        fi
    done
    
    # Check rollouts
    for env in "${ENVIRONMENTS[@]}"; do
        local namespace="pern-app-$env"
        if kubectl get namespace "$namespace" &> /dev/null; then
            local rollout_count=$(kubectl get rollouts -n "$namespace" --no-headers 2>/dev/null | wc -l)
            log_info "Environment $env has $rollout_count rollouts"
        fi
    done
}

# Setup monitoring
setup_monitoring() {
    log_info "Setting up monitoring and alerting..."
    
    # Deploy ServiceMonitors and PrometheusRules
    for env in "${ENVIRONMENTS[@]}"; do
        local namespace="pern-app-$env"
        if kubectl get namespace "$namespace" &> /dev/null; then
            # Apply monitoring configuration
            kubectl apply -f "$SCRIPT_DIR/apps/pern-app/base/servicemonitor.yaml" -n "$namespace" || log_warning "ServiceMonitor deployment failed for $env"
        fi
    done
    
    log_success "Monitoring setup completed"
}

# Generate deployment report
generate_report() {
    log_info "Generating deployment report..."
    
    local report_file="deployment-report-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "PERN Stack GitOps Deployment Report"
        echo "Generated: $(date)"
        echo "======================================"
        echo
        
        echo "ArgoCD Status:"
        kubectl get pods -n "$ARGOCD_NAMESPACE" -l app.kubernetes.io/part-of=argocd
        echo
        
        echo "Applications Status:"
        argocd app list || echo "ArgoCD CLI not available"
        echo
        
        echo "Environment Resources:"
        for env in "${ENVIRONMENTS[@]}"; do
            local namespace="pern-app-$env"
            echo "Environment: $env"
            if kubectl get namespace "$namespace" &> /dev/null; then
                kubectl get rollouts,services,ingress -n "$namespace" 2>/dev/null || echo "No resources found"
            else
                echo "Namespace not found"
            fi
            echo "---"
        done
        
    } > "$report_file"
    
    log_success "Deployment report saved to: $report_file"
}

# Rollback function
rollback_application() {
    local app_name=${1:-}
    local revision=${2:-}
    
    if [[ -z "$app_name" ]]; then
        log_error "Application name required for rollback"
        return 1
    fi
    
    log_info "Rolling back application: $app_name"
    
    if [[ -n "$revision" ]]; then
        argocd app rollback "$app_name" "$revision"
    else
        argocd app rollback "$app_name"
    fi
    
    log_success "Rollback initiated for $app_name"
}

# Main deployment function
main() {
    local action=${1:-"deploy"}
    
    case $action in
        "deploy")
            log_info "Starting production-grade PERN Stack deployment..."
            check_prerequisites
            deploy_argocd_ha
            deploy_appproject
            deploy_analysis_templates
            deploy_applicationset
            deploy_root_application
            setup_monitoring
            validate_deployment
            generate_report
            log_success "Deployment completed successfully!"
            ;;
        "validate")
            log_info "Validating existing deployment..."
            check_prerequisites
            validate_deployment
            ;;
        "rollback")
            local app_name=${2:-}
            local revision=${3:-}
            rollback_application "$app_name" "$revision"
            ;;
        "report")
            generate_report
            ;;
        *)
            echo "Usage: $0 [deploy|validate|rollback|report] [app_name] [revision]"
            echo
            echo "Commands:"
            echo "  deploy     - Deploy complete PERN GitOps infrastructure"
            echo "  validate   - Validate existing deployment"
            echo "  rollback   - Rollback application to previous version"
            echo "  report     - Generate deployment report"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
