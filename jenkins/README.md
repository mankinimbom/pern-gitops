# Jenkins CI/CD Setup for PERN GitOps

This directory contains Jenkins configuration and setup instructions for the PERN GitOps pipeline.

## 📋 Prerequisites

Before setting up Jenkins, ensure you have:

1. **Jenkins Server** (2.400+ recommended)
2. **Required Plugins**:
   - Docker Pipeline Plugin
   - GitHub Plugin
   - Credentials Binding Plugin
   - Pipeline Plugin
   - Kubernetes CLI Plugin (optional)
3. **Docker** installed on Jenkins agents
4. **Git** configured
5. **GitHub Personal Access Token** with `write:packages` scope for GHCR

## 🔧 Jenkins Setup Steps

### 1. Install Required Plugins

Navigate to **Manage Jenkins** → **Manage Plugins** → **Available** and install:

```
- Docker Pipeline
- GitHub
- Credentials Binding
- Pipeline
- Kubernetes CLI (optional, for ArgoCD sync)
```

### 2. Configure Credentials

Add the following credentials in **Manage Jenkins** → **Manage Credentials**:

#### GHCR Credentials (ID: `ghcr-credentials`)
- **Type**: Username with password
- **Username**: Your GitHub username
- **Password**: GitHub Personal Access Token with `write:packages` scope
- **ID**: `ghcr-credentials`
- **Description**: GitHub Container Registry credentials

#### GitHub Credentials (ID: `github-credentials`)
- **Type**: Username with password
- **Username**: Your GitHub username
- **Password**: GitHub Personal Access Token with `repo` scope
- **ID**: `github-credentials`
- **Description**: GitHub repository credentials

#### ArgoCD Credentials (ID: `argocd-credentials`, optional)
- **Type**: Secret text
- **Secret**: ArgoCD authentication token
- **ID**: `argocd-credentials`
- **Description**: ArgoCD CLI authentication

### 3. Create Jenkins Pipeline Job

1. Go to **New Item**
2. Enter name: `pern-gitops-pipeline`
3. Select **Pipeline**
4. Click **OK**

### 4. Configure Pipeline Job

#### General Settings
- ✅ **GitHub project**: `https://github.com/mankinimbom/pern-gitops`
- ✅ **This project is parameterized** (configured in Jenkinsfile)

#### Build Triggers
Choose one or more:
- ✅ **GitHub hook trigger for GITScm polling** (recommended)
- ✅ **Poll SCM**: `H/5 * * * *` (every 5 minutes, fallback)

#### Pipeline Configuration
- **Definition**: Pipeline script from SCM
- **SCM**: Git
  - **Repository URL**: `https://github.com/mankinimbom/pern-gitops.git`
  - **Credentials**: Select `github-credentials`
  - **Branch**: `*/main` (or your default branch)
- **Script Path**: `Jenkinsfile`

### 5. Configure GitHub Webhook (Optional but Recommended)

1. Go to your GitHub repository → **Settings** → **Webhooks**
2. Click **Add webhook**
3. Configure:
   - **Payload URL**: `http://your-jenkins-server/github-webhook/`
   - **Content type**: `application/json`
   - **Events**: Select "Just the push event"
   - **Active**: ✅
4. Click **Add webhook**

## 🚀 Running the Pipeline

### Manual Trigger

1. Go to the Jenkins job
2. Click **Build with Parameters**
3. Configure parameters:
   - **ENVIRONMENT**: `staging` or `production`
   - **SKIP_TESTS**: Checkbox to skip tests
   - **BUILD_BACKEND**: Build backend image
   - **BUILD_FRONTEND**: Build frontend image
4. Click **Build**

### Automatic Trigger

Once webhook is configured, pipeline will automatically run on:
- Push to main branch
- Pull request merge

## 📊 Pipeline Stages

The Jenkins pipeline includes the following stages:

1. **Checkout**: Clone repository and display build info
2. **Validate**: Run Kubernetes manifest validation
3. **Build Backend**: Build backend Docker image
4. **Build Frontend**: Build frontend Docker image
5. **Test**: Run unit tests for both services (parallel)
6. **Security Scan**: Scan images with Trivy (if available)
7. **Push to Registry**: Push images to GHCR
8. **Update Manifests**: Update Kubernetes manifests with new image tags
9. **Commit and Push**: Commit manifest changes back to Git
10. **Trigger ArgoCD Sync**: Trigger ArgoCD application sync (optional)

