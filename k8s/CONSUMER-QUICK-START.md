# Consumer Tasks - Quick Start Guide

Quick reference for deploying and managing consumer tasks in Kubernetes.

## 🚀 Quick Deploy

### Recommended: Using Helm (with loops & variables)

```bash
# Deploy all consumers at once with Helm
helm install consumers k8s/personal/consumer-chart/ -n backend --create-namespace

# Check status
helm status consumers -n backend

# Upgrade
helm upgrade consumers k8s/personal/consumer-chart/ -n backend

# Uninstall
helm uninstall consumers -n backend
```

### Using Single YAML File (kubectl)

```bash
# Deploy all consumers from one file
kubectl apply -f k8s/personal/consumers-all.yaml

# Delete all consumers
kubectl delete -f k8s/personal/consumers-all.yaml
```

**Note:** The `consumers-all.yaml` is auto-generated from the Helm chart. To regenerate:
```bash
cd k8s/personal
helm template consumers ./consumer-chart > consumers-all.yaml
```

### Using Bash Script (Legacy)

```bash
cd k8s/personal
./deploy-consumers.sh
```

## 📦 Individual Deployments

Deploy tasks individually:

```bash
# Email processor
kubectl apply -f k8s/personal/consumer-email-processor.yaml

# Data sync
kubectl apply -f k8s/personal/consumer-data-sync.yaml

# Report generator
kubectl apply -f k8s/personal/consumer-report-generator.yaml
```

## 📊 Monitoring

### Check Pod Status

```bash
# All consumer pods
kubectl get pods -n backend -l app=consumer

# Specific task
kubectl get pods -n backend -l task=email-processor
kubectl get pods -n backend -l task=data-sync
kubectl get pods -n backend -l task=report-generator
```

### View Logs

```bash
# All consumer logs
kubectl logs -n backend -l app=consumer -f --tail=50

# Specific task logs
kubectl logs -n backend -l task=email-processor -f
kubectl logs -n backend -l task=data-sync -f
kubectl logs -n backend -l task=report-generator -f
```

### Check Resource Usage

```bash
# CPU and memory usage
kubectl top pods -n backend -l app=consumer

# Detailed pod information
kubectl describe pod -n backend -l app=consumer
```

## 🔄 Restart / Update

### Restart Specific Task

```bash
# Restart email-processor
kubectl rollout restart deployment/consumer-email-processor -n backend

# Restart data-sync
kubectl rollout restart deployment/consumer-data-sync -n backend

# Restart report-generator
kubectl rollout restart deployment/consumer-report-generator -n backend
```

### Restart All Consumer Tasks

```bash
kubectl rollout restart deployment -n backend -l app=consumer
```

### Update Image

```bash
# Update email-processor image
kubectl set image deployment/consumer-email-processor -n backend \
  email-processor=khoanguyen2610/backend:consumer-latest

# Force pull latest image
kubectl rollout restart deployment/consumer-email-processor -n backend
```

## 📈 Scaling

### Scale Individual Task

```bash
# Scale email-processor to 2 replicas
kubectl scale deployment/consumer-email-processor -n backend --replicas=2

# Scale data-sync to 3 replicas
kubectl scale deployment/consumer-data-sync -n backend --replicas=3
```

### Scale All Consumer Tasks

```bash
# Scale all to 2 replicas
kubectl scale deployment -n backend -l app=consumer --replicas=2
```

## 🧹 Cleanup

### Delete Specific Task

```bash
kubectl delete -f consumer-email-processor.yaml
# or
kubectl delete deployment consumer-email-processor -n backend
```

### Delete All Consumer Tasks

```bash
kubectl delete deployment -n backend -l app=consumer
```

## 🐛 Troubleshooting

### Pod Not Starting

```bash
# Check events
kubectl describe pod -n backend -l app=consumer

# Check pod status
kubectl get pods -n backend -l app=consumer -o wide
```

### View Previous Logs (if pod crashed)

```bash
kubectl logs -n backend -l task=email-processor --previous
```

### Interactive Shell (for debugging)

```bash
# Get pod name first
POD_NAME=$(kubectl get pods -n backend -l task=email-processor -o jsonpath='{.items[0].metadata.name}')

# Execute shell
kubectl exec -it -n backend $POD_NAME -- /bin/sh
```

### Check Events

```bash
# Check recent events in namespace
kubectl get events -n backend --sort-by='.lastTimestamp' | grep consumer
```

## 🎯 Useful One-Liners

```bash
# Watch pod status in real-time
watch kubectl get pods -n backend -l app=consumer

# Stream all consumer logs to separate windows
kubectl logs -n backend -l task=email-processor -f &
kubectl logs -n backend -l task=data-sync -f &
kubectl logs -n backend -l task=report-generator -f &

# Count running consumer pods
kubectl get pods -n backend -l app=consumer --field-selector=status.phase=Running --no-headers | wc -l

# Get all consumer deployments with their images
kubectl get deployments -n backend -l app=consumer -o custom-columns=NAME:.metadata.name,IMAGE:.spec.template.spec.containers[0].image,REPLICAS:.spec.replicas

# Port-forward (if needed for debugging)
kubectl port-forward -n backend deployment/consumer-email-processor 8080:8080
```

## 🔧 Configuration

### Environment Variables

Each consumer pod can be configured via environment variables in the deployment YAML:

```yaml
env:
- name: TASK_NAME
  value: "email-processor"
- name: ENV
  value: "production"
- name: LOG_LEVEL
  value: "info"
```

### Resource Limits

Current configuration (modify in YAML if needed):

```yaml
resources:
  requests:
    cpu: 50m
    memory: 64Mi
  limits:
    cpu: 200m
    memory: 128Mi
```

## 📝 Task Details

| Task | Name | Description |
|------|------|-------------|
| Email Processor | `email-processor` | Processes emails (sending, filtering, categorizing, archiving) |
| Data Sync | `data-sync` | Syncs data between systems (DB, API, files, cache) |
| Report Generator | `report-generator` | Generates reports (daily, weekly, monthly, quarterly) |

## 🔗 Related Documentation

- [Consumer Application README](../../backend/cmd/consumer/README.md)
- [Backend README](../../backend/README.md)
- [Kubernetes Handbook](../handbook.md)

