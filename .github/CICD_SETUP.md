# GitHub Actions CI/CD Setup Guide

This guide explains how to set up and use the GitHub Actions CI/CD pipelines for the DevOps project.

## Overview

The CI/CD setup includes three main workflows:

1. **Backend CI/CD** (`backend-cicd.yml`) - Build, test, and deploy the Go backend API
2. **Frontend CI/CD** (`frontend-cicd.yml`) - Build, test, and deploy the React frontend
3. **Deploy Full Stack** (`deploy-stack.yml`) - Deploy both services together with manual control

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     GitHub Actions                           │
├─────────────────────────────────────────────────────────────┤
│  Push to main/master/develop                                 │
│         │                                                     │
│         ├──► Backend CI/CD                                   │
│         │    ├── Test (Go tests)                            │
│         │    ├── Lint (golangci-lint)                       │
│         │    ├── Build & Push (Docker + GHCR)               │
│         │    ├── Security Scan (Trivy)                      │
│         │    └── Deploy (Kubernetes)                        │
│         │                                                     │
│         └──► Frontend CI/CD                                  │
│              ├── Test (Jest/React tests)                    │
│              ├── Lint (ESLint)                              │
│              ├── Build (React build)                        │
│              ├── Build & Push (Docker + GHCR)               │
│              ├── Security Scan (Trivy)                      │
│              └── Deploy (Kubernetes)                        │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│              Kubernetes Cluster                              │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐              ┌──────────────┐            │
│  │   Backend    │              │   Frontend   │            │
│  │  Namespace   │              │  Namespace   │            │
│  ├──────────────┤              ├──────────────┤            │
│  │ Deployment   │              │ Deployment   │            │
│  │ Service      │◄─────────────┤ ConfigMap    │            │
│  │ ClusterIP    │              │ Service      │            │
│  └──────────────┘              │ NodePort     │            │
│                                 └──────────────┘            │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

### 1. GitHub Repository Secrets

You need to configure the following secrets in your GitHub repository (`Settings > Secrets and variables > Actions`):

#### Required Secrets:

- **`KUBECONFIG`**: Base64-encoded Kubernetes configuration file
  ```bash
  # Get your kubeconfig and encode it
  cat ~/.kube/config | base64 | pbcopy  # macOS
  cat ~/.kube/config | base64 -w 0      # Linux
  ```

#### Optional Secrets:

- **`REACT_APP_API_URL`**: Backend API URL for the frontend (defaults to in-cluster service)
- **`DOCKER_USERNAME`**: Docker Hub username (if using Docker Hub instead of GHCR)
- **`DOCKER_PASSWORD`**: Docker Hub password (if using Docker Hub instead of GHCR)

### 2. GitHub Packages/Container Registry

The workflows use GitHub Container Registry (ghcr.io) by default. No additional setup is needed as it uses the `GITHUB_TOKEN` automatically provided by GitHub Actions.

#### Enable GitHub Container Registry:

1. Go to your repository settings
2. Navigate to `Actions > General`
3. Under "Workflow permissions", ensure "Read and write permissions" is selected
4. Check "Allow GitHub Actions to create and approve pull requests"

### 3. Kubernetes Cluster

Ensure your Kubernetes cluster is running and accessible. The workflows expect:

- Cluster is accessible via the kubeconfig provided in secrets
- Namespaces: `backend` and `frontend` (created automatically by workflows)
- Sufficient resources for deployments (see resource limits in deployment files)

## Workflow Details

### Backend CI/CD Pipeline

**Trigger**: Push or PR to `main`, `master`, or `develop` branches with changes in:
- `backend/**`
- `k8s/personal/backend-deployment.yaml`
- `.github/workflows/backend-cicd.yml`

**Jobs**:

1. **Test** - Runs Go tests with coverage
   - Uses Go 1.21
   - Runs tests with race detection
   - Uploads coverage to Codecov

2. **Lint** - Runs golangci-lint
   - Checks code quality
   - Enforces Go best practices

3. **Build and Push** - Creates Docker image
   - Multi-platform build (amd64, arm64)
   - Pushes to GitHub Container Registry
   - Tags: branch name, SHA, latest (for main/master)
   - Runs Trivy security scan
   - Uploads security results to GitHub Security tab

4. **Deploy** - Deploys to Kubernetes (main/master only)
   - Updates deployment with new image
   - Waits for rollout completion
   - Runs smoke tests
   - Automatic rollback on failure

