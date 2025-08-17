# PERN Stack GitOps Repository

This repository contains the GitOps configuration for the PERN (PostgreSQL, Express, React, Node.js) stack application, following ArgoCD best practices for production-ready deployments.

## Repository Structure

```
pern-gitops/
├── kustomization.yaml              # Root kustomization for app-of-apps pattern
├── README.md                       # This file
├── .gitignore                     # Git ignore patterns
│
├── bootstrap/                      # Bootstrap configurations
│   └── root-app.yaml             # Root ArgoCD application (app-of-apps)
│
├── projects/                       # ArgoCD project definitions
│   ├── appproject.yaml            # Main application project with RBAC
│   ├── applicationset.yaml        # ApplicationSet for multi-environment management
│   └── analysis-template.yaml     # Argo Rollouts analysis templates
│
└── apps/                          # Application definitions
    ├── pern-app-production.yaml   # Production application
    ├── pern-app-staging.yaml     # Staging application  
    └── pern-app/                  # Main application structure
        ├── base/                  # Base Kustomize configuration
        │   ├── kustomization.yaml # Base resources list with sync ordering
        │   ├── namespace.yaml     # Base namespace definition
        │   ├── secrets.yaml       # Application secrets
        │   ├── postgresql.yaml    # PostgreSQL StatefulSet
        │   ├── redis.yaml        # Redis Deployment
        │   ├── backend.yaml       # Backend Argo Rollout
        │   ├── frontend.yaml      # Frontend Argo Rollout  
        │   ├── ingress.yaml       # Ingress configuration
        │   ├── hpa.yaml          # Horizontal Pod Autoscaler
        │   ├── poddisruptionbudgets.yaml # Pod Disruption Budgets
        │   ├── networkpolicies.yaml     # Network security policies
        │   └── servicemonitor.yaml      # Prometheus monitoring
        └── overlays/              # Environment-specific configurations
            ├── production/        # Production overlay
            │   ├── kustomization.yaml    # Production-specific configs
            │   ├── namespace-patch.yaml  # Production namespace
            │   ├── replica-patch.yaml    # Higher replica counts
            │   └── resource-patch.yaml   # Production resource limits
            └── staging/           # Staging overlay
                ├── kustomization.yaml    # Staging-specific configs
                └── namespace-patch.yaml  # Staging namespace
```

## ArgoCD Best Practices Implemented

### 1. **App-of-Apps Pattern**
- Root application (`bootstrap/root-app.yaml`) manages all child applications
- Hierarchical application management for better organization
- Centralized management of application lifecycle

### 2. **Proper Resource Separation**
- **Frontend**: React application served via Nginx
- **Backend**: Node.js/Express API with canary deployments
- **Database**: PostgreSQL StatefulSet with persistent storage
- **Cache**: Redis deployment for session management
- **Infrastructure**: Ingress, monitoring, security policies

### 3. **Environment Management**
- **Base**: Common configuration shared across environments
- **Overlays**: Environment-specific customizations using Kustomize
- **Namespace Isolation**: Separate namespaces per environment
- **Resource Scaling**: Different replica counts and resources per environment

### 4. **Sync Wave Orchestration**
```
Wave 0: Namespaces, Secrets, ConfigMaps, PVCs
Wave 1: Database and Cache (PostgreSQL, Redis)
Wave 2: Backend services
Wave 3: Frontend services  
Wave 4: Ingress and networking
Wave 5: Policies, monitoring, and scaling (HPA, NetworkPolicies, ServiceMonitors)
```

### 5. **Progressive Delivery**
- **Argo Rollouts**: Canary deployments for both frontend and backend
- **Analysis Templates**: Automated success rate analysis during deployments
- **Traffic Routing**: Nginx-based traffic splitting
- **Rollback Capability**: Automated rollback on failed deployments

### 6. **Security Best Practices**
- **Network Policies**: Microsegmentation between services
- **RBAC**: Role-based access control with least privilege
- **Secret Management**: Kubernetes secrets with proper labeling
- **Pod Disruption Budgets**: Maintain availability during updates
- **Security Context**: Non-root containers with specific user IDs

### 7. **Monitoring and Observability**
- **ServiceMonitors**: Prometheus metrics collection
- **Health Checks**: Proper liveness, readiness, and startup probes
- **Resource Monitoring**: CPU and memory-based autoscaling

### 8. **Multi-Environment Support**
- **ApplicationSet**: Automated environment provisioning
- **Git-based Discovery**: Automatic environment detection from repository structure
- **Environment-specific Labels**: Proper resource tagging and organization

## Deployment Flow

1. **Bootstrap Phase**: Deploy root application to ArgoCD
2. **Project Setup**: Create AppProject with RBAC policies
3. **Application Discovery**: ApplicationSet discovers environments
4. **Resource Deployment**: Sync waves ensure proper ordering
5. **Progressive Rollout**: Canary deployments with analysis
6. **Monitoring Setup**: ServiceMonitors enable metrics collection

## Environment Configuration

### Production
- **Namespace**: `pern-app-production`
- **Replicas**: 5 for both frontend and backend
- **Resources**: Higher CPU/memory limits
- **Storage**: Production-grade persistent volumes
- **Sync Policy**: Manual sync during business hours

### Staging
- **Namespace**: `pern-app-staging`  
- **Replicas**: 3 for both frontend and backend
- **Resources**: Moderate CPU/memory limits
- **Auto-sync**: Enabled for continuous deployment
- **Testing**: Pre-production validation environment

## Security Features

### Network Policies
- **Backend**: Only accepts traffic from frontend and ingress
- **Frontend**: Only accepts traffic from ingress controller
- **Database**: Only accepts traffic from backend
- **DNS**: Allows DNS resolution for all pods

### RBAC Configuration
- **Admin Role**: Full access to all applications and resources
- **Developer Role**: Sync and view access to applications
- **Viewer Role**: Read-only access to applications

## Getting Started

1. **Bootstrap ArgoCD**:
   ```bash
   kubectl apply -f bootstrap/root-app.yaml
   ```

2. **Monitor Deployment**:
   ```bash
   argocd app get pern-app-root
   argocd app sync pern-app-root
   ```

3. **Access Applications**:
   - Production: `https://pern-app.ankinimbom.com`
   - Staging: `https://staging-pern-app.ankinimbom.com`

## Customization

### Adding New Environments
1. Create new overlay directory under `apps/pern-app/overlays/`
2. Add `kustomization.yaml` with environment-specific configuration
3. ApplicationSet will automatically discover and deploy the new environment

### Updating Images
Images are automatically updated through CI/CD pipelines that modify the `images` section in environment-specific `kustomization.yaml` files.

### Scaling Configuration
Adjust HPA settings in the base configuration or create environment-specific patches for different scaling behavior.

## Monitoring and Troubleshooting

### ArgoCD Dashboard
Monitor application health and sync status through the ArgoCD web interface.

### Sync Issues
Use sync waves and dependency management to resolve resource ordering issues:
```bash
argocd app sync <app-name> --strategy hook
```

### Rollback Procedures
Argo Rollouts provides automatic rollback capabilities. Manual rollback:
```bash
kubectl argo rollouts undo backend -n pern-app-production
```

## Contributing

1. Make changes to base configuration or overlays
2. Test in staging environment first
3. Submit PR with proper validation
4. Production deployments require manual approval

This GitOps repository implements enterprise-grade practices for reliable, scalable, and secure application deployments using ArgoCD and Kubernetes.
