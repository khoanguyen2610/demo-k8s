# 🚀 ArgoCD - GitOps Continuous Delivery

## ✅ ArgoCD Deployed Successfully!

ArgoCD is a declarative, GitOps continuous delivery tool for Kubernetes.

---

## 🌐 Quick Access

**ArgoCD UI**: https://localhost:8081

**Login Credentials**:
- Username: `admin`
- Password: `55pWJxHnBI3mJCRT`

```bash
# Open ArgoCD UI
open https://localhost:8081

# Accept the self-signed certificate warning
```

---

## 🎯 What is ArgoCD?

ArgoCD is a GitOps tool that:
- ✅ Automatically syncs Kubernetes manifests from Git
- ✅ Provides visual dashboard for deployments
- ✅ Enables easy rollbacks
- ✅ Tracks application health and sync status
- ✅ Supports multiple clusters
- ✅ Integrates with CI/CD pipelines

### GitOps Benefits
- **Git as single source of truth**
- **Automated deployments**
- **Easy rollbacks** (just revert Git commit)
- **Audit trail** (Git history)
- **Declarative configuration**

---

## 📊 Current Setup

### ArgoCD Components (7 pods running)
```
✅ argocd-server                  - Web UI & API
✅ argocd-repo-server             - Git repository interface
✅ argocd-application-controller  - Application monitoring
✅ argocd-dex-server              - Authentication (SSO)
✅ argocd-redis                   - Cache
✅ argocd-applicationset-controller - Application set management
✅ argocd-notifications-controller - Notifications
```

---

## 🚀 Getting Started

### Step 1: Access ArgoCD UI
```bash
# Already port-forwarded!
open https://localhost:8081
```

### Step 2: Login
1. Accept self-signed certificate
2. Username: `admin`
3. Password: `55pWJxHnBI3mJCRT`

### Step 3: Change Password (Recommended)
```bash
# Install ArgoCD CLI (optional)
brew install argocd

# Login via CLI
argocd login localhost:8081 --username admin --password 55pWJxHnBI3mJCRT --insecure

# Change password
argocd account update-password
```

---

## 📦 Create Your First Application

### Option 1: Via UI

1. Click **"+ NEW APP"**
2. Fill in:
   - **Application Name**: `backend`
   - **Project**: `default`
   - **Sync Policy**: `Automatic`
   - **Source**:
     - Repository URL: `https://github.com/YOUR_USERNAME/devops.git`
     - Revision: `HEAD`
     - Path: `k8s-practise/k8s/2-apps/backend`
   - **Destination**:
     - Cluster URL: `https://kubernetes.default.svc`
     - Namespace: `production`
3. Click **"CREATE"**

### Option 2: Via YAML

Create `argocd-apps/backend-app.yaml`:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: backend
  namespace: argocd
spec:
  project: default
  
  source:
    repoURL: https://github.com/YOUR_USERNAME/devops.git
    targetRevision: HEAD
    path: k8s-practise/k8s/2-apps/backend
  
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

Apply:
```bash
kubectl apply -f argocd-apps/backend-app.yaml
```

---

## 🔧 Managing Applications

### View Applications
```bash
# Via CLI
argocd app list

# Via UI
open https://localhost:8081
```

### Sync Application (Deploy)
```bash
# Via CLI
argocd app sync backend

# Via UI
Click on app → Click "SYNC"
```

### Check Application Status
```bash
argocd app get backend
```

### Rollback
```bash
# Get history
argocd app history backend

# Rollback to revision
argocd app rollback backend 1
```

### Delete Application
```bash
argocd app delete backend
```

---

## 🎨 ArgoCD UI Features

### Dashboard View
- See all applications at a glance
- Health status (Healthy, Progressing, Degraded)
- Sync status (Synced, Out of Sync)
- Last sync time

### Application Details
- Resource tree view
- Logs for each pod
- Events
- Sync history
- Parameters

