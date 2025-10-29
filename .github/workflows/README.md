# GitHub Actions Workflows

Simple CI/CD pipeline: Build Docker images → Push to Docker Hub → Deploy to Kubernetes.

## Workflow: build-deploy.yml

**Trigger:** Push to main/master/develop, Pull requests

**Flow:**
```
1. Build and Push (all branches)
   ├─ Build backend image
   ├─ Build consumer image
   └─ Build frontend image
   
2. Deploy (main/master only)
   ├─ Apply K8s configs
   ├─ Update image tags
   └─ Wait for rollout
```

## Required Secrets

Add these in: **Settings → Secrets and variables → Actions**

| Secret | Description | How to Get |
|--------|-------------|------------|
| `DOCKER_USERNAME` | Docker Hub username | Your username (e.g., `khoanguyen2610`) |
| `DOCKER_PASSWORD` | Docker Hub password/token | Your password or create a token at hub.docker.com/settings/security |
| `KUBECONFIG` | Kubernetes config (base64) | See setup below |

## Quick Setup

### 1. Docker Hub Secrets

```bash
gh secret set DOCKER_USERNAME -b "khoanguyen2610"
gh secret set DOCKER_PASSWORD  # Enter your password/token
```

### 2. Kubernetes Config

**If you have a cluster:**
```bash
# Get your kubeconfig
kubectl config view --flatten --minify > kubeconfig.yaml

# Encode and set as secret
cat kubeconfig.yaml | base64 | gh secret set KUBECONFIG

# Clean up
rm kubeconfig.yaml
```

**If you don't have a cluster:**

Use **Minikube** (local):
```bash
# Install and start
brew install minikube
minikube start

# Get kubeconfig
kubectl config view --flatten --minify > kubeconfig.yaml
cat kubeconfig.yaml | base64 | gh secret set KUBECONFIG
rm kubeconfig.yaml
```

Or use a **cloud provider**:
- DigitalOcean Kubernetes (~$12/month)
- Linode Kubernetes (~$10/month)
- Oracle Cloud (free tier)

### 3. Verify Setup

```bash
# Check secrets are set
gh secret list

# Should show:
# DOCKER_PASSWORD
# DOCKER_USERNAME
# KUBECONFIG
```

## How It Works

### On Every Push

**All branches (including PRs):**
- ✅ Builds Docker images
- ✅ Pushes to Docker Hub with SHA tag
- ✅ Also tags as `:latest`

**main/master branches only:**
- ✅ Deploys to Kubernetes
- ✅ Updates deployments with new image tags
- ✅ Waits for rollout to complete

### Image Tags

Images are tagged with both SHA and `latest`:

```bash
# Backend
khoanguyen2610/backend:abc123         # SHA
khoanguyen2610/backend:latest         # Latest

# Consumer
khoanguyen2610/backend:abc123-consumer
khoanguyen2610/backend:latest-consumer

# Frontend
khoanguyen2610/frontend:abc123
khoanguyen2610/frontend:latest
```

## Deployment Process

When you push to `main` or `master`:

```
1. Build Phase (~3-5 min)
   ✓ Builds all images in parallel
   ✓ Pushes to Docker Hub
   ✓ Uses layer caching for speed

2. Deploy Phase (~2-3 min)
   ✓ Connects to K8s cluster
   ✓ Applies kustomize configs
   ✓ Updates image tags
   ✓ Waits for rollout

3. Done!
   ✓ Shows pod status
   ✓ Shows ingress info
```

## Manual Deployment

Deploy from your local machine:

```bash
# Deploy backend
kubectl apply -k k8s/backend/

# Deploy frontend
kubectl apply -k k8s/frontend/

# Update images to latest
kubectl set image deployment/backend-api backend-api=khoanguyen2610/backend:latest -n backend
kubectl set image deployment/frontend-app frontend-app=khoanguyen2610/frontend:latest -n frontend
```

## Troubleshooting

### Build Fails

Check:
- Docker Hub credentials are correct
- Dockerfile syntax is valid
- All required files exist

### Deploy Fails

Check:
- KUBECONFIG secret is set correctly
- Cluster is accessible
- Namespaces exist (backend, frontend)

```bash
# Test kubeconfig locally
echo "$KUBECONFIG_BASE64" | base64 -d > test-config
kubectl --kubeconfig=test-config cluster-info
```

### Check Deployment

```bash
# View pods
kubectl get pods -n backend
kubectl get pods -n frontend

# View logs
kubectl logs -n backend -l app=backend-api
kubectl logs -n frontend -l app=frontend-app

# Check ingress
kubectl get ingress -n frontend
```

## Monitoring

### View Workflow

1. Go to GitHub → **Actions** tab
2. Click on the latest run
3. View logs for each step

### Check Kubernetes

```bash
# Check all resources
kubectl get all -n backend
kubectl get all -n frontend

# Check specific deployment
kubectl describe deployment backend-api -n backend

# Watch pods
kubectl get pods -n backend -w
```

## Rollback

If deployment fails:

```bash
# Rollback backend
kubectl rollout undo deployment/backend-api -n backend

# Rollback frontend
kubectl rollout undo deployment/frontend-app -n frontend

# Check rollout history
kubectl rollout history deployment/backend-api -n backend
```

## Local Development

Test locally without GitHub Actions:

```bash
# Build images
docker build -t khoanguyen2610/backend:dev backend/
docker build -t khoanguyen2610/frontend:dev frontend/

# Run locally
docker run -p 8080:8080 khoanguyen2610/backend:dev
docker run -p 3000:80 khoanguyen2610/frontend:dev

# Or deploy to local K8s
kubectl apply -k k8s/backend/
kubectl apply -k k8s/frontend/
```

## Environment Variables

Default images (can be changed in workflow):

```yaml
DOCKER_BACKEND_IMAGE: khoanguyen2610/backend
DOCKER_FRONTEND_IMAGE: khoanguyen2610/frontend
DOCKER_CONSUMER_IMAGE: khoanguyen2610/backend
```

## Resources

- [Kubernetes Configs](../k8s/README.md)
- [Backend README](../../backend/README.md)
- [Frontend README](../../frontend/README.md)
- [Setup Secrets Guide](../SETUP-SECRETS.md)
