# Kubernetes Configurations - Helm-Based

Modern, simplified Kubernetes configuration using Helm charts with templates, loops, and variables.

## 📁 Directory Structure

```
k8s/personal/
├── devops-app/              # 🎯 MAIN CHART - Deploy entire application
│   ├── Chart.yaml
│   ├── values.yaml          # All configuration in one file
│   ├── values-dev.yaml      # Development overrides
│   ├── values-prod.yaml     # Production overrides
│   ├── templates/           # Kubernetes templates with loops
│   └── README.md
│
├── consumer-chart/          # Consumer workers (standalone)
│   ├── values.yaml
│   ├── templates/
│   └── README.md
│
├── Legacy files (keep for reference):
│   ├── backend-deployment.yaml
│   ├── frontend-deployment.yaml
│   ├── ingress.yaml
│   └── namespaces.yaml
│
└── Documentation:
    ├── README.md                    # This file
    ├── CONSUMER-QUICK-START.md      # Consumer quick reference
    ├── DEPLOYMENT-OPTIONS.md        # Helm vs YAML comparison
    └── FREE-TIER-SETUP.md          # AWS setup guide
```

## 🚀 Quick Start

### Deploy Entire Application

```bash
# Deploy everything (backend, frontend, consumers, ingress)
helm install myapp devops-app/ --create-namespace

# Or from repository root
cd /Users/khoa.nguyen/Workings/Personal/devops
helm install myapp k8s/personal/devops-app/ --create-namespace
```

### Deploy to Specific Environment

```bash
# Development (lower resources, debug logging)
helm install myapp-dev devops-app/ -f devops-app/values-dev.yaml

# Production (multiple replicas, specific versions)
helm install myapp-prod devops-app/ -f devops-app/values-prod.yaml
```

### Check Status

```bash
helm status myapp
kubectl get all -n backend
kubectl get all -n frontend
```

## 🎯 What's Deployed

The main Helm chart deploys:

| Component | Description | Namespace |
|-----------|-------------|-----------|
| **Backend API** | Go REST API server | backend |
| **Frontend** | React application | frontend |
| **Consumers** | 3 background workers | backend |
| **Ingress** | Routing configuration | backend/frontend |
| **Namespaces** | backend and frontend | - |

## 📦 Charts Available

### 1. devops-app (Recommended)

**Complete application stack**

```bash
helm install myapp devops-app/
```

Includes:
- Backend API
- Frontend
- Consumer workers (3 tasks)
- Ingress routing
- Namespaces

[📖 Full Documentation](devops-app/README.md)

### 2. consumer-chart

**Standalone consumer workers**

```bash
helm install consumers consumer-chart/ -n backend
```

Includes:
- email-processor
- data-sync
- report-generator

[📖 Full Documentation](consumer-chart/README.md)

## ⚙️ Configuration

All configuration is in `devops-app/values.yaml`:

```yaml
# Enable/disable components
components:
  backend: true
  frontend: true
  consumers: true
  ingress: true

# Configure each component
backend:
  replicas: 1
  image:
    repository: khoanguyen2610/backend
    tag: latest

frontend:
  replicas: 1
  image:
    repository: khoanguyen2610/frontend
    tag: latest

# Consumer tasks (with loop!)
consumers:
  tasks:
    - name: email-processor
      replicas: 1
    - name: data-sync
      replicas: 1
    # Add more tasks easily
```

## 🔧 Common Operations

### Update Image Tags

```bash
# Update backend
helm upgrade myapp devops-app/ --set backend.image.tag=v1.2.3

# Update frontend
helm upgrade myapp devops-app/ --set frontend.image.tag=v2.0.0

# Update both
helm upgrade myapp devops-app/ \
  --set backend.image.tag=v1.2.3 \
  --set frontend.image.tag=v2.0.0
```

### Scale Components

```bash
# Scale backend
helm upgrade myapp devops-app/ --set backend.replicas=3

# Scale frontend
helm upgrade myapp devops-app/ --set frontend.replicas=2
```

### Deploy Specific Components

```bash
# Backend only
helm install backend devops-app/ \
  --set frontend.enabled=false \
  --set consumers.enabled=false

# Frontend only
helm install frontend devops-app/ \
  --set backend.enabled=false \
  --set consumers.enabled=false

# Consumers only (use standalone chart)
helm install consumers consumer-chart/ -n backend
```

### Rollback

```bash
# View history
helm history myapp

# Rollback to previous
helm rollback myapp

# Rollback to specific version
helm rollback myapp 3
```

### Uninstall

```bash
# Uninstall release
helm uninstall myapp

# Delete namespaces if needed
kubectl delete namespace backend frontend
```

## 🌍 Environments

### Development

```bash
helm install dev devops-app/ -f devops-app/values-dev.yaml
```

Features:
- Single replicas
- Latest images
- Lower resource limits
- Debug logging
- Ingress disabled (use port-forward)

### Production

```bash
helm install prod devops-app/ -f devops-app/values-prod.yaml
```

Features:
- Multiple replicas (HA)
- Specific version tags
- Higher resource limits
- Info-level logging
- Ingress enabled

## 📊 Before vs After Helm

### Before (Plain YAML)

```
Managing 10+ separate YAML files:
- namespaces.yaml
- backend-deployment.yaml
- backend-service.yaml
- frontend-deployment.yaml
- frontend-service.yaml
- consumer-email-processor.yaml
- consumer-data-sync.yaml
- consumer-report-generator.yaml
- frontend-ingress.yaml
- backend-ingress.yaml
```

