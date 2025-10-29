# 🚀 CI/CD Quick Reference Card

**Quick commands and tips for daily use**

---

## 📋 Common Commands

### Setup & Configuration
```bash
# Initial setup
./scripts/setup-github-secrets.sh

# List secrets
gh secret list

# Add/update secret
gh secret set SECRET_NAME
```

### Testing Before Push
```bash
# Test everything locally
./scripts/local-test.sh

# Test backend only
cd backend && go test ./... && cd ..

# Test frontend only
cd frontend && npm test && cd ..
```

### Workflow Management
```bash
# List workflows
gh workflow list

# View recent runs
gh run list

# Watch current run
gh run watch

# View specific run
gh run view <run-id>

# View logs
gh run view <run-id> --log

# Cancel run
gh run cancel <run-id>

# Re-run failed jobs
gh run rerun <run-id>
```

### Manual Deployments
```bash
# Deploy full stack (latest images)
gh workflow run deploy-stack.yml --field environment=production

# Deploy specific versions
gh workflow run deploy-stack.yml \
  --field environment=production \
  --field backend_image_tag=main-abc123 \
  --field frontend_image_tag=main-def456
```

### Kubernetes Operations
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

# View logs
kubectl logs -n backend deployment/backend-api
kubectl logs -n frontend deployment/frontend-app

# Describe pod
kubectl describe pod -n backend <pod-name>

# Execute into pod
kubectl exec -it -n backend <pod-name> -- /bin/sh

# Port forward
kubectl port-forward -n backend svc/backend-api-service 8080:8080
kubectl port-forward -n frontend svc/frontend-app-service 8080:80
```

### Deployment Verification
```bash
# Run verification script
./scripts/verify-deployment.sh

# Quick health check
kubectl run curl-test --image=curlimages/curl --rm -it --restart=Never -- \
  curl http://backend-api-service.backend.svc.cluster.local:8080/api/v1/health
```

### Rollback
```bash
# Rollback backend
kubectl rollout undo deployment/backend-api -n backend
kubectl rollout status deployment/backend-api -n backend

# Rollback frontend
kubectl rollout undo deployment/frontend-app -n frontend
kubectl rollout status deployment/frontend-app -n frontend

# Rollback to specific revision
kubectl rollout undo deployment/backend-api -n backend --to-revision=2
```

### Image Management
```bash
# Pull images manually
docker pull ghcr.io/username/devops/backend:latest
docker pull ghcr.io/username/devops/frontend:latest

# List container images
gh api /user/packages?package_type=container

