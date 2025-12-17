# 🔧 Jenkins CI/CD Setup Guide

## Quick Start

The PERN GitOps repository now includes a complete Jenkins CI/CD pipeline for automated builds and deployments.

### Option 1: Local Jenkins (Development/Testing)

```bash
cd jenkins
./setup.sh
```

The script will:
1. Prompt for GitHub credentials
2. Create necessary configuration files
3. Start Jenkins in Docker
4. Configure the pipeline automatically

Access Jenkins at: **http://localhost:8080**

### Option 2: Production Jenkins Server

For production environments, follow the detailed setup guide in [`jenkins/README.md`](jenkins/README.md).

## What the Jenkins Pipeline Does

The automated pipeline handles the complete CI/CD workflow:

1. ✅ **Build** Docker images for backend and frontend
2. ✅ **Test** applications with automated tests
3. ✅ **Scan** images for security vulnerabilities
4. ✅ **Push** images to GitHub Container Registry (GHCR)
5. ✅ **Update** Kubernetes manifests with new image tags
6. ✅ **Trigger** ArgoCD to deploy the changes

## Pipeline Parameters

When running the pipeline, you can configure:

- **ENVIRONMENT**: Choose `staging` or `production`
- **BUILD_BACKEND**: Build backend image (default: true)
- **BUILD_FRONTEND**: Build frontend image (default: true)
- **SKIP_TESTS**: Skip test execution (default: false)

## File Structure

```
pern-gitops/
├── Jenkinsfile                          # Main pipeline definition
├── jenkins/
│   ├── README.md                        # Detailed setup guide
│   ├── setup.sh                         # Quick setup script
│   ├── docker-compose.yml              # Local Jenkins environment
│   ├── jenkins.yaml                     # Jenkins Configuration as Code
│   └── examples/                        # Example Dockerfiles and configs
│       ├── backend/
│       │   ├── Dockerfile
│       │   └── package.json
│       └── frontend/
│           ├── Dockerfile
│           └── package.json
```

## Required Credentials

The Jenkins pipeline requires these credentials to be configured:

1. **GitHub Personal Access Token** with scopes:
   - `repo` - For Git operations
   - `write:packages` - For pushing to GHCR

2. **Jenkins Credentials** (automatically configured by setup.sh):
   - `ghcr-credentials` - GitHub Container Registry access
   - `github-credentials` - GitHub repository access
   - `argocd-credentials` - ArgoCD CLI access (optional)

## Integration with GitOps

The Jenkins pipeline integrates seamlessly with the existing GitOps workflow:

```
Developer Push → GitHub → Jenkins → Build & Test → Push to GHCR
    ↓
Update Manifests → Git Commit → ArgoCD Detects → Deploy to K8s
```

## Next Steps

1. **Set up Jenkins** using the quick start or production guide
2. **Add source code** to `backend/` and `frontend/` directories, or
3. **Modify Jenkinsfile** to pull from separate repositories
4. **Configure webhooks** for automatic builds on push
5. **Run your first build** and watch the magic happen!

## Documentation

- 📖 [Detailed Jenkins Setup Guide](jenkins/README.md)
- 📖 [Jenkinsfile Reference](Jenkinsfile)
- 📖 [Example Dockerfiles](jenkins/examples/)

## Support

For issues or questions:
- Review the [Jenkins README](jenkins/README.md)
- Check Jenkins job console output
- Open an issue on GitHub

---

**Ready to automate your deployments? Get started with Jenkins today!** 🚀
