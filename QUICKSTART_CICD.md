# Quick Start Guide - GitHub Actions CI/CD

Get your CI/CD pipeline up and running in minutes!

## 🚀 Quick Setup (5 minutes)

### Step 1: Prerequisites

Ensure you have:
- [ ] GitHub repository with admin access
- [ ] Kubernetes cluster running
- [ ] `kubectl` configured locally
- [ ] GitHub CLI installed (`gh`)

```bash
# Install GitHub CLI if needed
brew install gh  # macOS
# or follow: https://cli.github.com/

# Authenticate
gh auth login
```

### Step 2: Run Setup Script

We've automated most of the setup for you!

```bash
# Run the automated setup script
./scripts/setup-github-secrets.sh
```

This script will:
- ✅ Upload your kubeconfig to GitHub secrets
- ✅ Configure optional secrets (API URLs, Docker Hub)
- ✅ Update deployment files with correct image paths
- ✅ Verify all secrets are properly configured

### Step 3: Enable GitHub Container Registry

1. Go to repository `Settings > Actions > General`
2. Under "Workflow permissions":
   - ✅ Select "Read and write permissions"
   - ✅ Check "Allow GitHub Actions to create and approve pull requests"
3. Click "Save"

### Step 4: Update Repository URLs

Replace `YOUR_GITHUB_USERNAME` in these files with your actual GitHub username:

```bash
# Quick find and replace (run from repo root)
find k8s/personal -name "*deployment.yaml" -exec sed -i '' 's/YOUR_GITHUB_USERNAME/your-actual-username/g' {} \;

# Or update manually:
# - k8s/personal/backend-deployment.yaml
# - k8s/personal/frontend-deployment.yaml
```

### Step 5: Commit and Push

```bash
git add .
git commit -m "feat: setup GitHub Actions CI/CD pipeline"
git push origin main
```

### Step 6: Watch the Magic! ✨

Go to `Actions` tab in GitHub and watch your pipelines run!

```bash
# Or watch from CLI
gh run watch
```

---

## 📋 Manual Setup (Alternative)

If you prefer manual setup or the script doesn't work:

### 1. Create KUBECONFIG Secret

```bash
# Encode your kubeconfig
cat ~/.kube/config | base64 | pbcopy  # macOS
cat ~/.kube/config | base64 -w 0      # Linux

# Add to GitHub
gh secret set KUBECONFIG
# Paste the base64 encoded content when prompted
```

### 2. (Optional) Add API URL Secret

```bash
gh secret set REACT_APP_API_URL
# Enter: http://backend-api-service.backend.svc.cluster.local:8080
```

### 3. Update Deployment Files

Edit `k8s/personal/backend-deployment.yaml`:
```yaml
image: ghcr.io/your-username/devops/backend:latest
```

Edit `k8s/personal/frontend-deployment.yaml`:
```yaml
image: ghcr.io/your-username/devops/frontend:latest
```

### 4. Verify Secrets

```bash
gh secret list
```

Expected output:
```
KUBECONFIG              Updated YYYY-MM-DD
REACT_APP_API_URL       Updated YYYY-MM-DD (optional)
```

---

## 🧪 Testing the Pipeline

### Test Backend Pipeline

```bash
# Make a small change
echo "// Test change" >> backend/main.go

# Commit and push
git add backend/main.go
git commit -m "test: trigger backend pipeline"
git push origin main

# Watch the workflow
gh run watch
```

### Test Frontend Pipeline

```bash
# Make a small change
echo "/* Test change */" >> frontend/src/App.js

# Commit and push
git add frontend/src/App.js
git commit -m "test: trigger frontend pipeline"
git push origin main

# Watch the workflow
gh run watch
```

### Test Full Stack Deployment

```bash
# Trigger manual deployment
gh workflow run deploy-stack.yml \
  --field environment=production \
  --field backend_image_tag=latest \
  --field frontend_image_tag=latest

# Watch the workflow
gh run watch
```