## 🔐 Security Best Practices

### Credentials & Secrets
- ✅ Never commit credentials to Git
- ✅ Use Jenkins Credentials Store for all secrets
- ✅ Use separate credentials for different environments
- ✅ Rotate GitHub tokens regularly
- ✅ Use minimal required permissions for tokens

### Docker Socket Security
⚠️ **Important**: The default setup mounts the Docker socket for building images. This has security implications:

**Risks:**
- Containers can access the Docker daemon
- Effectively provides root-level access to the host
- Suitable for **development/testing only**

**Production Alternatives:**
1. **Docker-in-Docker (DinD)**: Use the commented-out `docker-dind` service in `docker-compose.yml`
2. **Kaniko**: Build images without Docker daemon access
3. **Dedicated Build Agents**: Run on isolated VMs/nodes
4. **Kubernetes-based Jenkins**: Use proper RBAC and pod security policies

**To Enable Docker-in-Docker:**
```yaml
# In docker-compose.yml:
# 1. Comment out the docker.sock mount
# 2. Uncomment the docker-dind service
# 3. Set DOCKER_HOST=tcp://docker-dind:2376 in Jenkins
```

### Image Scanning
- ✅ Enable security scanning with Trivy
- ✅ Use minimal required permissions for tokens

## 📁 Expected Repository Structure

For the pipeline to work with application source code, your repository should have:

```
pern-gitops/
├── Jenkinsfile                 # Main pipeline definition
├── jenkins/                    # Jenkins configuration
│   ├── README.md              # This file
│   └── docker-compose.yml     # Local Jenkins setup (optional)
├── backend/                   # Backend source code (if in same repo)
│   ├── Dockerfile
│   ├── package.json
│   └── src/
├── frontend/                  # Frontend source code (if in same repo)
│   ├── Dockerfile
│   ├── package.json
│   └── src/
└── apps/                      # Kubernetes manifests
    └── pern-app/
```

**Note**: If backend/frontend are in separate repositories, you can:
1. Use Jenkins Multi-branch Pipeline
2. Trigger this pipeline from separate build jobs
3. Modify the Jenkinsfile to skip build stages

## 🐳 Local Jenkins Testing

For local testing, use the provided Docker Compose setup:

```bash
cd jenkins
docker-compose up -d
```

Access Jenkins at: `http://localhost:8080`

Default credentials are in `docker-compose.yml` (change for production!)

## 🔄 Pipeline Flow Diagram

```
┌─────────────┐
│  Git Push   │
└──────┬──────┘
       │
       ▼
┌─────────────────┐
│ GitHub Webhook  │
└──────┬──────────┘
       │
       ▼
┌──────────────────────┐
│  Jenkins Triggered   │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│  Build Docker Images │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│   Run Tests          │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│  Security Scan       │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│  Push to GHCR        │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ Update K8s Manifests │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│  Commit to Git       │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│  ArgoCD Auto-Sync    │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│   Deployed! 🚀       │
└──────────────────────┘
```

## 🛠️ Troubleshooting

### Issue: Docker permission denied
**Solution**: Add Jenkins user to docker group:
```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### Issue: GHCR push fails with authentication error
**Solution**: 
1. Verify GitHub token has `write:packages` scope
2. Check credentials ID matches `ghcr-credentials`
3. Test login manually: `echo $TOKEN | docker login ghcr.io -u USERNAME --password-stdin`

### Issue: Git push fails
**Solution**:
1. Verify GitHub token has `repo` scope
2. Check credentials ID matches `github-credentials`
3. Ensure Jenkins user has Git configured

### Issue: ArgoCD sync fails
**Solution**:
1. Install ArgoCD CLI on Jenkins agent
2. Configure ArgoCD server URL in pipeline
3. Add ArgoCD credentials to Jenkins

## 📚 Additional Resources

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Docker Pipeline Plugin](https://plugins.jenkins.io/docker-workflow/)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)

## 🤝 Support

For issues or questions:
1. Check Jenkins job console output
2. Review this README
3. Check GitHub repository issues
4. Contact repository maintainer

---

**Last Updated**: December 2025