### Sync Options
- **Auto-sync**: Automatically deploy on Git changes
- **Self-heal**: Auto-fix manual changes
- **Prune**: Delete resources not in Git

---

## 📚 Example: Full Application Setup

### 1. Create Git Repository
```bash
# Push your k8s manifests to GitHub
cd /Users/khoa.nguyen/Workings/Personal/devops
git add k8s-practise/
git commit -m "Add Kubernetes manifests"
git push origin main
```

### 2. Create ArgoCD Applications

#### Backend Application
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: backend
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/khoanguyen/devops.git
    targetRevision: HEAD
    path: k8s-practise/k8s/2-apps/backend
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
      - Validate=true
      - CreateNamespace=true
      - PrunePropagationPolicy=foreground
      - PruneLast=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
```

#### Frontend Application
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: frontend
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/khoanguyen/devops.git
    targetRevision: HEAD
    path: k8s-practise/k8s/2-apps/frontend
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

#### Monitoring Stack
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: monitoring
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/khoanguyen/devops.git
    targetRevision: HEAD
    path: k8s-practise/k8s/1-platform/monitoring
  destination:
    server: https://kubernetes.default.svc
    namespace: monitoring
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### 3. Apply Applications
```bash
kubectl apply -f argocd-apps/
```

---

## 🔄 GitOps Workflow

### Traditional Workflow
```
Code → Build → Push Image → kubectl apply
```

### GitOps Workflow with ArgoCD
```
Code → Build → Push Image → Update Git → ArgoCD Auto-deploys
```

### Example: Update Backend

1. **Make code changes**
```bash
cd k8s-001/backend
# Edit code
```

2. **Build and push new image**
```bash
docker build --target api -t khoanguyen2610/backend:v2.0 .
docker push khoanguyen2610/backend:v2.0
```

3. **Update Git manifest**
```bash
cd k8s-practise/k8s/2-apps/backend
# Edit deployment.yaml - change image tag to v2.0
git add .
git commit -m "Update backend to v2.0"
git push
```

4. **ArgoCD auto-deploys!** ✅
- ArgoCD detects Git change
- Syncs automatically
- Updates pods
- Shows status in UI

---

## 🎯 Best Practices

### 1. Use Separate Git Repos
```
app-code/          # Application source code
└── backend/

app-manifests/     # Kubernetes manifests
└── k8s/
    └── backend/
```

### 2. Use Helm or Kustomize
```
k8s/
├── base/          # Base manifests
└── overlays/
    ├── dev/
    ├── staging/
    └── production/
```

### 3. Use Image Tags (not latest)
```yaml
# ❌ Bad
image: khoanguyen2610/backend:latest

# ✅ Good
image: khoanguyen2610/backend:v2.0.1
```

### 4. Enable Auto-sync with Care
```yaml
syncPolicy:
  automated:
    prune: true      # Delete resources not in Git
    selfHeal: true   # Revert manual changes
```

### 5. Use Projects for Isolation
```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: production
spec:
  destinations:
    - namespace: 'production'
      server: https://kubernetes.default.svc
  sourceRepos:
    - 'https://github.com/khoanguyen/*'
```

---

## 🔐 Security

### Change Default Password
```bash
argocd account update-password
```

### Enable SSO (Optional)
Configure OIDC, SAML, or GitHub OAuth in ConfigMap:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argocd
data:
  dex.config: |
    connectors:
      - type: github
        id: github
        name: GitHub
        config:
          clientID: $GITHUB_CLIENT_ID
          clientSecret: $GITHUB_CLIENT_SECRET
```

### RBAC Policies
```yaml
# argocd-rbac-cm ConfigMap
policy.default: role:readonly
policy.csv: |
  p, role:dev, applications, *, */dev/*, allow
  p, role:prod, applications, *, */production/*, allow
  g, dev-team, role:dev
  g, ops-team, role:prod
```

---

## 📱 ArgoCD CLI

### Install
```bash
brew install argocd
```

