# 🚀 ArgoCD GitOps Setup

## 📁 Directory Structure

```
argocd/
├── namespace.yaml              # ArgoCD namespace
├── install.yaml                # Installation reference
├── argocd-configmap.yaml       # ArgoCD configuration
├── argocd-ingress.yaml         # Ingress for ArgoCD UI
├── applications/               # Application definitions
│   ├── backend-app.yaml        # Backend application
│   ├── frontend-app.yaml       # Frontend application
│   ├── monitoring-app.yaml     # Monitoring stack
│   ├── logging-app.yaml        # Logging stack
│   └── app-of-apps.yaml        # App of Apps pattern
└── README.md                   # This file
```

---

## 🎯 Installation

### Step 1: Install ArgoCD

```bash
# Create namespace
kubectl apply -f k8s/1-platform/argocd/namespace.yaml

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
```

### Step 2: Get Initial Password

```bash
# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo
```

### Step 3: Access ArgoCD UI

```bash
# Port forward
kubectl port-forward svc/argocd-server -n argocd 8081:443 &

# Open UI
open https://localhost:8081

# Login with:
# Username: admin
# Password: [from step 2]
```

### Step 4: Apply Custom Configuration

```bash
# Apply ConfigMap (optional)
kubectl apply -f k8s/1-platform/argocd/argocd-configmap.yaml

# Apply Ingress (optional - for public access)
kubectl apply -f k8s/1-platform/argocd/argocd-ingress.yaml
```

---

## 🔄 Register Current Cluster

ArgoCD needs to know about the cluster it's running in:

```bash
# ArgoCD automatically registers its own cluster as:
# https://kubernetes.default.svc

# Verify cluster registration
kubectl get cm argocd-cm -n argocd -o yaml
```

---

## 📦 Deploy Applications

### Option 1: App of Apps Pattern (Recommended)

Deploy everything at once:

```bash
# Deploy the root app (manages all other apps)
kubectl apply -f k8s/1-platform/argocd/applications/app-of-apps.yaml

# This will automatically deploy:
# - Backend application
# - Frontend application
# - Monitoring stack
# - Logging stack
```

### Option 2: Individual Applications

Deploy applications one by one:

```bash
# Backend
kubectl apply -f k8s/1-platform/argocd/applications/backend-app.yaml

# Frontend
kubectl apply -f k8s/1-platform/argocd/applications/frontend-app.yaml

# Monitoring
kubectl apply -f k8s/1-platform/argocd/applications/monitoring-app.yaml

# Logging
kubectl apply -f k8s/1-platform/argocd/applications/logging-app.yaml
```

---

## 🌐 Public Access (Optional)

### Via Ingress

The ingress is configured for: `argocd.local.kn-tech.click`

```bash
# Apply ingress
kubectl apply -f k8s/1-platform/argocd/argocd-ingress.yaml

# Add to /etc/hosts or update DNS
echo "127.0.0.1 argocd.local.kn-tech.click" | sudo tee -a /etc/hosts

# Access at
open https://argocd.local.kn-tech.click
```

### Via Cloudflare Tunnel

Add to `~/.cloudflared/config.yml`:

```yaml
ingress:
  - hostname: argocd.kn-tech.click
    service: https://localhost:8081
    originRequest:
      noTLSVerify: true
  # ... other services
```

---

## 🔧 Configuration

### Update Git Repository

Edit each application file to point to your Git repository:

```yaml
source:
  repoURL: https://github.com/YOUR_USERNAME/devops.git  # Update this
  targetRevision: HEAD
  path: k8s-practise/k8s/2-apps/backend
```

### Sync Policies

Each application has auto-sync enabled:

```yaml
syncPolicy:
  automated:
    prune: true       # Delete resources not in Git
    selfHeal: true    # Auto-fix manual changes
```

To disable auto-sync, remove the `automated` section.

---

## 📊 Managing Applications

### Via UI

1. Open https://localhost:8081
2. Login with admin credentials
3. View all applications
4. Click on an app to see details
5. Sync, refresh, or delete as needed

### Via CLI

```bash
# Install ArgoCD CLI
brew install argocd

# Login
argocd login localhost:8081 --username admin --insecure

# List applications
argocd app list

# Get app details
argocd app get backend

# Sync application
argocd app sync backend

# Watch sync status
argocd app wait backend --sync

# View history
argocd app history backend

# Rollback
argocd app rollback backend 1

# Delete application
argocd app delete backend
```

---

## 🔄 GitOps Workflow

### Making Changes

1. **Update Code**
   ```bash
   cd k8s-001/backend
   # Make changes
   ```

2. **Build & Push Image**
   ```bash
   docker build --target api -t khoanguyen2610/backend:v2.0 .
   docker push khoanguyen2610/backend:v2.0
   ```

3. **Update Manifest in Git**
   ```bash
   cd k8s-practise/k8s/2-apps/backend
   # Edit deployment.yaml - update image tag
   git add .
   git commit -m "Update backend to v2.0"
   git push
   ```

4. **ArgoCD Auto-Deploys!** ✅
   - ArgoCD detects Git change
   - Automatically syncs
   - Updates pods
   - Shows status in UI

---

## 🎯 Application Structure