---

## 🔍 Verify Deployment

After the pipeline completes, verify everything is running:

```bash
# Check deployments
kubectl get deployments -n backend
kubectl get deployments -n frontend

# Check pods
kubectl get pods -n backend
kubectl get pods -n frontend

# Check services
kubectl get svc -n backend
kubectl get svc -n frontend

# Test backend
kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never -- \
  curl http://backend-api-service.backend.svc.cluster.local:8080/api/v1/health

# Test frontend
kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never -- \
  curl http://frontend-app-service.frontend.svc.cluster.local:80
```

Or use our verification script:

```bash
./scripts/verify-deployment.sh
```

---

## 📊 Add Status Badges

Add these to your README.md to show pipeline status:

```markdown
![Backend CI/CD](https://github.com/YOUR_USERNAME/devops/actions/workflows/backend-cicd.yml/badge.svg)
![Frontend CI/CD](https://github.com/YOUR_USERNAME/devops/actions/workflows/frontend-cicd.yml/badge.svg)
```

Replace `YOUR_USERNAME` with your GitHub username.

---

## 🛠️ Common Commands

### View Workflows

```bash
# List all workflows
gh workflow list

# View recent runs
gh run list

# View specific run
gh run view <run-id>

# Watch current run
gh run watch
```

### Manage Secrets

```bash
# List secrets
gh secret list

# Add/update secret
gh secret set SECRET_NAME

# Delete secret
gh secret delete SECRET_NAME
```

### Deploy Specific Version

```bash
# Deploy specific image tag
gh workflow run deploy-stack.yml \
  --field environment=production \
  --field backend_image_tag=main-abc123 \
  --field frontend_image_tag=main-def456
```

### View Logs

```bash
# View workflow logs
gh run view <run-id> --log

# View specific job logs
gh run view <run-id> --log --job=<job-id>
```

---

## 🐛 Troubleshooting

### Pipeline fails with "KUBECONFIG not found"

```bash
# Re-encode and upload kubeconfig
cat ~/.kube/config | base64 | gh secret set KUBECONFIG
```

### Docker image push fails

1. Check workflow permissions (Step 3 above)
2. Ensure GitHub token has package write access
3. Verify repository is not private or enable private package access

### Deployment timeout

```bash
# Check pod status
kubectl describe pod -n backend <pod-name>

# Check events
kubectl get events -n backend --sort-by='.lastTimestamp'

# Check logs
kubectl logs -n backend deployment/backend-api
```

### Tests fail in CI but pass locally

- Verify Go/Node versions match CI environment
- Check for missing dependencies
- Ensure no hardcoded local paths

---

## 📚 Next Steps

- [ ] Set up [GitHub Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
- [ ] Configure [branch protection rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [ ] Add [Slack notifications](.github/CICD_SETUP.md#set-up-slack-notifications-optional)
- [ ] Set up [monitoring and alerts](.github/CICD_SETUP.md#monitoring-and-alerts)
- [ ] Configure [auto-merge for dependabot](https://docs.github.com/en/code-security/dependabot/working-with-dependabot/automating-dependabot-with-github-actions)

---

## 📖 Documentation

For detailed documentation, see:
- [Complete CI/CD Setup Guide](.github/CICD_SETUP.md)
- [PR Template](.github/pull_request_template.md)
- [Backend README](backend/README.md)
- [Frontend README](frontend/README.md)
- [Kubernetes Setup](k8s/personal/README.md)

---

## 🆘 Need Help?

1. Check [CI/CD Setup Guide](.github/CICD_SETUP.md) for detailed docs
2. Review [workflow logs](https://github.com/YOUR_USERNAME/devops/actions)
3. Check [troubleshooting section](.github/CICD_SETUP.md#troubleshooting)
4. Open an issue in the repository

---

**Happy Deploying! 🚀**

