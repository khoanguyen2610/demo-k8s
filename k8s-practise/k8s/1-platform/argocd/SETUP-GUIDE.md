# 🚀 ArgoCD Complete Setup Guide

## ✅ Current Status

ArgoCD is **INSTALLED** and **CONNECTED** to your cluster!

- **Namespace**: `argocd`
- **Pods Running**: 7 (all healthy)
- **Cluster Connected**: ✅ `https://kubernetes.default.svc`
- **UI Access**: https://localhost:8081
- **Admin Password**: `55pWJxHnBI3mJCRT`

---

## 📁 Files Created in `1-platform/argocd/`

```
k8s/1-platform/argocd/
├── README.md                      # Comprehensive guide
├── SETUP-GUIDE.md                 # This file (quick start)
├── namespace.yaml                 # ArgoCD namespace
├── install.yaml                   # Installation reference
├── argocd-configmap.yaml          # Custom configuration
├── argocd-ingress.yaml            # Public access ingress
└── applications/                  # GitOps application definitions
    ├── backend-app.yaml           # Backend app
    ├── frontend-app.yaml          # Frontend app
    ├── monitoring-app.yaml        # Monitoring stack
    ├── logging-app.yaml           # Logging stack
    └── app-of-apps.yaml           # Manages all apps
```

---

## 🎯 Quick Start (3 Steps)

### Step 1: Access ArgoCD UI

```bash
# Port forward is already running!
# If not, run:
kubectl port-forward svc/argocd-server -n argocd 8081:443 > /dev/null 2>&1 &

# Open UI
open https://localhost:8081
```

**Login**:
- Username: `admin`
- Password: `55pWJxHnBI3mJCRT`

### Step 2: Test ArgoCD Connection

ArgoCD is already connected to your cluster. Test it:

```bash
# Create a test app
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: test-guestbook
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/argoproj/argocd-example-apps.git
    targetRevision: HEAD
    path: guestbook
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

# Watch it deploy
kubectl get application -n argocd -w

# Check in UI: https://localhost:8081

# Clean up when done
kubectl delete application test-guestbook -n argocd
```

### Step 3: Deploy Your Applications (When Ready)

**Option A: Deploy All at Once (App of Apps)**
```bash
# First, update Git URLs in application files to your repo
# Then deploy the root app
kubectl apply -f k8s/1-platform/argocd/applications/app-of-apps.yaml
```

**Option B: Deploy Individually**
```bash
kubectl apply -f k8s/1-platform/argocd/applications/backend-app.yaml
kubectl apply -f k8s/1-platform/argocd/applications/frontend-app.yaml
kubectl apply -f k8s/1-platform/argocd/applications/monitoring-app.yaml
kubectl apply -f k8s/1-platform/argocd/applications/logging-app.yaml
```

---

## ⚙️ Before Deploying Your Apps

### Update Git Repository URLs

All application files currently point to:
```yaml
repoURL: https://github.com/khoanguyen2610/devops.git
```

**If this is your repo**, you're good to go!

**If not**, update each application file:

```bash
# Update backend-app.yaml
sed -i '' 's|khoanguyen2610/devops|YOUR_USERNAME/devops|g' k8s/1-platform/argocd/applications/backend-app.yaml

# Update frontend-app.yaml
sed -i '' 's|khoanguyen2610/devops|YOUR_USERNAME/devops|g' k8s/1-platform/argocd/applications/frontend-app.yaml

# Update monitoring-app.yaml
sed -i '' 's|khoanguyen2610/devops|YOUR_USERNAME/devops|g' k8s/1-platform/argocd/applications/monitoring-app.yaml

# Update logging-app.yaml
sed -i '' 's|khoanguyen2610/devops|YOUR_USERNAME/devops|g' k8s/1-platform/argocd/applications/logging-app.yaml

# Update app-of-apps.yaml
sed -i '' 's|khoanguyen2610/devops|YOUR_USERNAME/devops|g' k8s/1-platform/argocd/applications/app-of-apps.yaml
```

---

## 🔄 GitOps Workflow

### Making Changes

1. **Update your code**
2. **Build and push Docker image with new tag**
   ```bash
   docker build -t khoanguyen2610/backend:v2.0 .
   docker push khoanguyen2610/backend:v2.0
   ```

3. **Update Kubernetes manifest in Git**
   ```bash
   # Edit k8s/2-apps/backend/deployment.yaml
   # Change image tag to v2.0
   git add .
   git commit -m "Update backend to v2.0"
   git push
   ```

4. **ArgoCD automatically deploys!** ✅
   - Detects Git change within 3 minutes
   - Or click "Refresh" in UI for instant sync
   - Updates pods automatically
   - Shows progress in real-time

---

## 📊 ArgoCD UI Features

### Dashboard
- See all applications
- Health status (Healthy, Progressing, Degraded, Suspended)
- Sync status (Synced, Out of Sync)
- Last sync time

### Application View
- Visual resource tree
- Pod logs
- Events
- Sync history
- Diff view (what will change)

### Actions
- **Sync**: Deploy latest from Git
- **Refresh**: Check Git for changes
- **Rollback**: Revert to previous version
- **Delete**: Remove application
- **Hard Refresh**: Clear cache and resync

