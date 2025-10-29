# DevOps Application - Helm Chart

Complete Helm chart for deploying the entire DevOps application stack: Frontend (React), Backend API (Go), Consumer Workers (Go), and Ingress routing.

## 🎯 One Chart to Rule Them All

Instead of managing 10+ separate YAML files, everything is now in **one place**:
- ✅ Single `values.yaml` with all configuration
- ✅ Templates with loops and variables
- ✅ Environment-specific configs
- ✅ Enable/disable components easily
- ✅ DRY code - no duplication

## 📦 What's Included

This chart deploys:
- **Backend API** (Go REST API)
- **Frontend** (React application)
- **Consumer Workers** (3 background tasks)
- **Ingress** (Routing configuration)
- **Namespaces** (backend and frontend)

## 🚀 Quick Start

### Deploy Everything

```bash
# Deploy entire application (all components)
helm install myapp k8s/personal/devops-app/ --create-namespace

# Or with full path
cd /Users/khoa.nguyen/Workings/Personal/devops
helm install myapp k8s/personal/devops-app/ --create-namespace
```

### Deploy to Specific Environment

```bash
# Development
helm install myapp k8s/personal/devops-app/ -f k8s/personal/devops-app/values-dev.yaml

# Production
helm install myapp k8s/personal/devops-app/ -f k8s/personal/devops-app/values-prod.yaml
```

### Check Status

```bash
# Helm release status
helm status myapp

# All resources
kubectl get all -n backend
kubectl get all -n frontend

# Check ingress
kubectl get ingress -A
```

## ⚙️ Configuration

All configuration is centralized in `values.yaml`. Here are the key sections:

### Enable/Disable Components

```yaml
components:
  backend: true      # Set to false to disable backend
  frontend: true     # Set to false to disable frontend
  consumers: true    # Set to false to disable consumers
  ingress: true      # Set to false to disable ingress
```

### Backend Configuration

```yaml
backend:
  enabled: true
  replicas: 1
  image:
    repository: khoanguyen2610/backend
    tag: latest
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
```

### Frontend Configuration

```yaml
frontend:
  enabled: true
  replicas: 1
  image:
    repository: khoanguyen2610/frontend
    tag: latest
```

### Consumer Tasks (with loop!)

```yaml
consumers:
  enabled: true
  tasks:
    - name: email-processor
      replicas: 1
    - name: data-sync
      replicas: 1
    - name: report-generator
      replicas: 1
    # Add new task - just 3 lines!
```

### Ingress Configuration

```yaml
ingress:
  enabled: true
  frontend:
    host: your-domain.com
    path: /
  backend:
    host: your-domain.com
    path: /api
```

## 📚 Common Operations

### Deploy Only Backend

```bash
helm install myapp ./devops-app \
  --set frontend.enabled=false \
  --set consumers.enabled=false \
  --set ingress.enabled=false
```

### Deploy Only Frontend

```bash
helm install myapp ./devops-app \
  --set backend.enabled=false \
  --set consumers.enabled=false \
  --set ingress.enabled=false
```

### Deploy Without Consumers

```bash
helm install myapp ./devops-app --set consumers.enabled=false
```

### Update Image Tags

```bash
# Update backend image
helm upgrade myapp ./devops-app --set backend.image.tag=v1.2.3

# Update frontend image
helm upgrade myapp ./devops-app --set frontend.image.tag=v2.0.0

# Update both
helm upgrade myapp ./devops-app \
  --set backend.image.tag=v1.2.3 \
  --set frontend.image.tag=v2.0.0
```

### Scale Components

```bash
# Scale backend
helm upgrade myapp ./devops-app --set backend.replicas=3

# Scale frontend
helm upgrade myapp ./devops-app --set frontend.replicas=2

# Scale specific consumer
helm upgrade myapp ./devops-app \
  --set 'consumers.tasks[0].replicas=3'
```

### Add New Consumer Task

Edit `values.yaml`:
```yaml
consumers:
  tasks:
    - name: email-processor
      replicas: 1
    - name: data-sync
      replicas: 1
    - name: report-generator
      replicas: 1
    - name: notification-sender  # New task!
      replicas: 2
```

Then upgrade:
```bash
helm upgrade myapp ./devops-app
```

## 🌍 Environment-Specific Deployments

### Development Environment

```bash
helm install myapp-dev ./devops-app -f values-dev.yaml

# Features:
# - Lower resource limits
# - Latest images
# - Debug logging
# - Single replicas
# - Ingress disabled (use port-forward)
```

### Production Environment

```bash
helm install myapp-prod ./devops-app -f values-prod.yaml

# Features:
# - Higher resources
# - Specific version tags
# - Multiple replicas for HA
# - Info-level logging
# - Ingress enabled
```

## 🔍 Monitoring

### View Logs

```bash
# Backend logs
kubectl logs -n backend -l app=backend-api -f

# Frontend logs
kubectl logs -n frontend -l app=frontend-app -f

# Consumer logs (all)
kubectl logs -n backend -l app=consumer -f

# Specific consumer
kubectl logs -n backend -l task=email-processor -f
```

### Check Resources

```bash
# All deployments
helm status myapp

# CPU/Memory usage
kubectl top pods -n backend
kubectl top pods -n frontend

# Events
kubectl get events -n backend --sort-by='.lastTimestamp'
```

## 🔄 Upgrade & Rollback

### Upgrade Deployment

```bash
# After changing values.yaml
helm upgrade myapp ./devops-app

# With new values file
helm upgrade myapp ./devops-app -f values-prod.yaml

# Reuse previous values
helm upgrade myapp ./devops-app --reuse-values
```

