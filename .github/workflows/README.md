# GitHub Actions Workflows

This directory contains GitHub Actions workflows for building, testing, and deploying the application using Helm.

## Workflows

### 1. build-deploy.yml (Main CI/CD)

**Trigger:** Push to main/master/develop branches, Pull requests

**Jobs:**
- `build-backend` - Build and push backend API Docker image
- `build-consumer` - Build and push consumer workers Docker image
- `build-frontend` - Build and push frontend Docker image
- `test-backend` - Health check testing
- `deploy-helm` - Deploy to Kubernetes using Helm (main/master only)
- `rollback-on-failure` - Automatic rollback if deployment fails

**Features:**
- ✅ Parallel builds for faster CI/CD
- ✅ Docker layer caching (GitHub Actions cache)
- ✅ Automatic tagging (branch, SHA, latest)
- ✅ Health check testing before deployment
- ✅ Helm-based deployment
- ✅ Automatic rollback on failure
- ✅ Environment protection for production

### 2. helm-preview.yml (PR Validation)

**Trigger:** Pull requests that modify Helm charts or K8s configs

**Paths Watched:**
- `k8s/helm/devops-app/**`
- `k8s/helm/consumer-chart/**`
- `k8s/backend/**`
- `k8s/frontend/**`

**Jobs:**
- `lint-and-preview` - Lint charts, generate manifests, validate resources, comment on PR

**Features:**
- ✅ Helm chart linting
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
| `K8S_DOMAIN` | Your Kubernetes ingress domain (optional, for display) |

## Setup Instructions

### 1. Get Kubeconfig

```bash
# For AWS EKS
aws eks --region <region> update-kubeconfig --name <cluster-name>

# Encode kubeconfig for GitHub secret
cat ~/.kube/config | base64 -w 0  # Linux
cat ~/.kube/config | base64        # macOS
```

### 2. Add Secrets to GitHub

```bash
# Using GitHub CLI
gh secret set DOCKER_USERNAME
gh secret set DOCKER_PASSWORD
gh secret set KUBECONFIG
gh secret set K8S_DOMAIN

# Or via GitHub UI:
# Repository → Settings → Secrets and variables → Actions → New repository secret
```

### 3. Configure Environment Protection (Optional)

For production deployments:
1. Go to Repository → Settings → Environments
2. Create environment: `production`
3. Add protection rules:
   - Required reviewers
   - Wait timer
   - Deployment branches (main/master only)

## Workflow Behavior

### On Push to main/master
1. Build all Docker images in parallel
2. Test backend health endpoint
3. Deploy to production using Helm
4. Verify deployment
5. Auto-rollback if deployment fails

### On Push to develop
1. Build all Docker images
2. Test backend health endpoint
3. No deployment (build only)

### On Pull Request
1. Lint Helm charts
2. Generate manifest preview
3. Validate Kubernetes resources
4. Comment on PR with results

## Helm Deployment Command

The workflow uses this Helm command:

```bash
helm upgrade --install devops-app k8s/helm/devops-app/ \
  --namespace default \
  --create-namespace \
  --set backend.image.tag=main-abc123 \
  --set frontend.image.tag=main-abc123 \
  --set consumers.image.tag=main-abc123-consumer \
  --timeout 5m \
  --wait
```

## Image Tagging Strategy

| Branch | Backend Tag | Consumer Tag | Frontend Tag |
|--------|------------|--------------|--------------|
| main | `latest`, `main-SHA` | `consumer-latest`, `main-SHA-consumer` | `latest`, `main-SHA` |
| develop | `develop-SHA` | `develop-SHA-consumer` | `develop-SHA` |
| feature/* | `feature-*-SHA` | `feature-*-SHA-consumer` | `feature-*-SHA` |

## Monitoring Deployments

### View Workflow Runs

```bash
# Using GitHub CLI
gh run list
gh run watch

# View specific run
gh run view <run-id> --log
```

### Check Kubernetes Deployment

```bash
# Check Helm release
helm list -n default

# Check deployments
kubectl get deployments -n default
kubectl get pods -n default

# View logs
kubectl logs -n default -l app=backend-api -f
```

### Rollback if Needed

```bash
# Manual rollback
helm rollback devops-app -n default

# Or to specific revision
helm history devops-app -n default
helm rollback devops-app <revision> -n default
```

## Troubleshooting

### Build Failures

**Issue:** Docker build fails
```bash
# Check build logs in GitHub Actions
# Verify Dockerfile syntax locally:
docker build -t test ./backend
```

**Issue:** Image push fails
```bash
# Verify Docker Hub credentials are correct
# Check secret values in GitHub settings
```

### Deployment Failures

**Issue:** Helm deployment fails
```bash
# Check Helm chart validity
helm lint k8s/personal/devops-app/

# Preview what will be deployed
helm template devops-app k8s/personal/devops-app/
```

**Issue:** Pods not starting
```bash
# Check pod logs in workflow or manually
kubectl logs -n default -l app=backend-api
kubectl describe pod -n default <pod-name>
```

### Authentication Issues

**Issue:** Cannot connect to cluster
```bash
# Verify KUBECONFIG secret is correct
# Test kubeconfig locally:
kubectl cluster-info
```

**Issue:** Docker Hub rate limit
```bash
# Ensure DOCKER_USERNAME and DOCKER_PASSWORD are set
# Consider using GitHub Container Registry instead
```

## Customization

### Deploy to Different Namespace

Edit `build-deploy.yml`:
```yaml
helm upgrade --install devops-app k8s/personal/devops-app/ \
  --namespace production \  # Change namespace
  --create-namespace \
  ...
```

### Use Different Values File

Edit `build-deploy.yml`:
```yaml
helm upgrade --install devops-app k8s/personal/devops-app/ \
  --values k8s/personal/devops-app/values-prod.yaml \  # Add values file
  --set backend.image.tag=${{ github.sha }} \
  ...
```

### Add Notifications

Add to `build-deploy.yml`:
```yaml
- name: Notify Slack
  uses: slackapi/slack-github-action@v1
  with:
    payload: |
      {
        "text": "Deployment ${{ job.status }}"
      }
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

## Best Practices

1. ✅ **Use specific image tags** in production (not `latest`)
2. ✅ **Test locally** before pushing: `helm template` and `helm lint`
3. ✅ **Enable branch protection** on main/master
4. ✅ **Require PR reviews** before merging
5. ✅ **Monitor deployments** after pushing
6. ✅ **Use environment protection** for production
7. ✅ **Keep secrets secure** - never commit them

## Migration from Legacy

### Old (Manual kubectl)
```yaml
script:
  - kubectl apply -f k8s/personal/backend-deployment.yaml
  - kubectl apply -f k8s/personal/frontend-deployment.yaml
  - kubectl apply -f k8s/personal/consumer-*.yaml
```

### New (Helm)
```yaml
script:
  - helm upgrade --install devops-app k8s/personal/devops-app/
```

**Benefits:**
- One command instead of many
- Automatic rollback capability
- Version tracking
- Easier configuration management

## Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Helm Documentation](https://helm.sh/docs/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Build Push Action](https://github.com/docker/build-push-action)

---

**Workflows are ready to use!** Just add the required secrets and push your code. 🚀