### Common Commands
```bash
# Login
argocd login localhost:8081

# List apps
argocd app list

# Get app details
argocd app get backend

# Sync app
argocd app sync backend

# Watch sync status
argocd app wait backend --sync

# Get app history
argocd app history backend

# Rollback
argocd app rollback backend 1

# Delete app
argocd app delete backend

# Set parameter
argocd app set backend --parameter replicas=3
```

---

## 🔔 Notifications

### Configure Slack Notifications
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-notifications-cm
  namespace: argocd
data:
  service.slack: |
    token: $slack-token
  
  template.app-deployed: |
    message: |
      Application {{.app.metadata.name}} is now running new version.
  
  trigger.on-deployed: |
    - when: app.status.operationState.phase in ['Succeeded']
      send: [app-deployed]
```

### Add to Application
```yaml
metadata:
  annotations:
    notifications.argoproj.io/subscribe.on-deployed.slack: my-channel
```

---

## 🌍 Expose ArgoCD Publicly

### Option 1: Via Ingress
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: argocd
  annotations:
    nginx.ingress.kubernetes.io/ssl-passthrough: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
spec:
  ingressClassName: nginx
  rules:
    - host: argocd.kn-tech.click
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: argocd-server
                port:
                  number: 443
```

### Option 2: Via Cloudflare Tunnel
Add to `~/.cloudflared/config.yml`:
```yaml
ingress:
  - hostname: argocd.kn-tech.click
    service: https://localhost:8081
    originRequest:
      noTLSVerify: true
```

---

## 🔍 Troubleshooting

### ArgoCD UI Not Loading
```bash
# Check pods
kubectl get pods -n argocd

# Check server logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server

# Restart port-forward
pkill -f "port-forward.*argocd"
kubectl port-forward svc/argocd-server -n argocd 8081:443 &
```

### Application Out of Sync
```bash
# Check diff
argocd app diff backend

# Force sync
argocd app sync backend --force

# Refresh cache
argocd app get backend --refresh
```

### Authentication Issues
```bash
# Reset admin password
kubectl -n argocd patch secret argocd-secret \
  -p '{"stringData": {"admin.password": "'$(htpasswd -bnBC 10 "" mypassword | tr -d ':\n')'"}}'

# Restart server
kubectl rollout restart deployment/argocd-server -n argocd
```

---

## 📊 Monitoring ArgoCD

### Metrics
ArgoCD exposes Prometheus metrics:
- `argocd-metrics` service on port 8082
- `argocd-server-metrics` service on port 8083
- `argocd-repo-server` metrics on port 8084

### Add to Prometheus
```yaml
scrape_configs:
  - job_name: 'argocd'
    static_configs:
      - targets: ['argocd-metrics.argocd:8082']
      - targets: ['argocd-server-metrics.argocd:8083']
```

### Grafana Dashboard
Import dashboard ID: **14584** (ArgoCD Overview)

---

## ✅ Status

| Component | Status | URL | Credentials |
|-----------|--------|-----|-------------|
| **ArgoCD UI** | ✅ Running | https://localhost:8081 | admin / 55pWJxHnBI3mJCRT |
| **ArgoCD Server** | ✅ Running | - | - |
| **Repo Server** | ✅ Running | - | - |
| **Application Controller** | ✅ Running | - | - |

**ArgoCD is ready for GitOps!** 🚀

---

## 🎯 Next Steps

1. **✅ Login**: https://localhost:8081 (admin / 55pWJxHnBI3mJCRT)
2. **🔐 Change Password**: Via UI or CLI
3. **📦 Create Applications**: Connect to your Git repo
4. **🔄 Enable Auto-sync**: Let ArgoCD manage deployments
5. **📊 Monitor**: Watch deployments in real-time
6. **🔔 Setup Notifications**: Slack, Email, etc.

---

## 📚 Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [ArgoCD Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)
- [GitOps Principles](https://opengitops.dev/)
- [ArgoCD Examples](https://github.com/argoproj/argocd-example-apps)

**Happy GitOps! 🎉**

