# 🔄 Sync Current Cluster to ArgoCD

## ✅ Current Status

Your applications are registered in ArgoCD:
- **backend** ✅ Healthy (managing existing deployment)
- **frontend** ✅ Healthy (managing existing deployment)
- **monitoring** ✅ Healthy (managing existing stack)
- **logging** ✅ Healthy (managing existing stack)

**Issue**: ArgoCD can't sync from Git repository yet.

**Message**: `Repository not found` - The Git repository doesn't exist or needs authentication.

---

## 🎯 Solution 1: Push to Git (Recommended)

### Step 1: Check Git Repository

```bash
cd /Users/khoa.nguyen/Workings/Personal/devops

# Check if git is initialized
git status

# Check remote
git remote -v
```

### Step 2: Create/Update Git Repository

If repository doesn't exist:
```bash
# On GitHub:
# 1. Go to https://github.com/new
# 2. Create repository named: devops
# 3. Make it Public (or Private with token)

# Then push:
git add k8s-practise/
git commit -m "Add Kubernetes manifests for ArgoCD"
git push origin main
```

If repository exists but files not pushed:
```bash
git add k8s-practise/
git commit -m "Add Kubernetes manifests for ArgoCD"
git push origin main
```

### Step 3: Update Repository URLs (if needed)

If your GitHub username is different:
```bash
# Update all application files
cd k8s-practise/k8s/1-platform/argocd/applications

# Replace with your GitHub username
for file in *.yaml; do
    sed -i '' 's|khoanguyen2610/devops|YOUR_USERNAME/devops|g' "$file"
done

# Reapply applications
kubectl apply -f .
```

### Step 4: Wait for ArgoCD to Sync

```bash
# Watch applications sync
watch kubectl get application -n argocd

# Or check in UI
open https://localhost:8081
```

Within 3 minutes, ArgoCD will:
- Detect Git repository
- Compare with cluster resources
- Show sync status (Synced/OutOfSync)
- Adopt existing resources

---

## 🎯 Solution 2: Use Local Path (Development Only)

For local testing without Git:

### Update Applications to Use Local Path

```yaml
# Edit each application file
spec:
  source:
    # Remove repoURL and targetRevision
    # Use local path instead:
    path: /Users/khoa.nguyen/Workings/Personal/devops/k8s-practise/k8s/2-apps/backend
```

**Note**: This approach doesn't work for true GitOps workflow.

---

## 🎯 Solution 3: Configure Private Repository

If your repository is private:

### Add Repository Credentials

```bash
# Option A: Via UI
# 1. Open https://localhost:8081
# 2. Settings → Repositories → Connect Repo
# 3. Enter: https://github.com/YOUR_USERNAME/devops.git
# 4. Add credentials (token or SSH key)

# Option B: Via CLI
argocd repo add https://github.com/YOUR_USERNAME/devops.git \
  --username YOUR_USERNAME \
  --password YOUR_GITHUB_TOKEN

# Option C: Via kubectl
kubectl create secret generic github-creds \
  --from-literal=username=YOUR_USERNAME \
  --from-literal=password=YOUR_GITHUB_TOKEN \
  -n argocd

kubectl label secret github-creds \
  -n argocd \
  argocd.argoproj.io/secret-type=repository
```

---

## 🔍 Check Current Status

### View Application Details

```bash
# Get application status
kubectl get application backend -n argocd -o yaml

# Check sync status
kubectl describe application backend -n argocd

# View in UI (visual tree)
open https://localhost:8081
```

### What ArgoCD Currently Sees

Even without Git sync, ArgoCD is **already managing** your resources:

```bash
# ArgoCD can see these resources:
kubectl get deployment backend -n production -o yaml | grep -A 3 "metadata:"
# Shows: app.kubernetes.io/instance: backend (ArgoCD label)
```

---

## 🚀 Manual Sync (Temporary)

If you want to force ArgoCD to adopt existing resources now:

### Via UI

1. Open https://localhost:8081
2. Click on application (e.g., backend)
3. Click **"SYNC"**
4. Select **"SYNCHRONIZE"**

### Via CLI

```bash
# Install ArgoCD CLI
brew install argocd

# Login
argocd login localhost:8081 --username admin --password 55pWJxHnBI3mJCRT --insecure

# Force sync (will work even without Git access)
argocd app sync backend --force
argocd app sync frontend --force
argocd app sync monitoring --force
argocd app sync logging --force
```

---

## 📊 Verification

