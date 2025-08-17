# Production-Grade PERN Stack GitOps Implementation

## 🏗️ **Architecture Overview**

This repository implements a **production-grade PERN stack deployment** using GitOps principles with ArgoCD, featuring:

- **Multi-environment management** (staging, production)
- **Advanced canary deployments** with Argo Rollouts
- **Metrics-driven automated promotion** with Prometheus analysis
- **Manual approval gates** for production deployments
- **Comprehensive security controls** and RBAC
- **High-availability ArgoCD** setup
- **Automated CI/CD pipeline** with security scanning

## 🚀 **Key Improvements Made**

### ✅ **ArgoCD Configuration Enhancements**

#### **AppProject Security Hardening**
- **Principle of least privilege** RBAC with environment-specific permissions
- **Multi-role access control** (admin, production-deployer, developer, viewer)
- **Resource whitelisting** with comprehensive Kubernetes resource coverage
- **Source repository restrictions** and signature verification
- **Orphaned resource management** with ignore patterns

#### **ApplicationSet Robustness**
- **Multi-generator approach** combining Git, Matrix, and Merge generators
- **Go templating** with error handling (`missingkey=error`)
- **Environment-specific configurations** via JSON config files
- **Progressive sync policies** with comprehensive retry mechanisms
- **Health checks and drift detection** with ignore differences
- **Comprehensive labeling and annotations** for observability

### ✅ **Rollout Strategy Improvements**

#### **Enhanced Canary Deployment**
- **Progressive traffic shifting** (5% → 15% → 30% → 60% → 100%)
- **Multi-phase analysis gates** with automated promotion/rollback
- **Comprehensive metrics validation**:
  - Success rate (≥95%)
  - Response time (P95 ≤500ms, P99 ≤1000ms)
  - Error rates (4xx ≤5%, 5xx ≤1%)
  - CPU/Memory utilization monitoring

#### **Production Manual Approval Gates**
- **Job-based manual approval** with kubectl annotation system
- **Stakeholder notification** with approval/rejection tracking
- **Smoke tests integration** post-approval
- **Extended safety delays** for production environments

#### **Advanced Analysis Templates**
- **Multi-metric analysis** with Prometheus integration
- **Failure thresholds** and success conditions
- **Resource utilization monitoring**
- **Automated rollback triggers**

### ✅ **Security Enhancements**

#### **Container Security**
- **Immutable image tags** (SHA-based, no `:latest`)
- **Security scanning** with Trivy (enabled in CI/CD)
- **SBOM generation** for compliance
- **Read-only root filesystem** with volume mounts for writable dirs
- **Non-root user execution** with security contexts
- **Capability dropping** (`ALL` capabilities removed)

#### **Kubernetes Security**
- **Pod Security Standards** (restricted for production)
- **Network policies** for micro-segmentation
- **RBAC implementation** with service accounts
- **Resource limits and requests** optimization
- **Anti-affinity rules** for high availability

### ✅ **CI/CD Pipeline Improvements**

#### **Image Management**
- **Immutable tagging strategy**: SHA-based tags for production
- **Multi-stage security scanning**: Repository + container image scanning
- **SBOM generation** and artifact storage
- **Dependency vulnerability scanning**

#### **Deployment Automation**
- **Environment-specific deployment** with proper sequencing
- **GitOps repository updates** with structured commit messages
- **Automated staging deployment** followed by manual production approval
- **Comprehensive error handling** and rollback capabilities

### ✅ **Monitoring and Observability**

#### **Comprehensive Metrics**
- **ServiceMonitor configurations** for Prometheus
- **Custom alerting rules** with severity classification
- **Health check endpoints** monitoring
- **Resource utilization tracking**

#### **Alerting Strategy**
- **Service-level alerts**: Downtime, high error rates, latency
- **Infrastructure alerts**: CPU, memory, storage
- **Deployment alerts**: Rollout failures, stuck deployments
- **Runbook integration** with alert annotations

## 📋 **Repository Structure**

