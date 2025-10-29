# Why Use Helm for Consumer Tasks?

## The Problem with Plain YAML

When you have multiple similar deployments (like consumer tasks), plain YAML leads to:
- **Code duplication**: Copying 40+ lines per task
- **Error-prone**: Easy to miss changes when updating all tasks
- **Hard to maintain**: Change image? Update 3+ files
- **Not DRY**: Violates "Don't Repeat Yourself" principle

## The Solution: Helm Templates with Loops & Variables

### Code Comparison

#### Adding a New Task

**Plain YAML (44 lines per task):**
```yaml
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

**Helm (3 lines):**
```yaml
tasks:
  - name: notification-sender
    replicas: 2
    description: "Sends notifications"
```

### The Magic: Template Loop

**templates/deployment.yaml:**
```yaml
{{- range .Values.tasks }}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: consumer-{{ .name }}
  namespace: {{ $.Values.namespace }}
  labels:
    {{- range $key, $value := $.Values.commonLabels }}
    {{ $key }}: {{ $value }}
    {{- end }}
    task: {{ .name }}
spec:
  replicas: {{ .replicas | default 1 }}
  # ... rest generated automatically
{{- end }}
```

This loop generates a full deployment for **each task** in your values.yaml!

## Real-World Benefits

### 1. Update Image for All Tasks

**Plain YAML:**
```bash
# Edit 3 separate files
vim consumer-email-processor.yaml
# Change: image: khoanguyen2610/backend:consumer-latest
vim consumer-data-sync.yaml
# Change: image: khoanguyen2610/backend:consumer-latest
vim consumer-report-generator.yaml
# Change: image: khoanguyen2610/backend:consumer-latest

kubectl apply -f consumer-email-processor.yaml
kubectl apply -f consumer-data-sync.yaml
kubectl apply -f consumer-report-generator.yaml
```

**Helm:**
```bash
helm upgrade consumers ./consumer-chart --set image.tag=consumer-v1.2.3
```

### 2. Scale All Tasks

**Plain YAML:**
```bash
# Edit replicas in 3 files
vim consumer-email-processor.yaml  # replicas: 2
vim consumer-data-sync.yaml         # replicas: 2
vim consumer-report-generator.yaml  # replicas: 2

kubectl apply -f consumer-email-processor.yaml
kubectl apply -f consumer-data-sync.yaml
kubectl apply -f consumer-report-generator.yaml
```

**Helm:**
```yaml
# Edit values.yaml once
tasks:
  - name: email-processor
    replicas: 2  # Change here
  - name: data-sync
    replicas: 2  # And here
  - name: report-generator
    replicas: 2  # And here
```

```bash
helm upgrade consumers ./consumer-chart
```

### 3. Different Configs Per Environment

**Plain YAML:**
```bash
# Need separate files for each environment
consumer-email-processor-dev.yaml
consumer-email-processor-staging.yaml
consumer-email-processor-prod.yaml
consumer-data-sync-dev.yaml
consumer-data-sync-staging.yaml
consumer-data-sync-prod.yaml
consumer-report-generator-dev.yaml
consumer-report-generator-staging.yaml
consumer-report-generator-prod.yaml
# = 9 files!
```

**Helm:**
```bash
# Just 3 values files (one per environment)
consumer-chart/examples/values-dev.yaml
consumer-chart/examples/values-staging.yaml
consumer-chart/examples/values-prod.yaml

# Deploy to different environments
helm install consumers ./consumer-chart -f examples/values-dev.yaml
helm install consumers ./consumer-chart -f examples/values-prod.yaml
```

## Helm Features You Get

### 1. Variables
```yaml
image:
  repository: {{ .Values.image.repository }}
  tag: {{ .Values.image.tag }}
```

### 2. Conditionals
```yaml
{{- if .description }}
annotations:
  description: {{ .description | quote }}
{{- end }}
```

### 3. Defaults
```yaml
replicas: {{ .replicas | default 1 }}
```

### 4. Loops
```yaml
{{- range .Values.tasks }}
  # Generate deployment for each task
{{- end }}
```

### 5. Per-Item Overrides
```yaml
tasks:
  - name: email-processor
    replicas: 1
    # Uses default resources
  
  - name: data-sync
    replicas: 2
    # Override resources for this task only
    resources:
      requests:
        cpu: 100m
```

## Comparison Table

| Operation | Plain YAML | Helm |
|-----------|-----------|------|
| Add new task | 44 lines | 3 lines |
| Update image | Edit 3 files | 1 command |
| Scale all | Edit 3 files | Edit 1 file |
| Environment configs | 9+ files | 3 files |
| Rollback | Manual | `helm rollback` |
| Preview changes | N/A | `helm template` |
| Version tracking | Git only | Git + Helm revisions |

## Common Questions

### Q: Is Helm complicated?

**A:** The basics are simple:
1. Define values in `values.yaml`
2. Use `{{ .Values.something }}` in templates
3. Use `{{- range }}` for loops
4. Deploy with `helm install`

You don't need to learn everything - just these basics cover 90% of use cases.

### Q: What if I can't use Helm?

**A:** Generate plain YAML from the Helm chart:
```bash
helm template consumers ./consumer-chart > consumers-all.yaml
kubectl apply -f consumers-all.yaml
```

You get the benefits of DRY code during development, but deploy plain YAML.

### Q: How does it work with GitOps (ArgoCD/Flux)?

**A:** Both ArgoCD and Flux have native Helm support. They can:
- Track your Helm chart in Git
- Automatically deploy changes
- Manage different environments
- Handle rollbacks

### Q: Can I still see the generated YAML?

**A:** Yes!
```bash
# See what will be deployed
helm template consumers ./consumer-chart

# Save to file
helm template consumers ./consumer-chart > preview.yaml
```

## Getting Started

### 1. Install Helm (if not already installed)

```bash
# macOS
brew install helm

# Linux
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### 2. Deploy Consumer Tasks

```bash
cd /Users/khoa.nguyen/Workings/Personal/devops
helm install consumers k8s/personal/consumer-chart/ -n backend --create-namespace
```

### 3. Verify

```bash
helm list -n backend
kubectl get pods -n backend -l app=consumer
```

### 4. Add a New Task

Edit `consumer-chart/values.yaml`:
```yaml
tasks:
  - name: email-processor
    replicas: 1
  - name: data-sync
    replicas: 1
  - name: report-generator
    replicas: 1
  - name: your-new-task    # Add these 3 lines!
    replicas: 1
    description: "Does something cool"
```

Update deployment:
```bash
helm upgrade consumers k8s/personal/consumer-chart/ -n backend
```

Done! 🎉

## Summary

**Helm = DRY + Variables + Loops + Production-Ready**

- ✅ Write once, deploy many
- ✅ Easy to maintain
- ✅ Environment-specific configs
- ✅ Built-in versioning and rollback
- ✅ GitOps compatible
- ✅ Industry standard

**Result:** Less code, fewer errors, easier maintenance!

## Next Steps

1. Read the [Helm Chart README](README.md)
2. Try the [example values files](examples/)
3. Check the [template file](templates/deployment.yaml) to see how it works
4. Deploy to your cluster and see the magic! ✨

