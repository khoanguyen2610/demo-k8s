# GitHub Actions Workflows

This directory contains GitHub Actions workflows for building, testing, and deploying the application using Kustomize.

## Workflows

### 1. build-deploy.yml (Main CI/CD)

**Trigger:** Push to main/master/develop branches, Pull requests

**Jobs:**
- `build-backend` - Build and push backend API Docker image
- `build-consumer` - Build and push consumer workers Docker image
- `build-frontend` - Build and push frontend Docker image
- `deploy-k8s` - Deploy to Kubernetes using Kustomize (main/master only)
- `rollback-on-failure` - Automatic rollback if deployment fails

**Features:**
- ✅ Parallel builds for faster CI/CD
- ✅ Docker layer caching (GitHub Actions cache)
- ✅ Automatic tagging (branch, SHA, latest)
- ✅ Kustomize-based deployment
- ✅ Automatic rollback on failure
- ✅ Environment protection for production

### 2. helm-preview.yml (PR Validation)

**Trigger:** Pull requests that modify K8s configs

**Paths Watched:**
- `k8s/backend/**`
- `k8s/frontend/**`

**Jobs:**
- `validate-kustomize` - Build kustomizations, validate manifests, comment on PR

**Features:**
- ✅ Kustomize build validation
- ✅ Manifest generation preview
- ✅ Kubernetes resource validation (dry-run)
- ✅ Automated PR comments with results

## Required Secrets

Add these secrets in your GitHub repository settings:

### Docker Hub
| Secret | Description |
|--------|-------------|
| `DOCKER_USERNAME` | Your Docker Hub username |
| `DOCKER_PASSWORD` | Your Docker Hub password or access token |

### Kubernetes
| Secret | Description |
|--------|-------------|
| `KUBECONFIG` | Base64 encoded kubeconfig file for your cluster |

## Setup Instructions

### 1. Get Kubeconfig

```bash
# For your Kubernetes cluster
kubectl config view --flatten --minify > kubeconfig.yaml

# Encode kubeconfig for GitHub secret
cat kubeconfig.yaml | base64 -w 0  # Linux
cat kubeconfig.yaml | base64        # macOS
```

### 2. Add Secrets to GitHub

```bash
# Using GitHub CLI
gh secret set DOCKER_USERNAME
gh secret set DOCKER_PASSWORD
gh secret set KUBECONFIG

# Or via GitHub UI:
# Repository → Settings → Secrets and variables → Actions → New repository secret
```

### 3. Configure Environment Protection (Optional)

For production environment:
1. Go to Settings → Environments → New environment
2. Name it "production"
3. Add protection rules:
   - Required reviewers
   - Wait timer
   - Deployment branches (main/master only)

## Workflow Details

### Build & Deploy Workflow

```yaml
Trigger: Push to main/master/develop, PRs

Flow:
  1. Build Images (Parallel)
     ├─ Backend API
     ├─ Consumer Workers
     └─ Frontend App
  
  2. Deploy to Kubernetes (main/master only)
     ├─ Apply backend kustomization
     ├─ Apply frontend kustomization
     ├─ Update image tags
     └─ Wait for rollout
  
  3. Rollback (if deploy fails)
     └─ Undo all deployments
```

**Image Tags:**
- Branch + SHA: `main-abc123` (for tracking)
- Latest: `latest` (for quick reference)
- Consumer: `main-abc123-consumer` (separate tag)

### PR Preview Workflow

```yaml
Trigger: PR modifying k8s/backend/** or k8s/frontend/**

Flow:
  1. Build kustomizations
  2. Validate manifests (dry-run)
  3. Comment on PR with:
     - Validation results
     - Manifest previews
     - Deploy commands
```

## Deployment Process

When you push to `main` or `master`:

1. **Build Phase** (~3-5 minutes)
   - Builds Docker images in parallel
   - Pushes to Docker Hub
   - Uses layer caching for speed

2. **Deploy Phase** (~2-3 minutes)
   - Connects to Kubernetes cluster
   - Applies Kustomize configurations
   - Updates image tags dynamically
   - Waits for rollout completion

3. **Verify Phase**
   - Checks deployment status
   - Lists pods and services
   - Shows ingress configuration

## Manual Deployment

If you need to deploy manually:

```bash
# Deploy backend
kubectl apply -k k8s/backend/
kubectl set image deployment/backend-api backend-api=khoanguyen2610/backend:latest -n backend

# Deploy frontend
kubectl apply -k k8s/frontend/
kubectl set image deployment/frontend-app frontend-app=khoanguyen2610/frontend:latest -n frontend
```

## Troubleshooting

### Deployment Fails

The workflow automatically rolls back failed deployments. Check:
```bash
kubectl get pods -n backend
kubectl get pods -n frontend
kubectl describe pod <pod-name> -n <namespace>
```

### KUBECONFIG Secret Issues

Verify your kubeconfig is properly base64 encoded:
```bash
# Decode to verify
echo "$KUBECONFIG_SECRET" | base64 -d

# Should show valid kubeconfig YAML
```

### Image Pull Errors

Ensure Docker Hub credentials are correct:
```bash
# Test locally
docker login
docker pull khoanguyen2610/backend:latest
```

## Monitoring Deployments

### View Workflow Runs

1. Go to Actions tab in GitHub
2. Select the workflow
3. View logs for each step

### Check Kubernetes Status

```bash
# Backend
kubectl get deployments -n backend
kubectl get pods -n backend -w
kubectl logs -n backend -l app=backend-api

# Frontend
kubectl get deployments -n frontend
kubectl get pods -n frontend -w
kubectl get ingress -n frontend
```

## Rollback

### Automatic Rollback
The workflow automatically rolls back failed deployments.

### Manual Rollback
```bash
# Backend
kubectl rollout undo deployment/backend-api -n backend
kubectl rollout undo deployment/email-processor-consumer -n backend

# Frontend
kubectl rollout undo deployment/frontend-app -n frontend
```

## Security Best Practices

1. **Secrets Management**
   - Never commit kubeconfig files
   - Rotate secrets regularly
   - Use minimal permissions

2. **Docker Hub**
   - Use access tokens instead of passwords
   - Limit token scope to push/pull only

3. **Kubernetes**
   - Use RBAC with minimal permissions
   - Enable audit logging
   - Regular security updates

## Performance Tips

1. **Docker Layer Caching**
   - Already enabled via GitHub Actions cache
   - Significantly speeds up builds

2. **Parallel Builds**
   - Three builds run simultaneously
   - Reduces total build time

3. **Efficient Kustomize**
   - Small, focused kustomizations
   - Fast build and apply times

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Kustomize Documentation](https://kustomize.io/)
- [kubectl Reference](https://kubernetes.io/docs/reference/kubectl/)
- [Docker Hub Documentation](https://docs.docker.com/docker-hub/)