```
pern-gitops/
├── apps/
│   └── pern-app/
│       ├── base/                    # Base Kubernetes manifests
│       │   ├── backend.yaml         # Enhanced Rollout with security
│       │   ├── frontend.yaml        # Frontend Rollout configuration
│       │   ├── postgresql.yaml      # StatefulSet with HA config
│       │   ├── rbac.yaml           # Service accounts and RBAC
│       │   ├── networkpolicies.yaml # Network segmentation
│       │   ├── servicemonitor.yaml  # Prometheus monitoring
│       │   ├── hpa.yaml            # Horizontal Pod Autoscaling
│       │   └── poddisruptionbudgets.yaml
│       └── overlays/
│           ├── staging/             # Staging environment
│           │   ├── config.json     # Environment-specific config
│           │   └── kustomization.yaml
│           └── production/          # Production environment
│               ├── config.json     # Production-specific config
│               ├── kustomization.yaml
│               └── rollout-backend-patch.yaml # Manual approval
├── projects/
│   ├── appproject.yaml             # Enhanced AppProject with RBAC
│   ├── applicationset.yaml         # Multi-generator ApplicationSet
│   ├── analysis-template.yaml      # Comprehensive analysis templates
│   └── manual-approval-template.yaml # Production approval gates
├── bootstrap/
│   └── root-app.yaml              # Bootstrap application
├── deploy-production-gitops.sh     # Production deployment script
└── README.md                      # This file
```

## 🚀 **Deployment Guide**

### **Prerequisites**

1. **Kubernetes cluster** (Rancher-managed)
2. **kubectl** configured for cluster access
3. **ArgoCD CLI** installed and configured
4. **GitHub Container Registry** access
5. **Prometheus** deployed in `monitoring` namespace

### **Step 1: Initial Setup**

```bash
# Clone the repository
git clone https://github.com/mankinimbom/pern-gitops.git
cd pern-gitops

# Make deployment script executable
chmod +x deploy-production-gitops.sh

# Run prerequisite check
./deploy-production-gitops.sh validate
```

### **Step 2: Deploy ArgoCD HA**

```bash
# Deploy ArgoCD in High Availability mode
./deploy-production-gitops.sh deploy
```

### **Step 3: Configure ArgoCD Access**

```bash
# Get ArgoCD admin password
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d

# Login to ArgoCD
argocd login https://argo-ui.ankinimbom.com --username admin

# Update admin password
argocd account update-password
```

### **Step 4: Validate Deployment**

```bash
# Check application status
./deploy-production-gitops.sh validate

# Generate deployment report
./deploy-production-gitops.sh report
```

## 🔄 **Deployment Workflow**

### **Staging Deployment (Automated)**

1. **Code push** to `main` branch triggers CI/CD
2. **Automated testing** (frontend, backend, security scans)
3. **Container image build** with immutable SHA-based tags
4. **Staging deployment** via GitOps repository update
5. **Canary analysis** with automated promotion

### **Production Deployment (Manual Approval)**

1. **Staging success** triggers production pipeline
2. **Manual approval gate** with stakeholder notification
3. **Progressive canary deployment**:
   - 5% traffic → automated analysis
   - 15% traffic → extended monitoring
   - 30% traffic → **manual approval required**
   - 60% traffic → smoke tests
   - 100% traffic → full deployment

### **Rollback Procedure**

```bash
# Rollback specific application
./deploy-production-gitops.sh rollback pern-app-production

# Rollback to specific revision
./deploy-production-gitops.sh rollback pern-app-production abc123

# Emergency rollback via ArgoCD UI
# Navigate to application → History → Rollback
```

## 📊 **Monitoring and Alerting**

### **Key Metrics Monitored**

- **Success Rate**: ≥95% (critical threshold: <90%)
- **Response Time**: P95 ≤500ms, P99 ≤1000ms
- **Error Rates**: 4xx ≤5%, 5xx ≤1%
- **Resource Utilization**: CPU ≤80%, Memory ≤85%
- **Database Connections**: ≤80% of max connections

