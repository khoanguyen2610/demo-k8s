# Consumer Tasks Helm Chart

A Helm chart for deploying consumer background task processors to Kubernetes with clean, DRY configuration using templates and loops.

## Features

✨ **Clean & DRY**: Define tasks once in `values.yaml`, deploy multiple times  
🔄 **Loop-based**: Automatically generates deployments for all tasks  
🎯 **Variables**: Easy to configure and override  
📦 **Single source of truth**: All configuration in `values.yaml`  
🚀 **Easy to extend**: Add new tasks without duplicating YAML  

## Quick Start

### Install Helm

If you don't have Helm installed:

```bash
# macOS
brew install helm

# Linux
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Windows
choco install kubernetes-helm
```

### Deploy All Consumer Tasks

```bash
# Install/Deploy the chart
helm install consumers ./consumer-chart -n backend --create-namespace

# Or using full path
cd /Users/khoa.nguyen/Workings/Personal/devops
helm install consumers k8s/personal/consumer-chart/ -n backend --create-namespace
```

### Verify Deployment

```bash
# Check Helm release
helm list -n backend

# Check deployments
kubectl get deployments -n backend -l app=consumer

# Check pods
kubectl get pods -n backend -l app=consumer
```

## Configuration

All configuration is in `values.yaml`. The chart uses loops to generate deployments from the task list.

### Default Configuration

```yaml
# Image settings
image:
  repository: khoanguyen2610/backend
  tag: consumer-latest

# Resource limits (applied to all tasks)
resources:
  requests:
    cpu: 50m
    memory: 64Mi
  limits:
    cpu: 200m
    memory: 128Mi

# Define tasks (loop through this list)
tasks:
  - name: email-processor
    replicas: 1
  - name: data-sync
    replicas: 1
  - name: report-generator
    replicas: 1
```

### Adding a New Task

Simply add to the `tasks` list in `values.yaml`:

```yaml
tasks:
  - name: email-processor
    replicas: 1
  - name: data-sync
    replicas: 1
  - name: report-generator
    replicas: 1
  - name: notification-sender    # New task!
    replicas: 2
    description: "Sends notifications to users"
```

Then upgrade:

```bash
helm upgrade consumers ./consumer-chart -n backend
```

### Customizing Per Task

Override settings for specific tasks:

```yaml
tasks:
  - name: email-processor
    replicas: 2
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 400m
        memory: 256Mi
    env:
      - name: LOG_LEVEL
        value: "debug"
  
  - name: data-sync
    replicas: 1
    # Uses default resources
```

## Usage Examples

### Deploy with Custom Values

```bash
# Deploy with custom image tag
helm install consumers ./consumer-chart -n backend \
  --set image.tag=consumer-v1.2.3

# Deploy with different namespace
helm install consumers ./consumer-chart -n production \
  --set namespace=production
```

### Using Custom Values File

Create `my-values.yaml`:

```yaml
image:
  tag: consumer-v2.0.0

tasks:
  - name: email-processor
    replicas: 3
  - name: data-sync
    replicas: 2
  - name: report-generator
    replicas: 1

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 256Mi
```

Deploy:

```bash
helm install consumers ./consumer-chart -n backend -f my-values.yaml
```

### Upgrade Deployment

```bash
# Upgrade with new values
helm upgrade consumers ./consumer-chart -n backend

# Upgrade with different image
helm upgrade consumers ./consumer-chart -n backend \
  --set image.tag=consumer-v1.3.0

# Upgrade and reuse previous values
helm upgrade consumers ./consumer-chart -n backend --reuse-values
```

### Rollback

```bash
# List releases
helm history consumers -n backend

# Rollback to previous version
helm rollback consumers -n backend

# Rollback to specific revision
helm rollback consumers 2 -n backend
```

### Uninstall

```bash
# Uninstall/delete all consumer tasks
helm uninstall consumers -n backend
```

## Advanced Usage

### Preview Generated YAML

```bash
# See what will be deployed
helm template consumers ./consumer-chart

# Save generated YAML to file
helm template consumers ./consumer-chart > preview.yaml
```

### Debug

```bash
# Dry-run install
helm install consumers ./consumer-chart -n backend --dry-run --debug

# Show computed values
helm get values consumers -n backend
```

