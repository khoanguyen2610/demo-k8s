# GitHub Actions CI/CD

Build and deploy pipeline for the DevOps application.

## Workflow Structure

```
┌─────────────────────────────────────────┐
│         BUILD STAGE (Parallel)          │
├─────────────┬──────────────┬────────────┤
│ Build       │ Build        │ Build      │
│ Backend     │ Frontend     │ Consumer   │
└──────┬──────┴──────┬───────┴─────┬──────┘
       │             │             │
       └─────────────┴─────────────┘
                     │
       ┌─────────────▼──────────────┐
       │      DEPLOY STAGE           │
       │  (main/master only)         │
       ├─────────────────────────────┤
       │ 1. Deploy Backend           │
       │ 2. Deploy Consumers         │
       │ 3. Deploy Frontend          │
       │ 4. Wait for Rollout         │
       └─────────────────────────────┘
```

## Triggers

- **Push:** main, master, develop
- **Pull Request:** main, master, develop

**Note:** Deployment only runs on `main` or `master` branch.

## Jobs

### Build Stage (Parallel)

All three builds run in parallel for speed:

1. **build-backend**
   - Builds backend API
   - Tags: `latest`, `{sha}`
   - Registry: `khoanguyen2610/backend`

2. **build-frontend**
   - Builds React frontend
   - Tags: `latest`, `{sha}`
   - Registry: `khoanguyen2610/frontend`

3. **build-consumer**
   - Builds consumer workers
   - Tags: `latest`, `{sha}`
   - Registry: `khoanguyen2610/consumer`

**Features:**
- ✅ Parallel execution (3 builds at once)
- ✅ Docker layer caching (GitHub Actions cache)
- ✅ Multi-stage Dockerfile support
- ✅ Automatic tagging (SHA + latest)

### Deploy Stage (Sequential)

Runs after all builds succeed, only on main/master:

1. **Configure kubectl**
   - Decodes KUBECONFIG secret
   - Sets up cluster connection

2. **Deploy Backend**
   - Applies Kustomize configs
   - Updates image to new SHA

3. **Deploy Consumers**
   - Updates all consumer deployments
   - email-processor, data-sync, report-generator

4. **Deploy Frontend**
   - Applies Kustomize configs
   - Updates image to new SHA

5. **Wait for Rollout**
   - Waits for all deployments
   - Timeout: 5 minutes per deployment

6. **Deployment Summary**
   - Shows pods, services, ingress
   - Timestamp

## Required Secrets

Add in: **Settings → Secrets and variables → Actions**

| Secret | Value | Description |
|--------|-------|-------------|
| `DOCKER_USERNAME` | `khoanguyen2610` | Docker Hub username |
| `DOCKER_PASSWORD` | Your password/token | Docker Hub authentication |
| `KUBECONFIG` | Base64 encoded config | Kubernetes cluster access |

## Setup

### Quick Setup

```bash
# 1. Docker Hub
gh secret set DOCKER_USERNAME -b "khoanguyen2610"
gh secret set DOCKER_PASSWORD

# 2. Kubernetes
kubectl config view --flatten --minify > kubeconfig.yaml
cat kubeconfig.yaml | base64 | gh secret set KUBECONFIG
rm kubeconfig.yaml

# 3. Verify
gh secret list
```

### Detailed Setup

See [SETUP-SECRETS.md](../SETUP-SECRETS.md)

## Usage

### Automatic Deployment

```bash
# Push to main/master to trigger deployment
git add .
git commit -m "Deploy new version"
git push origin main
```

### Watch Progress

1. Go to GitHub repository
2. Click **Actions** tab
3. Select latest workflow run
4. View logs for each job

### Check Deployment

```bash
# Check pods
kubectl get pods -n backend
kubectl get pods -n frontend

# Check services
kubectl get svc -n backend
kubectl get svc -n frontend

# Check ingress
kubectl get ingress -n frontend

# View logs
kubectl logs -n backend -l app=backend-api
kubectl logs -n frontend -l app=frontend-app
```

## Image Tags

All images are tagged with both SHA and `latest`:

```
# Backend
khoanguyen2610/backend:abc123def456  # SHA
khoanguyen2610/backend:latest        # Latest

# Frontend
khoanguyen2610/frontend:abc123def456
khoanguyen2610/frontend:latest

# Consumer
khoanguyen2610/consumer:abc123def456
khoanguyen2610/consumer:latest
```

**SHA tags** are used in deployment for:
- Immutability
- Traceability
- Easy rollback

## Deployment Flow

### On Feature Branch

```
Push to develop
  ↓
Build 3 images (parallel)
  ↓
Push to Docker Hub
  ↓
✅ Done (no deployment)
```

### On Main Branch

