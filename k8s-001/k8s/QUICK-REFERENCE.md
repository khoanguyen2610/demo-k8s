# Kubernetes Helm - Quick Reference Card

## 🚀 One-Liner Deployments

```bash
# Deploy everything
helm install myapp devops-app/ --create-namespace

# Deploy to production
helm install prod devops-app/ -f devops-app/values-prod.yaml

# Deploy to development
helm install dev devops-app/ -f devops-app/values-dev.yaml

# Deploy only consumers
helm install consumers consumer-chart/ -n backend --create-namespace
```

## ⚡ Common Commands

### Deploy & Upgrade

```bash
helm install myapp devops-app/                    # First install
helm upgrade myapp devops-app/                    # Update deployment
helm upgrade --install myapp devops-app/          # Install or upgrade
```

### Update Images

```bash
helm upgrade myapp devops-app/ --set backend.image.tag=v1.2.3
helm upgrade myapp devops-app/ --set frontend.image.tag=v2.0.0
helm upgrade myapp devops-app/ \
  --set backend.image.tag=v1.2.3 \
  --set frontend.image.tag=v2.0.0
```

### Scale

```bash
helm upgrade myapp devops-app/ --set backend.replicas=3
helm upgrade myapp devops-app/ --set frontend.replicas=2
helm upgrade myapp devops-app/ --set 'consumers.tasks[0].replicas=3'
```

### Enable/Disable Components

```bash
helm upgrade myapp devops-app/ --set frontend.enabled=false
helm upgrade myapp devops-app/ --set consumers.enabled=false
helm upgrade myapp devops-app/ --set ingress.enabled=false
```

### Status & Info

```bash
helm list                          # List all releases
helm status myapp                  # Release status
helm get values myapp              # Show current values
helm get manifest myapp            # Show deployed resources
helm history myapp                 # Release history
```

### Rollback & Delete

```bash
helm rollback myapp                # Rollback to previous
helm rollback myapp 3              # Rollback to revision 3
helm uninstall myapp               # Delete release
```

### Preview & Debug

```bash
helm template myapp devops-app/                  # Preview YAML
helm install myapp devops-app/ --dry-run --debug # Test install
helm lint devops-app/                            # Validate chart
```

## 📝 values.yaml Structure

```yaml
# Enable/disable components
components:
  backend: true
  frontend: true
  consumers: true
  ingress: true

# Backend configuration
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

# Frontend configuration
frontend:
  enabled: true
  replicas: 1
  image:
    repository: khoanguyen2610/frontend
    tag: latest

# Consumer tasks (loop!)
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

# Ingress routing
ingress:
  enabled: true
  frontend:
    host: your-domain.com
  backend:
    host: your-domain.com
```

## 🎯 Common Scenarios

### Update Backend to v1.2.3

```bash
helm upgrade myapp devops-app/ --set backend.image.tag=v1.2.3
```

### Scale Backend to 3 Replicas

```bash
helm upgrade myapp devops-app/ --set backend.replicas=3
```

### Add New Consumer Task

Edit `devops-app/values.yaml`:
```yaml
consumers:
  tasks:
    - name: new-task
      replicas: 1
```

Then:
```bash
helm upgrade myapp devops-app/
```

### Deploy Without Frontend

```bash
helm install myapp devops-app/ --set frontend.enabled=false
```

### Switch to Production Config

```bash
helm upgrade myapp devops-app/ -f devops-app/values-prod.yaml
```

### Rollback Bad Deployment

```bash
helm rollback myapp
```

## 🔍 Kubectl Commands

### Check Pods

```bash
kubectl get pods -n backend
kubectl get pods -n frontend
kubectl get pods -n backend -l app=consumer
```

### View Logs

```bash
kubectl logs -n backend -l app=backend-api -f
kubectl logs -n frontend -l app=frontend-app -f
kubectl logs -n backend -l task=email-processor -f
```

### Check Services

```bash
kubectl get svc -n backend
kubectl get svc -n frontend
```

### Check Ingress

```bash
kubectl get ingress -A
kubectl describe ingress -n frontend
```

## 📊 Comparison

| Task | Command |
|------|---------|
| Deploy all | `helm install myapp devops-app/` |
| Update image | `helm upgrade myapp devops-app/ --set backend.image.tag=v1.2.3` |
| Scale | `helm upgrade myapp devops-app/ --set backend.replicas=3` |
| Rollback | `helm rollback myapp` |
| Status | `helm status myapp` |
| Uninstall | `helm uninstall myapp` |

## 🌍 Environments

```bash
# Development
helm install dev devops-app/ -f devops-app/values-dev.yaml

# Production
helm install prod devops-app/ -f devops-app/values-prod.yaml

# Custom
helm install myapp devops-app/ -f my-values.yaml
```

## 🚦 CI/CD

```bash
# Deploy with commit SHA as tag
helm upgrade --install myapp devops-app/ \
  --set backend.image.tag=$CI_COMMIT_SHA \
  --set frontend.image.tag=$CI_COMMIT_SHA \
  -f devops-app/values-prod.yaml
```

## 📚 Documentation

- [Main README](README.md)
- [devops-app Chart](devops-app/README.md)
- [consumer-chart](consumer-chart/README.md)
- [Transformation Guide](HELM-TRANSFORMATION.md)

## ⚙️ Helm Installation

```bash
# macOS
brew install helm

# Linux
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Windows
choco install kubernetes-helm

# Verify
helm version
```

## 🎓 Helm Basics

```bash
helm install <name> <chart>         # Install release
helm upgrade <name> <chart>         # Upgrade release
helm rollback <name>                # Rollback release
helm uninstall <name>               # Uninstall release
helm list                           # List releases
helm status <name>                  # Check status
helm get values <name>              # Show values
helm template <name> <chart>        # Preview YAML
```

## 💡 Tips

1. **Always use specific tags in production**
   ```bash
   --set backend.image.tag=v1.0.0  # Not 'latest'
   ```

2. **Test with dry-run first**
   ```bash
   helm install myapp devops-app/ --dry-run --debug
   ```

3. **Keep values files in Git**
   ```
   devops-app/values-dev.yaml
   devops-app/values-prod.yaml
   ```

4. **Use semantic versioning**
   ```yaml
   image:
     tag: v1.2.3
   ```

## 🆘 Troubleshooting

```bash
# Chart validation
helm lint devops-app/

# Preview what will be deployed
helm template myapp devops-app/

# Dry run
helm install myapp devops-app/ --dry-run --debug

# Check current config
helm get values myapp

# See deployed resources
helm get manifest myapp

# Release history
helm history myapp
```

## 📞 Need Help?

- [devops-app/README.md](devops-app/README.md) - Detailed docs
- [HELM-TRANSFORMATION.md](HELM-TRANSFORMATION.md) - Before/after guide
- [Helm Documentation](https://helm.sh/docs/)

---

**Print this page for quick reference!** 📄