### Frontend CI/CD Pipeline

**Trigger**: Push or PR to `main`, `master`, or `develop` branches with changes in:
- `frontend/**`
- `k8s/personal/frontend-deployment.yaml`
- `.github/workflows/frontend-cicd.yml`

**Jobs**:

1. **Test** - Runs React tests with coverage
   - Uses Node.js 18
   - Runs Jest tests
   - Uploads coverage to Codecov

2. **Lint** - Runs ESLint
   - Checks code quality
   - Enforces React best practices

3. **Build** - Builds React application
   - Creates optimized production build
   - Uploads artifacts for inspection

4. **Build and Push** - Creates Docker image
   - Multi-platform build (amd64, arm64)
   - Pushes to GitHub Container Registry
   - Tags: branch name, SHA, latest (for main/master)
   - Runs Trivy security scan
   - Uploads security results to GitHub Security tab

5. **Deploy** - Deploys to Kubernetes (main/master only)
   - Updates deployment with new image
   - Waits for rollout completion
   - Runs smoke tests
   - Automatic rollback on failure

### Full Stack Deployment

**Trigger**: Manual workflow dispatch

**Parameters**:
- `environment`: Choose production, staging, or development
- `backend_image_tag`: Specific backend image tag (optional, defaults to latest)
- `frontend_image_tag`: Specific frontend image tag (optional, defaults to latest)

**Jobs**:

1. **Deploy Infrastructure** - Sets up base infrastructure
   - Creates namespaces
   - Deploys ingress

2. **Deploy Backend** - Deploys backend service
   - Uses specified or latest image tag
   - Waits for successful rollout

3. **Deploy Frontend** - Deploys frontend service
   - Uses specified or latest image tag
   - Waits for successful rollout

4. **Verify Deployment** - Runs comprehensive checks
   - Checks all pod statuses
   - Runs health checks
   - Displays deployment summary

## Usage

### Automatic Deployment

Simply push changes to the `main` or `master` branch:

```bash
# Make changes to backend or frontend
git add .
git commit -m "Update feature"
git push origin main
```

The appropriate CI/CD pipeline will automatically:
1. Run tests and linting
2. Build Docker image
3. Push to container registry
4. Deploy to Kubernetes
5. Verify deployment health

### Manual Deployment

Use the "Deploy Full Stack" workflow for manual deployments:

1. Go to `Actions` tab in GitHub
2. Select "Deploy Full Stack" workflow
3. Click "Run workflow"
4. Choose environment and image tags (optional)
5. Click "Run workflow" button

### Rollback

If a deployment fails, the workflow will automatically rollback to the previous version. To manually rollback:

```bash
# Rollback backend
kubectl rollout undo deployment/backend-api -n backend

# Rollback frontend
kubectl rollout undo deployment/frontend-app -n frontend

# Check rollback status
kubectl rollout status deployment/backend-api -n backend
kubectl rollout status deployment/frontend-app -n frontend
```

### Viewing Logs

Check deployment logs in real-time:

```bash
# Backend logs
kubectl logs -f deployment/backend-api -n backend

# Frontend logs
kubectl logs -f deployment/frontend-app -n frontend

# All pods in backend namespace
kubectl logs -l app=backend-api -n backend --all-containers=true
```

## Image Registry

### Using GitHub Container Registry (GHCR) - Default

Images are automatically pushed to `ghcr.io/<github-username>/<repo-name>/backend` and `frontend`.

**View images**:
1. Go to your repository page
2. Click "Packages" in the right sidebar
3. Select the package to view versions

**Pull images manually**:
```bash
# Login to GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# Pull images
docker pull ghcr.io/username/devops/backend:latest
docker pull ghcr.io/username/devops/frontend:latest
```

### Using Docker Hub (Alternative)

To use Docker Hub instead of GHCR:

1. Add Docker Hub secrets to GitHub:
   - `DOCKER_USERNAME`
   - `DOCKER_PASSWORD`

2. Update workflows to use Docker Hub:
   ```yaml
   env:
     REGISTRY: docker.io
     IMAGE_NAME: username/backend  # or frontend
   ```

3. Update login action:
   ```yaml
   - name: Log in to Docker Hub
     uses: docker/login-action@v3
     with:
       username: ${{ secrets.DOCKER_USERNAME }}
       password: ${{ secrets.DOCKER_PASSWORD }}
   ```