# View package versions
gh api /user/packages/container/devops%2Fbackend/versions
```

---

## 🎯 Workflow Triggers

| What You Push | Which Workflow Runs |
|---------------|---------------------|
| Changes in `backend/**` | Backend CI/CD |
| Changes in `frontend/**` | Frontend CI/CD |
| Changes in K8s backend files | Backend CI/CD |
| Changes in K8s frontend files | Frontend CI/CD |
| Pull Request | PR Checks |
| Manual trigger | Deploy Stack |

---

## 📊 Status Checks

### In GitHub UI
- Go to: `https://github.com/username/devops/actions`
- Green ✅ = Success
- Red ❌ = Failed
- Yellow 🟡 = In Progress

### Command Line
```bash
# Current status
gh run list --limit 5

# Watch latest
gh run watch

# Check specific workflow
gh run list --workflow=backend-cicd.yml
```

---

## 🔍 Debugging Failed Workflows

### Step 1: View the failure
```bash
gh run list
gh run view <run-id>
```

### Step 2: Check logs
```bash
gh run view <run-id> --log
gh run view <run-id> --log --job=<job-id>
```

### Step 3: Common fixes

**Tests fail:**
```bash
# Run tests locally first
./scripts/local-test.sh
```

**Build fails:**
```bash
# Check Docker build locally
docker build -t test-backend -f backend/Dockerfile backend
docker build -t test-frontend -f frontend/Dockerfile frontend
```

**Deploy fails:**
```bash
# Check K8s manifests
kubectl apply --dry-run=client -f k8s/personal/
```

**Permission errors:**
- Check repository Settings → Actions → General
- Ensure "Read and write permissions" enabled

### Step 4: Re-run
```bash
# Fix the issue, then
git add .
git commit -m "fix: issue description"
git push

# Or re-run the failed workflow
gh run rerun <run-id>
```

---

## 🔐 Secrets Management

### View secrets
```bash
gh secret list
```

### Add/Update secrets
```bash
# KUBECONFIG
cat ~/.kube/config | base64 | gh secret set KUBECONFIG

# API URL
gh secret set REACT_APP_API_URL
# Enter: http://backend-api-service.backend.svc.cluster.local:8080

# Docker Hub (optional)
gh secret set DOCKER_USERNAME
gh secret set DOCKER_PASSWORD
```

### Delete secret
```bash
gh secret delete SECRET_NAME
```

---

## 📝 Commit Message Format

Use semantic commit messages for PR checks:

```bash
feat: add new feature
fix: fix bug
docs: update documentation
style: format code
refactor: refactor code
perf: improve performance
test: add tests
build: update build config
ci: update CI/CD
chore: maintenance tasks
revert: revert previous commit
```

**Examples:**
```bash
git commit -m "feat: add user authentication"
git commit -m "fix: resolve memory leak in backend"
git commit -m "docs: update API documentation"
git commit -m "ci: optimize Docker build caching"
```

---

## 🎨 Useful Aliases

Add to your `~/.zshrc` or `~/.bashrc`:

```bash
# GitHub CLI shortcuts
alias ghw='gh run watch'
alias ghl='gh run list'
alias ghv='gh run view'
alias ghs='gh secret list'

# Kubernetes shortcuts
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get svc'
alias kgd='kubectl get deployments'
alias klf='kubectl logs -f'
alias kd='kubectl describe'

# DevOps project shortcuts
alias cicd-setup='cd ~/path/to/devops && ./scripts/setup-github-secrets.sh'
alias cicd-test='cd ~/path/to/devops && ./scripts/local-test.sh'
alias cicd-verify='cd ~/path/to/devops && ./scripts/verify-deployment.sh'
```

Then reload: `source ~/.zshrc` or `source ~/.bashrc`

---

## 📚 Quick Links

| Resource | Link |
|----------|------|
| Actions Tab | `https://github.com/username/devops/actions` |
| Packages | `https://github.com/username?tab=packages` |
| Security | `https://github.com/username/devops/security` |
| Settings | `https://github.com/username/devops/settings` |

---

## 🆘 Emergency Procedures

### Production is down!

1. **Check status**
   ```bash
   kubectl get pods --all-namespaces
   ./scripts/verify-deployment.sh
   ```

2. **Check recent deploys**
   ```bash
   gh run list --limit 5
   ```

3. **Rollback immediately**
   ```bash
   kubectl rollout undo deployment/backend-api -n backend
   kubectl rollout undo deployment/frontend-app -n frontend
   ```

4. **Verify rollback**
   ```bash
   kubectl rollout status deployment/backend-api -n backend
   ./scripts/verify-deployment.sh
   ```

5. **Investigate**
   ```bash
   kubectl logs -n backend deployment/backend-api --previous
   kubectl get events -n backend --sort-by='.lastTimestamp'
   ```

### Workflow stuck

1. **Cancel the run**
   ```bash
   gh run list
   gh run cancel <run-id>
   ```

2. **Check for issues**
   ```bash
   gh run view <run-id> --log
   ```

3. **Fix and re-run**
   ```bash
   # Fix the issue
   git add .
   git commit -m "fix: description"
   git push
   ```

---

## 💡 Pro Tips

1. **Always test locally first**
   ```bash
   ./scripts/local-test.sh
   ```

2. **Watch deployments in real-time**
   ```bash
   gh run watch
   # In another terminal:
   kubectl get pods -n backend -w
   ```

3. **Use path-based commits to trigger specific workflows**
   ```bash
   # Only trigger backend workflow
   git add backend/
   git commit -m "feat: update backend"
   
   # Only trigger frontend workflow
   git add frontend/
   git commit -m "feat: update frontend"
   ```

4. **Check workflow files before pushing**
   ```bash
   yamllint .github/workflows/*.yml
   ```

5. **Monitor resource usage**
   ```bash
   kubectl top nodes
   kubectl top pods -n backend
   kubectl top pods -n frontend
   ```

---

## 📊 Metrics to Monitor

- ✅ Workflow success rate
- ⏱️ Build duration
- 🔒 Security scan results
- 📈 Deployment frequency
- ⚡ Rollback rate
- 🐛 Failed job reasons

View in: `https://github.com/username/devops/actions`

---

## 🎓 Best Practices

1. ✅ Test locally before pushing
2. ✅ Use meaningful commit messages
3. ✅ Monitor workflow runs
4. ✅ Review security scan results
5. ✅ Verify deployments
6. ✅ Keep secrets updated
7. ✅ Document changes in PRs
8. ✅ Use feature branches for big changes

---

**Keep this card handy for quick reference!**

*Last updated: October 2025*