### **Alert Channels**

- **Slack Integration**: Real-time alerts and deployment notifications
- **GitHub Issues**: Automated issue creation for failures
- **ArgoCD Notifications**: Deployment status updates

## 🔒 **Security Features**

### **Container Security**
- ✅ **No privileged containers**
- ✅ **Read-only root filesystem**
- ✅ **Non-root user execution**
- ✅ **Dropped capabilities**
- ✅ **Security scanning** (Trivy)

### **Kubernetes Security**
- ✅ **Network policies** for traffic segmentation
- ✅ **RBAC** with least privilege
- ✅ **Pod Security Standards**
- ✅ **Resource quotas** and limits
- ✅ **Service account tokens** (auto-mount disabled)

### **GitOps Security**
- ✅ **Signed commits** verification
- ✅ **Repository access control**
- ✅ **Environment isolation**
- ✅ **Audit logging**

## 🛠️ **Troubleshooting**

### **Common Issues**

#### **Application Stuck in Progressing State**
```bash
# Check rollout status
kubectl describe rollout backend -n pern-app-production

# Check analysis runs
kubectl get analysisruns -n pern-app-production

# Manual intervention
kubectl annotate rollout backend -n pern-app-production deployment.argoproj.io/approved=true
```

#### **Analysis Template Failures**
```bash
# Check Prometheus connectivity
kubectl exec -n pern-app-production deployment/backend -- curl -s http://prometheus-server.monitoring.svc.cluster.local:80/api/v1/query?query=up

# Validate metrics
kubectl logs -n pern-app-production -l app=backend
```

#### **Manual Approval Not Working**
```bash
# Check approval job status
kubectl get jobs -n pern-app-production -l app=manual-approval

# Approve manually
kubectl annotate rollout backend -n pern-app-production deployment.argoproj.io/approved=true --overwrite

# Reject deployment
kubectl annotate rollout backend -n pern-app-production deployment.argoproj.io/rejected=true --overwrite
```

## 📈 **Performance Optimization**

### **Resource Allocation**

#### **Production Environment**
- **Backend**: 5 replicas, 500m CPU, 1Gi memory
- **Frontend**: 3 replicas, 200m CPU, 256Mi memory
- **PostgreSQL**: HA setup, 500m CPU, 1Gi memory

#### **Staging Environment**
- **Backend**: 2 replicas, 200m CPU, 512Mi memory
- **Frontend**: 2 replicas, 100m CPU, 256Mi memory

### **Auto-scaling Configuration**
- **HPA**: CPU 70%, Memory 80%
- **Scale up**: Max 100% increase per minute
- **Scale down**: Max 50% decrease per 5 minutes

## 🔄 **Maintenance**

### **Regular Tasks**

1. **Update dependencies** in CI/CD pipeline
2. **Review security scans** and patch vulnerabilities
3. **Monitor resource usage** and optimize allocations
4. **Update ArgoCD** and Argo Rollouts versions
5. **Review and rotate secrets** quarterly

### **Backup Strategy**

- **Database backups**: Automated daily snapshots
- **Configuration backups**: Git repository versioning
- **Disaster recovery**: Multi-region deployment ready

## 🤝 **Contributing**

1. **Fork** the repository
2. **Create feature branch**: `git checkout -b feature/enhancement`
3. **Follow security practices**: No secrets in commits
4. **Test thoroughly**: All environments
5. **Submit PR**: With detailed description

## 📞 **Support**

- **Documentation**: [Internal Wiki](https://docs.ankinimbom.com)
- **Runbooks**: [Incident Response](https://docs.ankinimbom.com/runbooks)
- **Monitoring**: [Grafana Dashboard](https://monitoring.ankinimbom.com)
- **Alerts**: [ArgoCD UI](https://argo-ui.ankinimbom.com)

---

**⚡ Production-Ready PERN Stack with Enterprise GitOps**

*Featuring automated CI/CD, canary deployments, metrics-driven rollouts, and comprehensive security controls.*