### Backend Application

**Path**: `k8s-practise/k8s/2-apps/backend`

Includes:
- Deployment (2 replicas)
- Service (ClusterIP)
- Ingress (NGINX)
- ConfigMap
- 3 Consumer deployments

### Frontend Application

**Path**: `k8s-practise/k8s/2-apps/frontend`

Includes:
- Deployment (2 replicas)
- Service (ClusterIP)
- Ingress (NGINX)
- ConfigMap

### Monitoring Stack

**Path**: `k8s-practise/k8s/1-platform/monitoring`

Includes:
- Prometheus deployment & service
- Grafana deployment & service
- ConfigMaps for both

### Logging Stack

**Path**: `k8s-practise/k8s/1-platform/logging`

Includes:
- Loki deployment & service
- Promtail DaemonSet
- RBAC configurations
- ConfigMaps

---

## 🔐 Security

### Change Admin Password

```bash
argocd account update-password
```

### Create Additional Users

Edit `argocd-cm` ConfigMap:

```yaml
data:
  accounts.alice: apiKey, login
  accounts.bob: apiKey, login
```

Set passwords:
```bash
argocd account update-password --account alice
```

### RBAC Policies

Edit `argocd-rbac-cm` ConfigMap:

```yaml
data:
  policy.default: role:readonly
  policy.csv: |
    p, role:dev, applications, *, */dev/*, allow
    p, role:prod, applications, *, */production/*, allow
    g, alice, role:dev
    g, bob, role:prod
```

---

## 📈 Monitoring ArgoCD

### Metrics

ArgoCD exposes Prometheus metrics:

```yaml
# In Prometheus scrape config
- job_name: 'argocd'
  static_configs:
    - targets:
      - 'argocd-metrics.argocd:8082'
      - 'argocd-server-metrics.argocd:8083'
      - 'argocd-repo-server.argocd:8084'
```

### Grafana Dashboard

Import dashboard ID: **14584** (ArgoCD Overview)

---

## 🔔 Notifications (Optional)

### Slack Integration

Create secret:
```bash
kubectl create secret generic argocd-notifications-secret \
  --from-literal=slack-token=YOUR_SLACK_TOKEN \
  -n argocd
```

Configure notifications:
```yaml
# In argocd-notifications-cm
data:
  service.slack: |
    token: $slack-token
  
  template.app-deployed: |
    message: Application {{.app.metadata.name}} deployed!
  
  trigger.on-deployed: |
    - when: app.status.operationState.phase in ['Succeeded']
      send: [app-deployed]
```

Add to application:
```yaml
metadata:
  annotations:
    notifications.argoproj.io/subscribe.on-deployed.slack: my-channel
```

---

## 🔍 Troubleshooting

### Applications Not Syncing

```bash
# Check ArgoCD logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server

# Check application status
argocd app get backend

# Force sync
argocd app sync backend --force

# Refresh repository cache
argocd app get backend --refresh
```

### Git Repository Connection Issues

```bash
# Test repository connection
argocd repo add https://github.com/YOUR_USERNAME/devops.git

# List repositories
argocd repo list

# Test application manifest
argocd app create test-app \
  --repo https://github.com/YOUR_USERNAME/devops.git \
  --path k8s-practise/k8s/2-apps/backend \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace production \
  --dry-run
```

### Certificate Issues

```bash
# Skip TLS verification (development only)
argocd login localhost:8081 --insecure

# Or add certificate
argocd cert add-tls example.com --from /path/to/cert.pem
```

---

## 📚 Best Practices

### 1. Use Separate Git Repositories

```
app-source/        # Application code
k8s-manifests/     # Kubernetes manifests
```

### 2. Use Environment Branches

```
main       -> production
staging    -> staging
develop    -> development
```

### 3. Use Kustomize or Helm

```
k8s/
├── base/
└── overlays/
    ├── dev/
    ├── staging/
    └── production/
```

### 4. Tag Images Properly

```yaml
# ❌ Bad
image: backend:latest

# ✅ Good
image: backend:v2.0.1
image: backend:sha-abc123
```

### 5. Enable Notifications

Get alerts on:
- Deployment success/failure
- Sync errors
- Health degradation

---

## ✅ Quick Commands

```bash
# Install ArgoCD
kubectl apply -f k8s/1-platform/argocd/namespace.yaml
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Get password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward
kubectl port-forward svc/argocd-server -n argocd 8081:443 &

# Deploy all apps
kubectl apply -f k8s/1-platform/argocd/applications/app-of-apps.yaml

# CLI login
argocd login localhost:8081 --username admin --insecure

# List apps
argocd app list

# Sync app
argocd app sync backend

# View logs
argocd app logs backend -f
```

---

## 🎯 Next Steps

1. ✅ Install ArgoCD
2. ✅ Access UI and change password
3. 📝 Update Git repository URLs in application files
4. 🚀 Deploy applications using app-of-apps pattern
5. 🔄 Push changes to Git and watch ArgoCD sync
6. 📊 Monitor applications in ArgoCD UI
7. 🔔 Set up notifications (optional)
8. 🌐 Configure public access via ingress (optional)

**Your GitOps journey starts now!** 🎉

