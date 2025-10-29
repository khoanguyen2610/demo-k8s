# Consumer Task Deployment Options

This document compares different ways to deploy consumer tasks to Kubernetes.

## Summary of Options

| Method | Complexity | Flexibility | Production Ready | GitOps Friendly | DRY Code |
|--------|-----------|-------------|------------------|-----------------|----------|
| **Helm Chart** | Medium | High | ✅✅ | ✅✅ | ✅✅ |
| **Single YAML** | Low | Medium | ✅ | ✅ | ❌ |
| **Bash Script** | Low | Low | ❌ | ❌ | ❌ |
| **Individual Files** | Low | Low | ⚠️ | ⚠️ | ❌ |

## 1. Helm Chart (Recommended - with loops & variables)

**Location:** `k8s/personal/consumer-chart/`

```bash
helm install consumers k8s/personal/consumer-chart/ -n backend --create-namespace
```

### Pros
- ✅✅ **DRY Code**: Define tasks once in `values.yaml`, loop generates all deployments
- ✅ **Variables**: Easy to configure and override (image, resources, replicas)
- ✅ **Loops**: Add new task = add 3 lines (vs 40+ lines of YAML)
- ✅ **Environment-specific**: Use different values files for dev/staging/prod
- ✅ **Version control**: Built-in versioning and rollback
- ✅ **Template functions**: Powerful Helm templating
- ✅ **Works with GitOps**: ArgoCD, Flux support Helm
- ✅ **Package management**: Easy to share and reuse

### Cons
- ⚠️ Requires Helm installed
- ⚠️ Slightly more complex than plain YAML
- ⚠️ Need to learn Helm templating basics

### Best for
- **Production deployments** (highly recommended)
- **Multi-environment setups** (dev/staging/prod)
- **Teams that value DRY code**
- **When you need to add tasks frequently**

### Key Files

**values.yaml** (Define all tasks here):
```yaml
tasks:
  - name: email-processor
    replicas: 1
  - name: data-sync
    replicas: 1
  - name: report-generator
    replicas: 1
  # Add new task = just 3 lines!
```

**templates/deployment.yaml** (Loop over tasks):
```yaml
{{- range .Values.tasks }}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: consumer-{{ .name }}
  # ... deployment config uses variables
{{- end }}
```

### Common Operations

```bash
# Deploy
helm install consumers ./consumer-chart -n backend --create-namespace

# Update image tag
helm upgrade consumers ./consumer-chart -n backend \
  --set image.tag=consumer-v1.2.3

# Use production values
helm install consumers ./consumer-chart -n backend \
  -f consumer-chart/examples/values-prod.yaml

# Rollback
helm rollback consumers -n backend

# Uninstall
helm uninstall consumers -n backend

# Preview generated YAML
helm template consumers ./consumer-chart
```

### Adding a New Task

Before (plain YAML - 40+ lines to copy/paste):
```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: consumer-new-task
  namespace: backend
  labels:
    app: consumer
    task: new-task
    tier: backend
spec:
  replicas: 1
  # ... 30+ more lines
```

After (Helm - just 3 lines):
```yaml
tasks:
  - name: new-task
    replicas: 1
    description: "Does something useful"
```

That's it! The template loop generates the full deployment automatically!

---

## 2. Bash Script (deploy-consumers.sh)

**Location:** `k8s/personal/deploy-consumers.sh`

```bash
./deploy-consumers.sh
```

### Pros
- ✅ Easy to understand
- ✅ Can add custom logic and checks
- ✅ Good for development/testing

### Cons
- ❌ Not declarative
- ❌ Harder to version control the process
- ❌ Doesn't work with GitOps tools
- ❌ Requires bash/shell access

### Best for
- Local development
- Quick testing
- One-off deployments

---

## 3. Single YAML File (consumers-all.yaml)

**Location:** `k8s/personal/consumers-all.yaml`

```bash
kubectl apply -f consumers-all.yaml
```

### Pros
- ✅ Pure Kubernetes config
- ✅ Easy to version control
- ✅ Works with GitOps tools
- ✅ Declarative and idempotent
- ✅ All resources in one place

### Cons
- ⚠️ Can become large
- ⚠️ Harder to manage individual resources
- ⚠️ No environment-specific configurations

### Best for
- Simple deployments
- Single environment setups
- Quick production deployments

### File Structure
```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: consumer-email-processor
...
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: consumer-data-sync
...
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: consumer-report-generator
...
```

**Note:** This file is auto-generated from the Helm chart:
```bash
cd k8s/personal
helm template consumers ./consumer-chart > consumers-all.yaml
```

---

## 4. Individual Files

**Location:** `k8s/personal/consumer-*.yaml`

```bash
kubectl apply -f consumer-email-processor.yaml
kubectl apply -f consumer-data-sync.yaml
kubectl apply -f consumer-report-generator.yaml
```

### Pros
- ✅ Simple and straightforward
- ✅ Easy to deploy/update single task
- ✅ Good for troubleshooting

### Cons
- ⚠️ Must apply multiple files
- ⚠️ Harder to ensure consistency
- ⚠️ Repetitive configurations

### Best for
- Development and testing
- Debugging specific tasks
- Learning Kubernetes

---

## Advanced: Environment-Specific Configurations with Helm

### Using Different Values Files

Create environment-specific values files:

```
consumer-chart/
├── Chart.yaml
├── values.yaml              # Default values
├── templates/
│   └── deployment.yaml      # Template with loops
└── examples/
    ├── values-dev.yaml      # Development config
    ├── values-staging.yaml  # Staging config
    └── values-prod.yaml     # Production config
```

