# 🚀 PERN GitOps - Declarative Setup Guide

This repository now supports **fully declarative setup** instead of ad-hoc kubectl commands!

## 🎯 Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/mankinimbom/pern-gitops.git
cd pern-gitops

# 2. Set your GitHub Personal Access Token
export GITHUB_PAT=your_github_personal_access_token

# 3. Run the declarative setup
./bootstrap/declarative-setup.sh
```

That's it! The script will handle everything that was previously done with manual `kubectl` commands.

## 📋 What the Setup Script Does

The `bootstrap/declarative-setup.sh` script automatically:

1. ✅ **Applies ArgoCD Project** with all necessary permissions
2. ✅ **Creates Image Pull Secrets** for GHCR authentication  
3. ✅ **Creates Repository Secret** for ArgoCD Git access
4. ✅ **Restarts ArgoCD Components** to pick up changes
5. ✅ **Applies Root Application** to bootstrap the app-of-apps pattern
6. ✅ **Refreshes All Applications** to ensure sync
7. ✅ **Verifies Final Status** of all components

## 🔧 Previous Manual Process vs. New Declarative Process

### ❌ Before (Manual Commands)
```bash
# Multiple ad-hoc kubectl patch commands
kubectl -n argocd patch appproject pern-app --type='merge' -p='...'
kubectl -n pern-app-production create secret docker-registry ghcr-creds ...
kubectl -n pern-app-staging create secret docker-registry ghcr-creds ...
kubectl -n argocd create secret generic pern-gitops-repo ...
kubectl -n argocd label secret pern-gitops-repo ...
kubectl -n argocd rollout restart deployment/argocd-repo-server
kubectl -n argocd annotate application pern-app-root ...
# ... many more manual steps
```

### ✅ After (Declarative)
```bash
export GITHUB_PAT=your_token
./bootstrap/declarative-setup.sh
```

## 📁 New Declarative Structure

```
bootstrap/
├── declarative-setup.sh           # Main setup script
├── root-app.yaml                  # Root application definition
└── secrets/                       # Secret management (gitignored)
    ├── README.md                   # Secret documentation
    ├── generate-secrets.sh         # Secret generation script
    ├── ghcr-image-pull-secrets.yaml    # GHCR auth template
    └── argocd-repo-secret.yaml     # Repository auth template

docs/
└── declarative-fixes.md           # Complete documentation of all fixes

projects/
└── appproject.yaml                # Fixed ArgoCD project permissions
```

## 🔐 Security Features

- **Secret Templates**: Actual secrets are not committed to Git
- **Environment Variables**: Credentials provided via environment variables
- **Automatic Cleanup**: Temporary secret files are cleaned up after use
- **GitIgnore Protection**: .gitignore prevents accidental secret commits

## 🎛️ Advanced Usage

### Generate Secrets Only
```bash
export GITHUB_PAT=your_token
cd bootstrap/secrets
./generate-secrets.sh
kubectl apply -f /tmp/ghcr-image-pull-secrets.yaml
kubectl apply -f /tmp/argocd-repo-secret.yaml
```

### Apply Without Secrets (Manual Secret Management)
```bash
# Script will skip secret generation if GITHUB_PAT is not set
./bootstrap/declarative-setup.sh
```

### Production Secret Management
For production environments, integrate with:
- External Secrets Operator
- HashiCorp Vault
- AWS Secrets Manager
- Sealed Secrets

## 📊 Expected Results

After running the declarative setup:

```bash
kubectl -n argocd get applications
# NAME                  SYNC STATUS   HEALTH STATUS
# pern-app-production   Synced        Healthy
# pern-app-root         Synced        Healthy
# pern-app-staging      Synced        Healthy

kubectl get pods -n pern-app-production
# All pods running: backend (3/3), frontend (3/3), postgresql (1/1), redis (1/1)

kubectl get pods -n pern-app-staging  
# All pods running: backend (3/3), frontend (3/3), postgresql (1/1), redis (1/1)
```

## 🔄 Maintenance

Future changes can be made declaratively by:
1. Updating YAML files in the repository
2. Committing and pushing changes
3. ArgoCD automatically syncs the changes
4. No more manual `kubectl patch` commands needed!

## 📚 Documentation

- **Complete Fix Documentation**: [docs/declarative-fixes.md](docs/declarative-fixes.md)
- **Secret Management Guide**: [bootstrap/secrets/README.md](bootstrap/secrets/README.md)
- **Production GitOps Guide**: [docs/production-gitops-implementation.md](docs/production-gitops-implementation.md)

---

🎉 **Your PERN stack is now fully GitOps-enabled with declarative configuration management!**
