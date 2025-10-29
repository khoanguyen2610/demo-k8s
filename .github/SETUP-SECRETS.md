# GitHub Secrets Setup

3 secrets required for CI/CD deployment.

## Quick Setup

```bash
# 1. Docker Hub
gh secret set DOCKER_USERNAME -b "khoanguyen2610"
gh secret set DOCKER_PASSWORD  # Enter password/token when prompted

# 2. Kubernetes
kubectl config view --flatten --minify > kubeconfig.yaml
cat kubeconfig.yaml | base64 | gh secret set KUBECONFIG
rm kubeconfig.yaml

# 3. Verify
gh secret list
```

Done! ✅

## Detailed Setup

### 1. Docker Hub Credentials

**Option A: Using GitHub CLI (Easiest)**
```bash
gh secret set DOCKER_USERNAME -b "khoanguyen2610"
gh secret set DOCKER_PASSWORD
# Enter your Docker Hub password when prompted
```

**Option B: Using Web UI**
1. Go to your repository on GitHub
2. Settings → Secrets and variables → Actions
3. New repository secret:
   - Name: `DOCKER_USERNAME`
   - Value: `khoanguyen2610`
4. New repository secret:
   - Name: `DOCKER_PASSWORD`
   - Value: Your Docker Hub password or token

**🔐 Recommended: Use Personal Access Token**

Instead of password:
1. Go to https://hub.docker.com/settings/security
2. Create new token: "GitHub Actions"
3. Copy token
4. Use token as `DOCKER_PASSWORD`

### 2. Kubernetes Config

**If you have a cluster:**

```bash
# Get current kubeconfig
kubectl config view --flatten --minify > kubeconfig.yaml

# Verify it works
kubectl --kubeconfig=kubeconfig.yaml cluster-info

# Encode to base64
# macOS:
cat kubeconfig.yaml | base64 | gh secret set KUBECONFIG

# Linux:
cat kubeconfig.yaml | base64 -w 0 | gh secret set KUBECONFIG

# Clean up
rm kubeconfig.yaml
```

**If you don't have a cluster:**

**Option 1: Minikube (Local)**
```bash
# Install
brew install minikube  # macOS
# or see: https://minikube.sigs.k8s.io/docs/start/

# Start
minikube start

# Get config
kubectl config view --flatten --minify > kubeconfig.yaml
cat kubeconfig.yaml | base64 | gh secret set KUBECONFIG
rm kubeconfig.yaml
```

**Option 2: Cloud Provider**

- **DigitalOcean**: ~$12/month - https://www.digitalocean.com/products/kubernetes
- **Linode**: ~$10/month - https://www.linode.com/products/kubernetes/
- **Oracle**: Free tier - https://www.oracle.com/cloud/free/

After creating cluster:
```bash
# Download kubeconfig from provider
# Then:
cat downloaded-kubeconfig.yaml | base64 | gh secret set KUBECONFIG
```

### 3. Verify

```bash
# Check all secrets are set
gh secret list

# Expected output:
# DOCKER_PASSWORD   Updated YYYY-MM-DD
# DOCKER_USERNAME   Updated YYYY-MM-DD
# KUBECONFIG        Updated YYYY-MM-DD
```

## Testing

### Test Docker Hub Login

```bash
# Test credentials
echo "$DOCKER_PASSWORD" | docker login -u khoanguyen2610 --password-stdin

# Should see: "Login Succeeded"
```

### Test Kubeconfig

```bash
# Decode and test (replace YOUR_BASE64 with your encoded config)
echo "YOUR_BASE64" | base64 -d > test-config.yaml
kubectl --kubeconfig=test-config.yaml cluster-info
rm test-config.yaml
```

## Troubleshooting

### "Docker login failed"

**Cause:** Wrong username or password

**Fix:**
```bash
# Verify credentials locally first
docker login -u khoanguyen2610

# If successful, update secret
gh secret set DOCKER_PASSWORD
```

### "connection refused to localhost:8080"

**Cause:** KUBECONFIG secret not set or invalid

**Fix:**
```bash
# Re-encode kubeconfig
kubectl config view --flatten --minify > kubeconfig.yaml

# macOS
cat kubeconfig.yaml | base64 | gh secret set KUBECONFIG

# Linux  
cat kubeconfig.yaml | base64 -w 0 | gh secret set KUBECONFIG

rm kubeconfig.yaml
```

### "base64: invalid input"

**Cause:** Wrong base64 encoding (macOS vs Linux)

**Fix:**
- macOS: `base64` (no flags)
- Linux: `base64 -w 0` (no line wrapping)

### "unauthorized: authentication required"

**Cause:** Docker Hub credentials incorrect

**Fix:**
```bash
# Use personal access token instead
# 1. Go to hub.docker.com/settings/security
# 2. Create token
# 3. Set as secret
gh secret set DOCKER_PASSWORD
```

## Security

✅ **Never commit secrets to git**
✅ **Use tokens instead of passwords**
✅ **Rotate secrets every 90 days**
✅ **Use minimal permissions**
✅ **Delete temporary files**

```bash
# Bad - leaves files around
cat kubeconfig.yaml | base64 > encoded.txt
cat encoded.txt  # Don't do this!

# Good - pipes directly
cat kubeconfig.yaml | base64 | gh secret set KUBECONFIG
rm kubeconfig.yaml
```

## Next Steps

After setting up secrets:

```bash
# 1. Push to trigger workflow
git add .
git commit -m "Setup CI/CD"
git push origin main

# 2. Watch workflow
# Go to: GitHub → Actions tab

# 3. Verify deployment
kubectl get pods -n backend
kubectl get pods -n frontend
```

## Quick Reference

```bash
# List secrets
gh secret list

# Set secret
gh secret set SECRET_NAME

# Delete secret
gh secret delete SECRET_NAME

# Update secret
gh secret set SECRET_NAME  # Just set again
```

## Need Help?

Check:
- [Workflow README](workflows/README.md)
- [Kubernetes README](../k8s/README.md)
- Workflow logs: GitHub → Actions