### Check if ArgoCD is Managing Resources

```bash
# List applications
kubectl get application -n argocd

# Check if resources have ArgoCD labels
kubectl get deployment backend -n production -o yaml | grep argocd

# View application tree in UI
open https://localhost:8081
```

### Expected Labels on Managed Resources

ArgoCD adds these labels:
```yaml
metadata:
  labels:
    app.kubernetes.io/instance: backend
  annotations:
    argocd.argoproj.io/tracking-id: backend:apps/Deployment:production/backend
```

---

## 🔄 GitOps Workflow (After Git Setup)

Once Git is configured:

1. **Make changes** to manifests locally
2. **Commit and push** to Git
   ```bash
   git add k8s-practise/
   git commit -m "Update backend image to v2.0"
   git push origin main
   ```
3. **ArgoCD auto-syncs** within 3 minutes
   - Or click "Refresh" in UI for instant sync
4. **Watch deployment** in ArgoCD UI
5. **Rollback** if needed (just revert Git commit)

---

## 🎯 Recommended Next Steps

### Immediate (to fix sync status):

1. ✅ **Push manifests to Git**
   ```bash
   cd /Users/khoa.nguyen/Workings/Personal/devops
   git add k8s-practise/
   git commit -m "Add Kubernetes manifests"
   git push origin main
   ```

2. ✅ **Wait 3 minutes** or refresh in UI
   - ArgoCD will detect repository
   - Sync status will change to "Synced"
   - Resources will be fully managed

3. ✅ **Verify in UI**
   - Open https://localhost:8081
   - All apps should show "Synced" status
   - Click on app to see resource tree

### For Private Repository:

4. **Add credentials** (if repository is private)
   ```bash
   argocd repo add https://github.com/YOUR_USERNAME/devops.git \
     --username YOUR_USERNAME \
     --password YOUR_GITHUB_TOKEN
   ```

---

## ✅ Success Indicators

You'll know it's working when:

```bash
# All applications show "Synced"
kubectl get application -n argocd

NAME         SYNC STATUS   HEALTH STATUS
backend      Synced        Healthy
frontend     Synced        Healthy
logging      Synced        Healthy
monitoring   Synced        Healthy
```

**In ArgoCD UI**:
- Green checkmark (✅) = Synced
- Green heart (💚) = Healthy
- Resource tree visible
- Git commit hash shown
- Last sync time visible

---

## 🔧 Troubleshooting

### "Repository not found"

```bash
# Check if repository exists
curl -I https://github.com/YOUR_USERNAME/devops

# Check if files are in repository
curl https://raw.githubusercontent.com/YOUR_USERNAME/devops/main/k8s-practise/k8s/2-apps/backend/deployment.yaml

# If 404: Push files to Git
# If private: Add credentials to ArgoCD
```

### "OutOfSync" Status

This is normal if:
- Manifests in Git differ from cluster
- Manual changes were made to resources

To sync:
```bash
# Via UI: Click app → Click "SYNC"
# Via CLI: argocd app sync backend
```

### Applications Not Adopting Resources

```bash
# Check resource labels
kubectl get deployment backend -n production -o yaml | grep -A 5 "labels:"

# Manually add labels if needed
kubectl label deployment backend -n production \
  app.kubernetes.io/instance=backend \
  app.kubernetes.io/name=backend
```

---

## 📚 What's Happening Now

### Current State:

✅ **ArgoCD Applications Created** - 4 applications registered  
✅ **Resources Healthy** - ArgoCD sees all pods/deployments  
⚠️ **Sync Status Unknown** - Git repository not accessible  
✅ **Resources Running** - All deployments still working fine  

### After Git Push:

✅ **Sync Status: Synced** - ArgoCD compares Git vs Cluster  
✅ **Full GitOps** - Auto-sync enabled  
✅ **Audit Trail** - All changes tracked in Git  
✅ **Easy Rollback** - Revert Git commits  

---

## 🎉 Summary

Your cluster is **already managed by ArgoCD**! The resources are healthy and ArgoCD is tracking them. You just need to:

1. **Push manifests to Git** (one-time)
2. **Wait for sync** (3 minutes or click refresh)
3. **Enjoy GitOps!** (push changes to Git, ArgoCD deploys)

**Current Access**:
- ArgoCD UI: https://localhost:8081
- Username: `admin`
- Password: `55pWJxHnBI3mJCRT`

**Your GitOps journey is 90% complete! Just need Git access configured.** 🚀