**Problems:**
- ❌ Code duplication everywhere
- ❌ Update image? Edit 5+ files
- ❌ Add consumer? Copy 40+ lines
- ❌ Hard to maintain consistency
- ❌ No built-in rollback
- ❌ Environment configs = duplicate files

### After (Helm)

```
One chart with templates:
devops-app/
├── values.yaml              # All config here!
├── values-dev.yaml          # Dev overrides
├── values-prod.yaml         # Prod overrides
└── templates/               # Reusable templates
    ├── backend-deployment.yaml
    ├── frontend-deployment.yaml
    ├── consumer-deployments.yaml  # Loop!
    └── ingress.yaml
```

**Benefits:**
- ✅ Single source of truth
- ✅ Update image: 1 command
- ✅ Add consumer: 3 lines
- ✅ Consistent across deployments
- ✅ Built-in rollback
- ✅ Environment = different values file
- ✅ DRY code with loops and variables

## 🎯 Key Advantages

### 1. Simplified Updates

**Before:**
```bash
# Edit multiple files manually
vim backend-deployment.yaml        # Change image tag
vim consumer-email-processor.yaml  # Change image tag
vim consumer-data-sync.yaml        # Change image tag
vim consumer-report-generator.yaml # Change image tag

kubectl apply -f backend-deployment.yaml
kubectl apply -f consumer-email-processor.yaml
kubectl apply -f consumer-data-sync.yaml
kubectl apply -f consumer-report-generator.yaml
```

**After:**
```bash
helm upgrade myapp devops-app/ --set backend.image.tag=v1.2.3
```

### 2. Add New Consumer

**Before:** Copy/paste 44 lines of YAML

**After:** Add 3 lines:
```yaml
consumers:
  tasks:
    - name: new-task
      replicas: 1
```

### 3. Environment Management

**Before:** Maintain separate files for dev/staging/prod

**After:** One chart, different values files:
```bash
helm install dev devops-app/ -f values-dev.yaml
helm install prod devops-app/ -f values-prod.yaml
```

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
- name: Deploy
  run: |
    helm upgrade --install myapp k8s/personal/devops-app/ \
      --set backend.image.tag=${{ github.sha }} \
      -f k8s/personal/devops-app/values-prod.yaml
```

## 📚 Documentation

- [devops-app Chart](devops-app/README.md) - Main application chart
- [consumer-chart](consumer-chart/README.md) - Standalone consumers
- [Consumer Quick Start](CONSUMER-QUICK-START.md) - Quick reference
- [Deployment Options](DEPLOYMENT-OPTIONS.md) - Helm vs YAML comparison
- [FREE-TIER-SETUP.md](FREE-TIER-SETUP.md) - AWS EKS setup guide

## 🆘 Troubleshooting

### Preview What Will Be Deployed

```bash
helm template myapp devops-app/
```

### Dry Run

```bash
helm install myapp devops-app/ --dry-run --debug
```

### Check Current Values

```bash
helm get values myapp
```

### View Generated Resources

```bash
helm template myapp devops-app/ > generated.yaml
less generated.yaml
```

### Validate Chart

```bash
helm lint devops-app/
```

## 🎓 Learning Resources

### Helm Basics

```bash
# Install Helm (if not already)
brew install helm  # macOS
# or
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Basic commands
helm install <name> <chart>        # Deploy
helm upgrade <name> <chart>        # Update
helm rollback <name>               # Rollback
helm uninstall <name>              # Remove
helm list                          # List releases
helm status <name>                 # Check status
```

### Template Syntax

```yaml
# Variables
{{ .Values.backend.name }}

# Conditionals
{{- if .Values.backend.enabled }}
...
{{- end }}

# Loops
{{- range .Values.consumers.tasks }}
  name: {{ .name }}
{{- end }}

# Defaults
{{ .replicas | default 1 }}
```

## 🔄 Migration Path

If you're migrating from plain YAML:

1. **Start:** Use existing YAML files ✅
2. **Migration:** Deploy with Helm ← **You are here**
3. **Optimization:** Customize values for your needs
4. **Production:** Use environment-specific values files

The legacy YAML files are kept for reference but no longer needed for deployment.

## 🎉 Summary

| Aspect | Plain YAML | Helm Chart |
|--------|-----------|------------|
| Files to manage | 10+ | 1 chart |
| Update image | Edit 5+ files | 1 command |
| Add consumer | 44 lines | 3 lines |
| Environments | Duplicate files | Values files |
| Rollback | Manual | Built-in |
| Consistency | Error-prone | Guaranteed |
| Maintainability | Hard | Easy |

**Result: 10x simpler, faster, and easier to maintain!** 🚀

## 📞 Quick Commands Cheat Sheet

```bash
# Deploy
helm install myapp devops-app/

# Deploy to environment
helm install myapp devops-app/ -f devops-app/values-prod.yaml

# Update
helm upgrade myapp devops-app/

# Update image
helm upgrade myapp devops-app/ --set backend.image.tag=v1.2.3

# Rollback
helm rollback myapp

# Status
helm status myapp
helm list
kubectl get all -n backend
kubectl get all -n frontend

# Logs
kubectl logs -n backend -l app=backend-api -f
kubectl logs -n frontend -l app=frontend-app -f
kubectl logs -n backend -l app=consumer -f

# Uninstall
helm uninstall myapp
```

---

**Next Steps:**
1. Read [devops-app/README.md](devops-app/README.md) for detailed documentation
2. Try deploying with `helm install myapp devops-app/`
3. Customize `values.yaml` for your needs
4. Set up CI/CD with Helm commands
