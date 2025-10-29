# GitHub Secrets Setup Guide

This guide will help you set up the required secrets for GitHub Actions deployment.

## Required Secrets

You need to configure 3 secrets:
1. `DOCKER_USERNAME` - Your Docker Hub username
2. `DOCKER_PASSWORD` - Your Docker Hub password or access token
3. `KUBECONFIG` - Base64 encoded kubeconfig file

## Quick Setup

### Option 1: Using GitHub CLI (Recommended)

```bash
# 1. Docker Hub credentials
gh secret set DOCKER_USERNAME
# Enter: khoanguyen2610

gh secret set DOCKER_PASSWORD
# Enter: your-docker-hub-password-or-token

# 2. Kubernetes config
kubectl config view --flatten --minify > /tmp/kubeconfig.yaml
cat /tmp/kubeconfig.yaml | base64 | gh secret set KUBECONFIG
rm /tmp/kubeconfig.yaml
```

### Option 2: Using GitHub Web UI

1. Go to your repository on GitHub
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret:

#### DOCKER_USERNAME
- Name: `DOCKER_USERNAME`
- Value: `khoanguyen2610`

#### DOCKER_PASSWORD
- Name: `DOCKER_PASSWORD`
- Value: Your Docker Hub password or personal access token

#### KUBECONFIG
- Name: `KUBECONFIG`
- Value: Base64 encoded kubeconfig (see below)

## Detailed KUBECONFIG Setup

### Step 1: Get Your Kubeconfig

```bash
# Export your current kubeconfig
kubectl config view --flatten --minify > kubeconfig.yaml

# Verify it works
KUBECONFIG=kubeconfig.yaml kubectl cluster-info
```

### Step 2: Encode to Base64

**On macOS:**
```bash
cat kubeconfig.yaml | base64
```

**On Linux:**
```bash
cat kubeconfig.yaml | base64 -w 0
```

This will output a long base64 string. Copy the entire output.

### Step 3: Add to GitHub

**Using GitHub CLI:**
```bash
cat kubeconfig.yaml | base64 | gh secret set KUBECONFIG
```

**Using Web UI:**
1. Go to Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `KUBECONFIG`
4. Value: Paste the base64 string
5. Click "Add secret"

### Step 4: Clean Up

```bash
# Remove the kubeconfig file (IMPORTANT for security!)
rm kubeconfig.yaml
```

## Docker Hub Setup

### Creating a Personal Access Token (Recommended)

Instead of using your Docker Hub password, create a Personal Access Token:

1. Go to https://hub.docker.com/settings/security
2. Click **New Access Token**
3. Description: `GitHub Actions - DevOps`
4. Permissions: `Read, Write, Delete`
5. Click **Generate**
6. Copy the token (you won't see it again!)
7. Use this token as `DOCKER_PASSWORD`

## Verification

### Test Your Secrets Locally

```bash
# Test Docker Hub login
echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

# Test kubeconfig
echo "$KUBECONFIG_BASE64" | base64 -d > /tmp/test-config
KUBECONFIG=/tmp/test-config kubectl cluster-info
rm /tmp/test-config
```

### Check Secrets in GitHub

```bash
# List all secrets (doesn't show values)
gh secret list
```

You should see:
```
DOCKER_PASSWORD   Updated YYYY-MM-DD
DOCKER_USERNAME   Updated YYYY-MM-DD
KUBECONFIG        Updated YYYY-MM-DD
```

## Troubleshooting

### KUBECONFIG Issues

**Error: "connection refused to localhost:8080"**

This means kubectl can't find the config. Possible causes:

1. **Secret not set**
   ```bash
   gh secret list | grep KUBECONFIG
   ```

2. **Invalid base64 encoding**
   ```bash
   # Test decoding
   echo "$YOUR_BASE64_STRING" | base64 -d
   # Should output valid YAML
   ```

3. **Wrong base64 command**
   - macOS: `base64` (no flags)
   - Linux: `base64 -w 0` (no line wrapping)

**Fix:**
```bash
# Re-encode properly
kubectl config view --flatten --minify > kubeconfig.yaml
cat kubeconfig.yaml | base64 | gh secret set KUBECONFIG
rm kubeconfig.yaml
```

### Docker Hub Issues

**Error: "unauthorized: incorrect username or password"**

Possible causes:
1. Wrong username (should be `khoanguyen2610`)
2. Wrong password/token
3. Token expired or revoked

**Fix:**
```bash
# Test login locally first
docker login -u khoanguyen2610
# If successful, use the same credentials in GitHub

# Update secret
gh secret set DOCKER_PASSWORD
```

### GitHub CLI Not Installed

Install GitHub CLI:

**macOS:**
```bash
brew install gh
gh auth login
```

**Linux:**
```bash
# See: https://github.com/cli/cli/blob/trunk/docs/install_linux.md
```

## Security Best Practices

1. ✅ **Never commit secrets** to git
2. ✅ **Use Personal Access Tokens** instead of passwords
3. ✅ **Rotate secrets regularly** (every 90 days)
4. ✅ **Use minimal permissions** for tokens
5. ✅ **Delete temporary files** after encoding
6. ✅ **Use environment protection** for production

## Next Steps

After setting up secrets:

1. Push to main branch:
   ```bash
   git add .
   git commit -m "Configure deployment"
   git push origin main
   ```

2. Check GitHub Actions:
   - Go to **Actions** tab
   - Watch the workflow run
   - Verify successful deployment

3. Verify deployment:
   ```bash
   kubectl get pods -n backend
   kubectl get pods -n frontend
   ```

## Support

If you encounter issues:

1. Check workflow logs in GitHub Actions
2. Verify secrets are set: `gh secret list`
3. Test kubeconfig locally
4. Review error messages carefully

## Quick Reference

```bash
# Set all secrets at once
gh secret set DOCKER_USERNAME -b "khoanguyen2610"
gh secret set DOCKER_PASSWORD  # Enter when prompted
kubectl config view --flatten --minify | base64 | gh secret set KUBECONFIG

# List secrets
gh secret list

# Delete secret (if needed)
gh secret delete SECRET_NAME

# Update secret
gh secret set SECRET_NAME  # Enter new value
```

