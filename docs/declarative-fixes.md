# Declarative Fixes Applied to PERN GitOps

This document outlines all the fixes that were previously applied using ad-hoc `kubectl` commands and have now been made declarative.

## 🔧 Fixes Applied

### 1. ArgoCD Project Permissions (`projects/appproject.yaml`)

**Issue**: Root application failing with "resource not permitted" errors for `AppProject` and `ApplicationSet`.

**Fix Applied**:
```yaml
namespaceResourceWhitelist:
  # ... existing resources ...
  - group: argoproj.io
    kind: AppProject
  - group: argoproj.io
    kind: ApplicationSet
```

**Previous Ad-hoc Command**:
```bash
kubectl -n argocd patch appproject pern-app --type='merge' -p='{"spec":{"namespaceResourceWhitelist":[...]}}'
```

### 2. GHCR Image Pull Secrets (`bootstrap/secrets/`)

**Issue**: Pods failing with `ImagePullBackOff` due to missing GHCR authentication.

**Fix Applied**: Created declarative secret templates and generation script:
- `bootstrap/secrets/ghcr-image-pull-secrets.yaml` (template)
- `bootstrap/secrets/generate-secrets.sh` (generator)

**Previous Ad-hoc Commands**:
```bash
kubectl -n pern-app-production create secret docker-registry ghcr-creds \
  --docker-server=ghcr.io --docker-username=mankinimbom \
  --docker-password=${GITHUB_PAT} --docker-email=mankinimbom@users.noreply.github.com

kubectl -n pern-app-staging create secret docker-registry ghcr-creds \
  --docker-server=ghcr.io --docker-username=mankinimbom \
  --docker-password=${GITHUB_PAT} --docker-email=mankinimbom@users.noreply.github.com
```

### 3. ArgoCD Repository Secret (`bootstrap/secrets/`)

**Issue**: ArgoCD unable to access GitOps repository - "repository not added to argocd".

**Fix Applied**: Created declarative repository secret template:
- `bootstrap/secrets/argocd-repo-secret.yaml` (template)
- Proper labeling with `argocd.argoproj.io/secret-type: repository`

**Previous Ad-hoc Commands**:
```bash
kubectl -n argocd create secret generic pern-gitops-repo \
  --from-literal=type=git \
  --from-literal=url=https://github.com/mankinimbom/pern-gitops \
  --from-literal=password=${GITHUB_PAT} \
  --from-literal=username=mankinimbom

kubectl -n argocd label secret pern-gitops-repo argocd.argoproj.io/secret-type=repository
```

### 4. Strategic Merge Patch Issues

**Issue**: Kustomize strategic merge patches removing image fields during overlay application.

**Fix Applied**: Added explicit image fields to resource patches in:
- `apps/pern-app/overlays/production/resource-patch.yaml`
- `apps/pern-app/overlays/staging/resource-patch.yaml`

**Files Modified**: Already committed to repository in previous sessions.

### 5. Node.js 20 LTS Upgrade

**Issue**: Compatibility issues with Node.js 18 and missing build tools in Dockerfiles.

**Fix Applied**: 
- Updated Dockerfiles to Node.js 20 LTS
- Added comprehensive build toolchains
- Updated Prisma binaryTargets for OpenSSL 3 compatibility

**Files Modified**: 
- `pern-app/apps/backend/Dockerfile`
- `pern-app/apps/frontend/Dockerfile`
- `pern-app/apps/backend/prisma/schema.prisma`

## 🚀 New Declarative Setup Process

Instead of running ad-hoc commands, the entire setup can now be done declaratively:

```bash
# Set GitHub PAT for secret generation
export GITHUB_PAT=your_github_personal_access_token

# Run the declarative setup
cd /path/to/pern-gitops
./bootstrap/declarative-setup.sh
```

This script will:
1. ✅ Apply ArgoCD project with all necessary permissions
2. ✅ Apply all ArgoCD project resources
3. ✅ Generate and apply secrets (if GITHUB_PAT provided)
4. ✅ Restart ArgoCD components
5. ✅ Wait for ArgoCD to be ready
6. ✅ Apply root application
7. ✅ Refresh all applications
8. ✅ Check final status

## 🔐 Security Considerations

### Current State (Development)
- Secrets are generated with actual credentials for immediate functionality
- GitHub PAT is used directly for authentication

### Production Recommendations
- Use External Secrets Operator or similar
- Integrate with HashiCorp Vault, AWS Secrets Manager, etc.
- Implement proper secret rotation
- Use Sealed Secrets for GitOps-native secret management

### Secret Management Options

1. **External Secrets Operator**:
```bash
kubectl apply -f https://raw.githubusercontent.com/external-secrets/external-secrets/main/deploy/crds/bundle.yaml
```

2. **Sealed Secrets**:
```bash
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.18.0/controller.yaml
```

3. **ArgoCD Vault Plugin**:
```bash
# Use ArgoCD with Vault plugin for secret injection
```

## 📊 Current Status

After applying all declarative fixes:

- ✅ **Root Application**: `Synced` and `Healthy`
- ✅ **Production Application**: `Synced` and `Healthy`  
- ✅ **Staging Application**: `Synced` and `Healthy`
- ✅ **All Pods**: Running successfully in both environments
- ✅ **Repository**: Properly connected to ArgoCD
- ✅ **Image Pulls**: Working with GHCR authentication

## 🔄 Maintenance

To apply any future changes declaratively:

1. Update the relevant YAML files in the repository
2. Commit and push changes
3. ArgoCD will automatically sync (or manually refresh if needed)
4. No more ad-hoc `kubectl patch` commands required

## 📚 References

- [ArgoCD Projects Documentation](https://argo-cd.readthedocs.io/en/stable/user-guide/projects/)
- [Kubernetes Secrets Documentation](https://kubernetes.io/docs/concepts/configuration/secret/)
- [External Secrets Operator](https://external-secrets.io/)
- [Sealed Secrets](https://sealed-secrets.netlify.app/)