### Scale Tasks

```bash
# Scale email-processor to 3 replicas
helm upgrade consumers ./consumer-chart -n backend \
  --set tasks[0].replicas=3

# Or edit values.yaml and upgrade
helm upgrade consumers ./consumer-chart -n backend
```

### Change Image Tag

```bash
# Update to new version
helm upgrade consumers ./consumer-chart -n backend \
  --set image.tag=consumer-v2.0.0
```

## Environment-Specific Deployments

### Development Environment

Create `values-dev.yaml`:

```yaml
namespace: backend-dev
image:
  tag: consumer-latest
tasks:
  - name: email-processor
    replicas: 1
  - name: data-sync
    replicas: 1
  - name: report-generator
    replicas: 1
resources:
  requests:
    cpu: 25m
    memory: 32Mi
env:
  - name: ENV
    value: "development"
```

Deploy:

```bash
helm install consumers ./consumer-chart -n backend-dev -f values-dev.yaml
```

### Production Environment

Create `values-prod.yaml`:

```yaml
namespace: backend
image:
  tag: consumer-v1.0.0  # Use specific version
tasks:
  - name: email-processor
    replicas: 3
  - name: data-sync
    replicas: 2
  - name: report-generator
    replicas: 2
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 256Mi
env:
  - name: ENV
    value: "production"
```

Deploy:

```bash
helm install consumers ./consumer-chart -n backend -f values-prod.yaml
```

## Monitoring

```bash
# Watch deployment status
helm status consumers -n backend

# Get all resources
kubectl get all -n backend -l app=consumer

# View logs
kubectl logs -n backend -l task=email-processor -f
kubectl logs -n backend -l task=data-sync -f
kubectl logs -n backend -l task=report-generator -f
```

## Chart Structure

```
consumer-chart/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default values (define tasks here)
├── templates/
│   ├── deployment.yaml     # Template with loop over tasks
│   └── _helpers.tpl        # Helper functions
├── .helmignore            # Files to ignore
└── README.md              # This file
```

## How It Works

### The Loop Magic

In `templates/deployment.yaml`:

```yaml
{{- range .Values.tasks }}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: consumer-{{ .name }}
  # ... rest of deployment config
{{- end }}
```

This loops through each task defined in `values.yaml` and generates a complete deployment for it!

### Variables

- `{{ $.Values.image.repository }}` - Image repository
- `{{ $.Values.image.tag }}` - Image tag
- `{{ .name }}` - Task name (from loop)
- `{{ .replicas }}` - Replicas per task
- `{{ $.Values.resources }}` - Default resources
- `{{ .resources }}` - Task-specific resources (optional override)

## Benefits Over Plain YAML

| Feature | Plain YAML | Helm Chart |
|---------|-----------|------------|
| Add new task | Copy/paste 40+ lines | Add 2 lines |
| Update image | Edit 3 files | Change 1 value |
| Scale all tasks | Edit multiple files | Change 1 value |
| Environment configs | Multiple files | Multiple values files |
| Version control | Manual | Built-in |
| Rollback | Manual | One command |

## Tips

1. **Always use specific tags in production**: Don't use `latest`
   ```yaml
   image:
     tag: consumer-v1.2.3
   ```

2. **Test with dry-run first**:
   ```bash
   helm install consumers ./consumer-chart --dry-run --debug
   ```

3. **Keep values files in Git**:
   ```
   consumer-chart/
   ├── values-dev.yaml
   ├── values-staging.yaml
   └── values-prod.yaml
   ```

4. **Use semantic versioning** for Chart version in `Chart.yaml`

## Troubleshooting

### Chart Not Found

Make sure you're in the correct directory:
```bash
cd /Users/khoa.nguyen/Workings/Personal/devops
helm install consumers k8s/personal/consumer-chart/ -n backend
```

### Validation Errors

```bash
# Lint the chart
helm lint ./consumer-chart

# Validate generated YAML
helm template consumers ./consumer-chart | kubectl apply --dry-run=client -f -
```

### See What Changed

```bash
# Diff before upgrading
helm diff upgrade consumers ./consumer-chart -n backend
```

## More Resources

- [Helm Documentation](https://helm.sh/docs/)
- [Helm Template Guide](https://helm.sh/docs/chart_template_guide/)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)

