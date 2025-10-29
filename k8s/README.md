# Kubernetes Configurations

This directory contains all Kubernetes configurations for the DevOps project.

## 📁 Directory Structure

```
k8s/
├── backend/              # Backend API & Consumer services
│   ├── base/            # Base Kubernetes manifests
│   │   ├── namespace.yaml
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── consumer-deployment.yaml
│   └── kustomization.yaml
│
├── frontend/            # Frontend application & Ingress
│   ├── base/           # Base Kubernetes manifests
│   │   ├── namespace.yaml
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── ingress.yaml
│   └── kustomization.yaml
│
└── helm/               # Helm charts (optional)
    ├── devops-app/     # Complete application Helm chart
    └── consumer-chart/ # Consumer tasks Helm chart
```

## 🚀 Deployment Options

### Option 1: Kustomize (Recommended for Simplicity)

Deploy everything with a single command:

```bash
# Deploy backend (API + Consumers)
kubectl apply -k k8s/backend/

# Deploy frontend (App + Ingress)
kubectl apply -k k8s/frontend/

# Deploy everything at once
kubectl apply -k k8s/backend/ -k k8s/frontend/
```

**Benefits:**
- Simple and straightforward
- No additional tools required
- Direct control over manifests
- Native Kubernetes

### Option 2: Helm (Recommended for Advanced Features)

Deploy using Helm charts:

```bash
# Deploy complete application
helm install devops-app k8s/helm/devops-app/ \
  --namespace default \
  --create-namespace

# Or deploy consumers separately
helm install consumer-tasks k8s/helm/consumer-chart/ \
  --namespace backend \
  --create-namespace
```

**Benefits:**
- Templating and variables
- Easy upgrades and rollbacks
- Environment-specific values
- Package management

## 🌐 Domain Configuration

The application is configured with the following domains:

- **Frontend:** `http://kn-tech.click` → React App
- **Backend API:** `http://api.kn-tech.click` → Go API (`/api/v1/...`)

### Ingress Configuration

The ingress is configured with:
- NGINX Ingress Controller
- HTTP protocol (no TLS/SSL)

## 📦 Components

### Backend

- **API Server:** Go-based REST API
  - Health check endpoint: `/api/v1/health`
  - Users endpoint: `/api/v1/users`
  - Port: 8080

- **Consumer Workers:** Background task processors
  - `email-processor`: Email processing tasks
  - `data-sync`: Data synchronization tasks
  - `report-generator`: Report generation tasks

### Frontend

- **React App:** Single-page application
  - Fetches data from backend API
  - Health monitoring dashboard
  - User management interface
  - Port: 80 (nginx)

## 🔄 Update Deployments

### Using Kustomize

```bash
# Update backend
kubectl apply -k k8s/backend/

# Update frontend
kubectl apply -k k8s/frontend/

# Restart deployments
kubectl rollout restart deployment -n backend backend-api
kubectl rollout restart deployment -n frontend frontend-app
```

### Using Helm

```bash
# Upgrade application
helm upgrade devops-app k8s/helm/devops-app/

# Rollback if needed
helm rollback devops-app
```

## 🔍 Monitoring

Check deployment status:

```bash
# Backend
kubectl get pods -n backend
kubectl get svc -n backend
kubectl logs -n backend -l app=backend-api

# Frontend
kubectl get pods -n frontend
kubectl get svc -n frontend
kubectl get ingress -n frontend

# Consumers
kubectl get pods -n backend -l component=consumer
```

## 🛠️ Troubleshooting

### Check Pod Logs

```bash
# Backend API
kubectl logs -n backend -l app=backend-api --tail=100

# Specific consumer
kubectl logs -n backend -l task=email-processor --tail=100

# Frontend
kubectl logs -n frontend -l app=frontend-app --tail=100
```

### Check Ingress

```bash
# Get ingress details
kubectl describe ingress -n frontend

# Check ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
```

### Test Internal Connectivity

```bash
# Test backend from within cluster
kubectl run curl --image=curlimages/curl -i --rm --restart=Never -- \
  curl http://backend-api-service.backend.svc.cluster.local:8080/api/v1/health

# Test frontend service
kubectl run curl --image=curlimages/curl -i --rm --restart=Never -- \
  curl http://frontend-app-service.frontend.svc.cluster.local
```

## 🗑️ Cleanup

Remove all resources:

```bash
# Using Kustomize
kubectl delete -k k8s/backend/
kubectl delete -k k8s/frontend/

# Using Helm
helm uninstall devops-app
helm uninstall consumer-tasks

# Delete namespaces (removes everything)
kubectl delete namespace backend frontend
```

## 📝 Notes

- The `base/` directories contain the core Kubernetes manifests
- Kustomization files provide easy orchestration
- Helm charts offer advanced templating for complex scenarios
- All configurations use namespaces for isolation (`backend`, `frontend`)
- TLS certificates are managed by cert-manager

## 🔗 Related Documentation

- [Backend README](../backend/README.md)
- [Frontend README](../frontend/README.md)
- [GitHub Actions Workflows](../.github/workflows/README.md)
- [Helm Charts](./helm/)
