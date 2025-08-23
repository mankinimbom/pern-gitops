# Repository Authentication Management

## Overview
Repository authentication for ArgoCD is managed **imperatively** (outside of GitOps) to prevent template variable conflicts and authentication loops.

## Why Imperative Management?

### The Problem with Declarative Repository Secrets
1. **Template Variable Conflicts**: GitOps templates with `${GITHUB_PAT}` get applied literally
2. **Chicken and Egg**: ArgoCD needs repo access to manage repo access secrets
3. **Security**: Prevents hardcoded tokens in Git history

### The Solution: Imperative Authentication
- Repository secret created directly via `kubectl`
- Actual GitHub token stored securely in cluster
- Excluded from GitOps via `kustomization.yaml`

## Implementation

### 1. Create Repository Secret
```bash
kubectl -n argocd create secret generic pern-gitops-repo \
  --from-literal=type=git \
  --from-literal=url=https://github.com/mankinimbom/pern-gitops \
  --from-literal=username=mankinimbom \
  --from-literal=password=YOUR_GITHUB_TOKEN_HERE

kubectl -n argocd label secret pern-gitops-repo argocd.argoproj.io/secret-type=repository
```

### 2. Verify Authentication
```bash
# Check secret contains actual token (not template variable)
kubectl -n argocd get secret pern-gitops-repo -o jsonpath='{.data.password}' | base64 -d

# Verify ArgoCD applications sync successfully  
kubectl -n argocd get applications
```

### 3. Exclude from GitOps
The `projects/kustomization.yaml` explicitly excludes repository secrets:
```yaml
resources:
  - appproject.yaml
  - applicationset.yaml
  # repository-secret.yaml intentionally excluded
```

## Maintenance

### Token Rotation
```bash
# Delete old secret
kubectl -n argocd delete secret pern-gitops-repo

# Create with new token
kubectl -n argocd create secret generic pern-gitops-repo \
  --from-literal=type=git \
  --from-literal=url=https://github.com/mankinimbom/pern-gitops \
  --from-literal=username=mankinimbom \
  --from-literal=password=NEW_GITHUB_TOKEN

kubectl -n argocd label secret pern-gitops-repo argocd.argoproj.io/secret-type=repository
```

### Troubleshooting

**Symptom**: Applications show "Unknown" sync status
**Cause**: Authentication failure
**Solution**: Recreate repository secret with actual token

**Symptom**: Applications show "OutOfSync" with template variables
**Cause**: ArgoCD applying repository secret from Git
**Solution**: Verify `kustomization.yaml` excludes repository secret

## Security Benefits
1. ✅ **No hardcoded tokens in Git**
2. ✅ **No template variable conflicts** 
3. ✅ **Proper secret lifecycle management**
4. ✅ **Clean separation of concerns**