**Deploy to development:**
```bash
helm install consumers ./consumer-chart -n backend-dev \
  -f consumer-chart/examples/values-dev.yaml
```

**Deploy to production:**
```bash
helm install consumers ./consumer-chart -n backend \
  -f consumer-chart/examples/values-prod.yaml
```

### Example: Production Values

`examples/values-prod.yaml`:
```yaml
namespace: backend
image:
  repository: khoanguyen2610/backend
  tag: consumer-v1.0.0  # Specific version
  pullPolicy: IfNotPresent

# Higher resources for production
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 256Mi

# Multiple replicas for HA
tasks:
  - name: email-processor
    replicas: 3
  - name: data-sync
    replicas: 2
  - name: report-generator
    replicas: 2

env:
  - name: ENV
    value: "production"
```

### Example: Development Values

`examples/values-dev.yaml`:
```yaml
namespace: backend-dev
image:
  tag: consumer-latest

# Lower resources for dev
resources:
  requests:
    cpu: 25m
    memory: 32Mi
  limits:
    cpu: 100m
    memory: 64Mi

# Single replica for dev
tasks:
  - name: email-processor
    replicas: 1
  - name: data-sync
    replicas: 1
  - name: report-generator
    replicas: 1

env:
  - name: ENV
    value: "development"
  - name: LOG_LEVEL
    value: "debug"
```

---

## GitOps Integration

### ArgoCD

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: consumers
spec:
  source:
    repoURL: https://github.com/your-repo/devops.git
    path: k8s/personal/consumers
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
    namespace: backend
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Flux

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: consumers
spec:
  interval: 5m
  path: ./k8s/personal/consumers
  prune: true
  sourceRef:
    kind: GitRepository
    name: devops
```

---

## Recommendations by Use Case

### Local Development
**Use:** Helm chart or bash script
```bash
helm install consumers ./consumer-chart -n backend --create-namespace
# or
./deploy-consumers.sh
```

### Single Production Environment
**Use:** Helm chart
```bash
helm install consumers ./consumer-chart -n backend \
  -f consumer-chart/examples/values-prod.yaml
```

### Multiple Environments (Dev/Staging/Prod)
**Use:** Helm with different values files
```bash
# Development
helm install consumers ./consumer-chart -n backend-dev \
  -f consumer-chart/examples/values-dev.yaml

# Production
helm install consumers ./consumer-chart -n backend \
  -f consumer-chart/examples/values-prod.yaml
```

### CI/CD Pipeline
**Use:** Helm
```bash
# In your CI/CD pipeline
helm upgrade --install consumers ./consumer-chart -n backend \
  --set image.tag=$CI_COMMIT_SHA
```

### GitOps (ArgoCD/Flux)
**Use:** Helm chart
- ArgoCD/Flux both have native Helm support
- Automatic syncs with Git
- Best practices for production

### No Helm Available
**Use:** Single YAML file (generated from Helm)
```bash
# Generate and apply
helm template consumers ./consumer-chart > consumers-all.yaml
kubectl apply -f consumers-all.yaml
```

---

## Quick Reference

| Task | Helm Chart | Single YAML | Bash Script |
|------|-----------|-------------|-------------|
| Deploy all | `helm install consumers ./consumer-chart -n backend` | `kubectl apply -f consumers-all.yaml` | `./deploy-consumers.sh` |
| Delete all | `helm uninstall consumers -n backend` | `kubectl delete -f consumers-all.yaml` | Manual |
| Update image | `helm upgrade ... --set image.tag=v1.2.3` | Edit YAML | Edit script |
| Scale | `helm upgrade ... --set tasks[0].replicas=3` | Edit YAML | Edit YAML |
| Rollback | `helm rollback consumers -n backend` | Manual | N/A |
| View changes | `helm template consumers ./consumer-chart` | N/A | N/A |
| Env-specific | Different values files | Multiple YAML files | Multiple scripts |
| Add new task | Add 3 lines to values.yaml | Copy/paste 40+ lines | Edit script |

---

## Why Helm? (Code Comparison)

### Adding a new task

**Without Helm (Plain YAML):**
```yaml
# Must copy/paste and edit 44 lines per task
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: consumer-notification-sender
  namespace: backend
  labels:
    app: consumer
    task: notification-sender
    tier: backend
spec:
  replicas: 1
  revisionHistoryLimit: 2
  selector:
    matchLabels:
      app: consumer
      task: notification-sender
  template:
    metadata:
      labels:
        app: consumer
        task: notification-sender
        tier: backend
    spec:
      containers:
      - name: notification-sender
        image: khoanguyen2610/backend:consumer-latest
        imagePullPolicy: Always
        args:
        - "--task=notification-sender"
        resources:
          requests:
            cpu: 50m
            memory: 64Mi
          limits:
            cpu: 200m
            memory: 128Mi
        env:
        - name: TASK_NAME
          value: "notification-sender"
        - name: ENV
          value: "production"
      restartPolicy: Always
```

**With Helm (values.yaml):**
```yaml
tasks:
  # ... existing tasks ...
  - name: notification-sender  # Just add these 3 lines!
    replicas: 2
    description: "Sends notifications"
```

**That's 44 lines vs 3 lines!** 🎉

---

## Migration Path

If you're currently using the bash script and want to move to a more production-ready approach:

1. **Start:** Bash script (quick dev testing)
2. **Better:** Single YAML file (declarative, but repetitive)
3. **Best:** Helm chart (DRY, flexible, production-ready)

The Helm approach is recommended for all use cases except quick local testing.