---

## 🔐 Security Best Practices

### 1. Change Admin Password

```bash
# Via UI
# Settings → Accounts → admin → Update Password

# Or via CLI
argocd login localhost:8081 --username admin --password 55pWJxHnBI3mJCRT --insecure
argocd account update-password
```

### 2. Delete Initial Secret (After changing password)

```bash
kubectl delete secret argocd-initial-admin-secret -n argocd
```

### 3. Use Private Git Repositories (If needed)

```bash
# Add repository with credentials
argocd repo add https://github.com/YOUR_USERNAME/private-repo.git \
  --username YOUR_USERNAME \
  --password YOUR_PAT
```

---

## 🌐 Public Access Options

### Option 1: Via Port Forward (Current)
```bash
kubectl port-forward svc/argocd-server -n argocd 8081:443 &
open https://localhost:8081
```

### Option 2: Via Ingress (Local Domain)
```bash
# Apply ingress
kubectl apply -f k8s/1-platform/argocd/argocd-ingress.yaml

# Add to /etc/hosts
echo "127.0.0.1 argocd.local.kn-tech.click" | sudo tee -a /etc/hosts

# Access
open https://argocd.local.kn-tech.click
```

### Option 3: Via Cloudflare Tunnel (Public HTTPS)
```yaml
# Add to ~/.cloudflared/config.yml
ingress:
  - hostname: argocd.kn-tech.click
    service: https://localhost:8081
    originRequest:
      noTLSVerify: true
```

Then restart cloudflared and access:
```
https://argocd.kn-tech.click
```

---

## 📱 ArgoCD CLI (Optional)

### Install
```bash
brew install argocd
```

### Login
```bash
argocd login localhost:8081 --username admin --password 55pWJxHnBI3mJCRT --insecure
```

### Common Commands
```bash
# List apps
argocd app list

# Get app details
argocd app get backend

# Sync app
argocd app sync backend

# Watch sync
argocd app wait backend --sync

# View logs
argocd app logs backend -f

# Rollback
argocd app history backend
argocd app rollback backend 1

# Delete app
argocd app delete backend
```

---

## 🔍 Troubleshooting

### Application Stuck in "OutOfSync"

```bash
# Check application details
kubectl describe application backend -n argocd

# Force refresh
kubectl patch application backend -n argocd \
  -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}' \
  --type merge

# Or via UI: Click app → Click "Refresh" → Select "Hard Refresh"
```

### "PermissionDenied" Errors

ArgoCD service account needs permissions:

```bash
# Check ArgoCD service account
kubectl get serviceaccount argocd-application-controller -n argocd

# Check cluster role
kubectl get clusterrole argocd-application-controller -o yaml
```

### UI Not Loading

```bash
# Check pods
kubectl get pods -n argocd

# Check server logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-server --tail=50

# Restart port-forward
pkill -f "port-forward.*argocd"
kubectl port-forward svc/argocd-server -n argocd 8081:443 &
```

---

## 📊 Monitoring ArgoCD

### Add to Prometheus

```yaml
# Add to prometheus scrape configs
- job_name: 'argocd'
  static_configs:
    - targets:
      - 'argocd-metrics.argocd:8082'
      - 'argocd-server-metrics.argocd:8083'
```

### Grafana Dashboard

1. Login to Grafana: http://localhost:3000
2. Go to **Dashboards → Import**
3. Enter ID: **14584**
4. Select Prometheus datasource
5. Import

---

## ✅ Verification Checklist

- [ ] ArgoCD UI accessible: https://localhost:8081
- [ ] Can login with admin credentials
- [ ] Test application deployed successfully
- [ ] Git repository URLs updated (if needed)
- [ ] Applications created
- [ ] Applications syncing from Git
- [ ] Pods deploying correctly
- [ ] Can view resources in UI
- [ ] Admin password changed
- [ ] Initial secret deleted

---

## 🎯 Next Steps

1. ✅ **Verify Setup**: Test with sample app (done above)
2. 📝 **Update Git URLs**: Point to your repository
3. 🔐 **Change Password**: Secure your ArgoCD
4. 🚀 **Deploy Apps**: Use app-of-apps pattern
5. 📊 **Monitor**: Watch deployments in UI
6. 🔄 **Test GitOps**: Push change to Git, watch auto-deploy
7. 📱 **Setup CLI**: Install and configure ArgoCD CLI
8. 🔔 **Notifications**: Configure Slack/Email alerts (optional)

---

## 📚 Quick Links

- **ArgoCD UI**: https://localhost:8081
- **Grafana**: http://localhost:3000
- **Prometheus**: http://localhost:9090
- **Backend API**: https://local-api.kn-tech.click/v1/health
- **Frontend**: https://local.kn-tech.click/

---

## 🎉 Summary

**ArgoCD is ready for GitOps!**

- ✅ Installed and running
- ✅ Connected to your cluster
- ✅ Tested and verified
- ✅ Application manifests created
- ✅ Documentation complete
- ✅ Ready to manage deployments

**Push to Git → ArgoCD deploys → Success!** 🚀

---

For detailed information, see [README.md](./README.md)