## Environments

GitHub Environments provide deployment protection and secrets management.

### Setting up Environments:

1. Go to `Settings > Environments`
2. Create environments: `production`, `staging`, `development`
3. Configure protection rules:
   - **Production**: Require approvals, restrict to main branch
   - **Staging**: Require approvals (optional)
   - **Development**: No restrictions

4. Add environment-specific secrets if needed

### Environment URLs:

Update the environment URLs in workflows:

```yaml
environment:
  name: production
  url: https://your-actual-domain.com  # Update this
```

## Monitoring and Alerts

### GitHub Actions Notifications

Configure notifications in `Settings > Notifications`:
- Enable "GitHub Actions" notifications
- Choose email or web notifications for workflow failures

### Kubernetes Monitoring

Monitor deployments:

```bash
# Watch deployments
kubectl get deployments --all-namespaces -w

# Check pod health
kubectl get pods --all-namespaces

# View events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'
```

### Set up Slack Notifications (Optional)

Add to workflows:

```yaml
- name: Notify Slack
  if: always()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK_URL }}
```

## Troubleshooting

### Common Issues

1. **"KUBECONFIG secret not found"**
   - Ensure KUBECONFIG secret is properly base64-encoded
   - Verify secret is available in repository settings

2. **"Permission denied to push to GitHub Container Registry"**
   - Check workflow permissions in repository settings
   - Ensure "Read and write permissions" is enabled

3. **"Deployment timeout"**
   - Check pod logs: `kubectl logs -n backend deployment/backend-api`
   - Verify resource limits match cluster capacity
   - Check image pull status: `kubectl describe pod -n backend <pod-name>`

4. **"Tests failing in CI but passing locally"**
   - Ensure all dependencies are in package.json/go.mod
   - Check environment variables
   - Verify Node.js/Go versions match

5. **"Image not found during deployment"**
   - Verify image was successfully pushed
   - Check image name and tag in deployment files
   - Ensure imagePullPolicy is correct

### Debug Mode

Enable debug logging in workflows:

```yaml
env:
  ACTIONS_STEP_DEBUG: true
  ACTIONS_RUNNER_DEBUG: true
```

## Security Best Practices

1. **Secrets Management**
   - Never commit secrets to repository
   - Use GitHub Secrets for sensitive data
   - Rotate secrets regularly

2. **Image Scanning**
   - Workflows include Trivy security scanning
   - Review security alerts in GitHub Security tab
   - Update base images regularly

3. **Access Control**
   - Use namespaces for isolation
   - Implement RBAC in Kubernetes
   - Restrict workflow permissions

4. **Network Security**
   - Use ClusterIP for internal services
   - Implement network policies
   - Enable TLS/HTTPS for ingress

## Performance Optimization

### Docker Build Cache

Workflows use GitHub Actions cache for faster builds:
```yaml
cache-from: type=gha
cache-to: type=gha,mode=max
```

### Dependency Caching

Node.js and Go dependencies are cached:
```yaml
- uses: actions/setup-node@v4
  with:
    cache: 'npm'
```

### Parallel Jobs

Independent jobs run in parallel to reduce total workflow time.

## Cost Optimization

1. **Use path filters** - Only run workflows when relevant files change
2. **Limit retention** - Set appropriate artifact retention days
3. **Use self-hosted runners** - For private repositories with high usage
4. **Optimize Docker layers** - Reduce image size and build time

## Advanced Configuration

### Blue-Green Deployment

Implement blue-green deployments:

```yaml
- name: Deploy new version (green)
  run: |
    kubectl apply -f k8s/green-deployment.yaml
    kubectl wait --for=condition=ready pod -l version=green
    
- name: Switch traffic
  run: |
    kubectl patch service my-service -p '{"spec":{"selector":{"version":"green"}}}'
```

### Canary Deployment

Use Argo Rollouts or Flagger for canary deployments:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
spec:
  strategy:
    canary:
      steps:
      - setWeight: 20
      - pause: {duration: 1m}
      - setWeight: 50
      - pause: {duration: 1m}
```

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)

## Support

For issues or questions:
1. Check workflow logs in GitHub Actions tab
2. Review Kubernetes pod logs
3. Consult this documentation
4. Open an issue in the repository

---

**Last Updated**: October 2025  
**Maintained By**: DevOps Team