### Rollback

```bash
# View release history
helm history myapp

# Rollback to previous version
helm rollback myapp

# Rollback to specific revision
helm rollback myapp 3
```

## 🧹 Cleanup

### Uninstall Everything

```bash
# Uninstall the release (keeps namespaces)
helm uninstall myapp

# Delete namespaces too
kubectl delete namespace backend frontend
```

### Uninstall Specific Component

```bash
# Just disable in values and upgrade
helm upgrade myapp ./devops-app --set consumers.enabled=false
```

## 🛠️ Advanced Usage

### Preview Generated YAML

```bash
# See all generated Kubernetes resources
helm template myapp ./devops-app

# Save to file
helm template myapp ./devops-app > generated.yaml

# Preview with specific values
helm template myapp ./devops-app -f values-prod.yaml > prod-generated.yaml
```

### Dry Run

```bash
# Test install without actually deploying
helm install myapp ./devops-app --dry-run --debug

# Test upgrade
helm upgrade myapp ./devops-app --dry-run --debug
```

### Lint Chart

```bash
# Validate chart syntax
helm lint ./devops-app

# Validate with values
helm lint ./devops-app -f values-prod.yaml
```

## 📊 Before vs After

### Before (Plain YAML)

```
10+ separate files:
├── namespaces.yaml
├── backend-deployment.yaml
├── backend-service.yaml
├── frontend-deployment.yaml
├── frontend-service.yaml
├── consumer-email-processor.yaml
├── consumer-data-sync.yaml
├── consumer-report-generator.yaml
├── frontend-ingress.yaml
└── backend-ingress.yaml
```

**Problems:**
- Duplicate code everywhere
- Update image? Edit 5+ files
- Add consumer? Copy/paste 40 lines
- Different environments? Duplicate all files
- Hard to maintain consistency

### After (Helm Chart)

```
One chart:
├── Chart.yaml
├── values.yaml              # All config here!
├── values-dev.yaml          # Dev overrides
├── values-prod.yaml         # Prod overrides
└── templates/
    ├── namespaces.yaml
    ├── backend-deployment.yaml
    ├── backend-service.yaml
    ├── frontend-deployment.yaml
    ├── frontend-service.yaml
    ├── consumer-deployments.yaml  # Loop for all consumers
    └── ingress.yaml
```

**Benefits:**
- ✅ Single source of truth
- ✅ Update image: Change 1 value
- ✅ Add consumer: Add 3 lines
- ✅ Environments: Different values files
- ✅ Easy to maintain
- ✅ Built-in rollback
- ✅ Version tracking

## 🎯 Key Benefits

### 1. Simplified Configuration

**Before:**
```bash
# Need to edit multiple files
vim backend-deployment.yaml
vim consumer-email-processor.yaml
vim consumer-data-sync.yaml
vim consumer-report-generator.yaml
# ...change image in each file

kubectl apply -f backend-deployment.yaml
kubectl apply -f consumer-email-processor.yaml
kubectl apply -f consumer-data-sync.yaml
kubectl apply -f consumer-report-generator.yaml
```

**After:**
```bash
# Just one command
helm upgrade myapp ./devops-app --set backend.image.tag=v1.2.3
```

### 2. Environment Management

**Before:**
```
Need duplicate files for each environment:
backend-deployment-dev.yaml
backend-deployment-staging.yaml
backend-deployment-prod.yaml
frontend-deployment-dev.yaml
frontend-deployment-staging.yaml
frontend-deployment-prod.yaml
# ... and so on
```

**After:**
```bash
# One chart, different values
helm install dev ./devops-app -f values-dev.yaml
helm install prod ./devops-app -f values-prod.yaml
```

### 3. Consistency

All deployments use the same templates, ensuring consistency across:
- Resource limits
- Labels
- Probes
- Environment variables

## 🚦 CI/CD Integration

### GitLab CI

```yaml
deploy:
  stage: deploy
  script:
    - helm upgrade --install myapp k8s/personal/devops-app/ \
        --set backend.image.tag=$CI_COMMIT_SHA \
        --set frontend.image.tag=$CI_COMMIT_SHA \
        -f k8s/personal/devops-app/values-prod.yaml
```

### GitHub Actions

```yaml
- name: Deploy with Helm
  run: |
    helm upgrade --install myapp k8s/personal/devops-app/ \
      --set backend.image.tag=${{ github.sha }} \
      --set frontend.image.tag=${{ github.sha }} \
      -f k8s/personal/devops-app/values-prod.yaml
```

## 🔗 Related Charts

- [Consumer Chart](../consumer-chart/) - Standalone consumer workers
- Can be used independently if you only need consumers

## 📖 Further Reading

- [Helm Documentation](https://helm.sh/docs/)
- [values.yaml](values.yaml) - See all configuration options
- [values-dev.yaml](values-dev.yaml) - Development configuration
- [values-prod.yaml](values-prod.yaml) - Production configuration

## 🎉 Quick Comparison

| Task | Before (Plain YAML) | After (Helm) |
|------|---------------------|--------------|
| Deploy all | Apply 10+ files | 1 command |
| Update images | Edit 5+ files | 1 value change |
| Add consumer | 44 lines | 3 lines |
| Scale backend | Edit YAML, apply | 1 command |
| Environment configs | Duplicate all files | 1 values file |
| Rollback | Manual | `helm rollback` |
| View current config | Check each file | `helm get values` |

**Result: 10x simpler, 10x faster, 10x easier to maintain!** 🚀