```
Push to main
  ↓
Build 3 images (parallel)
  ↓
Push to Docker Hub
  ↓
Deploy to Kubernetes
  ├─ Backend
  ├─ Consumers
  └─ Frontend
  ↓
Wait for rollout
  ↓
✅ Live!
```

## Rollback

If deployment fails or has issues:

```bash
# View rollout history
kubectl rollout history deployment/backend-api -n backend

# Rollback to previous version
kubectl rollout undo deployment/backend-api -n backend
kubectl rollout undo deployment/frontend-app -n frontend

# Rollback to specific revision
kubectl rollout undo deployment/backend-api -n backend --to-revision=2
```

## Local Development

### Build Locally

```bash
# Backend
docker build -t khoanguyen2610/backend:local backend/

# Frontend
docker build -t khoanguyen2610/frontend:local frontend/

# Consumer
docker build -t khoanguyen2610/consumer:local --target consumer backend/
```

### Run Locally

```bash
# Backend API
docker run -p 8080:8080 khoanguyen2610/backend:local

# Frontend
docker run -p 3000:80 khoanguyen2610/frontend:local

# Consumer
docker run khoanguyen2610/consumer:local --task email-processor
```

### Deploy Locally

```bash
# Deploy to local K8s
kubectl apply -k k8s/backend/
kubectl apply -k k8s/frontend/

# Use local images
kubectl set image deployment/backend-api backend-api=khoanguyen2610/backend:local -n backend
kubectl set image deployment/frontend-app frontend-app=khoanguyen2610/frontend:local -n frontend
```

## Troubleshooting

### Build Fails

**Check:**
- Docker Hub credentials
- Dockerfile syntax
- Build context files exist

**Fix:**
```bash
# Test build locally
docker build -f backend/Dockerfile backend/
docker build -f frontend/Dockerfile frontend/
```

### Deploy Fails - KUBECONFIG

**Error:** `connection refused to localhost:8080`

**Fix:**
```bash
# Re-encode kubeconfig
kubectl config view --flatten --minify > kubeconfig.yaml
cat kubeconfig.yaml | base64 | gh secret set KUBECONFIG
rm kubeconfig.yaml
```

### Deploy Fails - Image Pull

**Error:** `ImagePullBackOff` or `ErrImagePull`

**Check:**
```bash
# Verify image exists
docker pull khoanguyen2610/backend:latest

# Check deployment
kubectl describe pod <pod-name> -n backend
```

**Fix:**
- Check Docker Hub credentials
- Verify image was pushed successfully
- Check image name/tag spelling

### Rollout Timeout

**Error:** `rollout status timed out`

**Check:**
```bash
# View pod status
kubectl get pods -n backend
kubectl describe pod <pod-name> -n backend
kubectl logs <pod-name> -n backend
```

**Common causes:**
- Application crash on startup
- Wrong environment variables
- Missing config/secrets
- Resource limits too low

## Performance

### Build Time

- **Parallel builds:** ~3-5 minutes
- **With cache:** ~1-2 minutes

### Deploy Time

- **Apply configs:** ~10 seconds
- **Rollout:** ~1-3 minutes
- **Total:** ~2-4 minutes

### Optimization Tips

1. **Docker layer caching** (already enabled)
2. **Multi-stage builds** (already implemented)
3. **Smaller base images** (consider alpine)
4. **Parallel deployments** (can be added if needed)

## Monitoring

### GitHub Actions

- View workflow runs: Actions tab
- Download logs: Click run → Download logs
- Re-run failed jobs: Click "Re-run jobs"

### Kubernetes

```bash
# Watch deployments
kubectl get deployments -n backend -w

# Watch pods
kubectl get pods -n backend -w

# Stream logs
kubectl logs -f -n backend -l app=backend-api

# Events
kubectl get events -n backend --sort-by='.lastTimestamp'
```

## Environment Variables

Default values in workflow:

```yaml
DOCKER_REGISTRY: docker.io
DOCKER_USERNAME: khoanguyen2610
BACKEND_IMAGE: khoanguyen2610/backend
FRONTEND_IMAGE: khoanguyen2610/frontend
CONSUMER_IMAGE: khoanguyen2610/consumer
```

To customize, edit `.github/workflows/build-deploy.yml`

## Related Documentation

- [Setup Secrets](../SETUP-SECRETS.md)
- [Kubernetes Configs](../../k8s/README.md)
- [Backend README](../../backend/README.md)
- [Frontend README](../../frontend/README.md)

## Support

**Workflow issues?**
- Check GitHub Actions logs
- Verify secrets are set: `gh secret list`

**Kubernetes issues?**
- Check pod status: `kubectl get pods -n backend`
- View logs: `kubectl logs <pod-name> -n backend`
- Describe resources: `kubectl describe deployment backend-api -n backend`
