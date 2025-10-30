# 🚀 Complete Cluster Startup Guide

## After `minikube stop` - How to Start Everything

This guide shows you how to restart your complete Kubernetes infrastructure after stopping Minikube.

---

## 🎯 Quick Start (One Command)

```bash
cd /Users/khoa.nguyen/Workings/Personal/devops/k8s-practise
./start-cluster.sh
```

---

## 📋 Manual Step-by-Step Process

### Step 1: Start Minikube

```bash
# Start Minikube cluster
minikube start

# Verify cluster is running
kubectl cluster-info
kubectl get nodes
```

### Step 2: Deploy Base Infrastructure (0-init-cluster)

```bash
cd /Users/khoa.nguyen/Workings/Personal/devops/k8s-practise

# Create production namespace
kubectl apply -f k8s/0-init-cluster/namespace.yaml

# Create storage class
kubectl apply -f k8s/0-init-cluster/storageclass.yaml

# Install NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/cloud/deploy.yaml

# Wait for NGINX to be ready (important!)
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s

# Apply NGINX custom configuration
kubectl apply -f k8s/0-init-cluster/nginx-configmap.yaml

# Optional: Create registry secret (if using private images)
# kubectl apply -f k8s/0-init-cluster/registry-secret.yaml
```

### Step 3: Deploy Platform Services (1-platform)

```bash
# Deploy monitoring stack
kubectl apply -f k8s/1-platform/monitoring/

# Deploy logging stack (optional)
kubectl apply -f k8s/1-platform/logging/

# Wait for monitoring to be ready
kubectl wait --namespace monitoring \
  --for=condition=ready pod \
  --selector=app=prometheus \
  --timeout=300s

kubectl wait --namespace monitoring \
  --for=condition=ready pod \
  --selector=app=grafana \
  --timeout=300s

# Deploy ArgoCD
kubectl apply -f k8s/1-platform/argocd/namespace.yaml
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --namespace argocd \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=argocd-server \
  --timeout=300s
```

### Step 4: Deploy Applications (2-apps)

**Option A: Using kubectl (Direct)**
```bash
# Deploy backend
kubectl apply -f k8s/2-apps/backend/

# Deploy frontend
kubectl apply -f k8s/2-apps/frontend/

# Wait for apps to be ready
kubectl wait --namespace production \
  --for=condition=ready pod \
  --selector=app=backend \
  --timeout=300s

kubectl wait --namespace production \
  --for=condition=ready pod \
  --selector=app=frontend \
  --timeout=300s
```

**Option B: Using ArgoCD (GitOps)**
```bash
# Deploy ArgoCD applications
kubectl apply -f k8s/1-platform/argocd/applications/

# Or deploy all at once with app-of-apps
kubectl apply -f k8s/1-platform/argocd/applications/app-of-apps.yaml

# Watch ArgoCD sync
kubectl get application -n argocd -w
```

### Step 5: Setup Port Forwarding

```bash
# NGINX Ingress (for local access)
kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8080:80 > /dev/null 2>&1 &

# ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8081:443 > /dev/null 2>&1 &

# Grafana
kubectl port-forward -n monitoring service/grafana 3000:3000 > /dev/null 2>&1 &

# Prometheus
kubectl port-forward -n monitoring service/prometheus 9090:9090 > /dev/null 2>&1 &
```

### Step 6: Start Cloudflare Tunnel (Optional)

```bash
# Start cloudflared tunnel
cloudflared tunnel run demo-k8s-local-app > /tmp/cloudflared.log 2>&1 &
```

### Step 7: Verify Everything

```bash
# Check all pods
kubectl get pods --all-namespaces

# Check applications
kubectl get pods -n production
kubectl get ingress -n production

# Get ArgoCD password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
echo

# Test endpoints
curl -H "Host: local-api.kn-tech.click" http://localhost:8080/v1/health
curl -H "Host: local.kn-tech.click" http://localhost:8080/
```

---

## 🤖 Automated Startup Script

Create a startup script for easy restart:

### Create `start-cluster.sh`

```bash
#!/bin/bash

set -e  # Exit on error

echo "🚀 Starting Kubernetes Cluster..."
echo "================================"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Start Minikube
echo -e "\n${YELLOW}Step 1: Starting Minikube...${NC}"
minikube start
echo -e "${GREEN}✓ Minikube started${NC}"

# Step 2: Deploy base infrastructure
echo -e "\n${YELLOW}Step 2: Deploying base infrastructure...${NC}"
kubectl apply -f k8s/0-init-cluster/namespace.yaml
kubectl apply -f k8s/0-init-cluster/storageclass.yaml
echo -e "${GREEN}✓ Namespace and storage created${NC}"

# Step 3: Install NGINX Ingress
echo -e "\n${YELLOW}Step 3: Installing NGINX Ingress Controller...${NC}"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/cloud/deploy.yaml
echo "Waiting for NGINX Ingress to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s
kubectl apply -f k8s/0-init-cluster/nginx-configmap.yaml
echo -e "${GREEN}✓ NGINX Ingress ready${NC}"

# Step 4: Deploy monitoring
echo -e "\n${YELLOW}Step 4: Deploying monitoring stack...${NC}"
kubectl apply -f k8s/1-platform/monitoring/
echo "Waiting for monitoring to be ready..."
sleep 10
echo -e "${GREEN}✓ Monitoring deployed${NC}"

# Step 5: Deploy ArgoCD
echo -e "\n${YELLOW}Step 5: Deploying ArgoCD...${NC}"
kubectl apply -f k8s/1-platform/argocd/namespace.yaml
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
echo "Waiting for ArgoCD to be ready..."
kubectl wait --namespace argocd \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=argocd-server \
  --timeout=300s
echo -e "${GREEN}✓ ArgoCD ready${NC}"

# Step 6: Deploy applications
echo -e "\n${YELLOW}Step 6: Deploying applications...${NC}"
kubectl apply -f k8s/2-apps/backend/
kubectl apply -f k8s/2-apps/frontend/
echo "Waiting for applications to be ready..."
sleep 15
echo -e "${GREEN}✓ Applications deployed${NC}"

# Step 7: Deploy ArgoCD applications
echo -e "\n${YELLOW}Step 7: Configuring ArgoCD applications...${NC}"
kubectl apply -f k8s/1-platform/argocd/applications/
echo -e "${GREEN}✓ ArgoCD applications configured${NC}"

# Step 8: Setup port forwarding
echo -e "\n${YELLOW}Step 8: Setting up port forwarding...${NC}"

# Kill existing port forwards
pkill -f "port-forward.*ingress-nginx" || true
pkill -f "port-forward.*argocd" || true
pkill -f "port-forward.*grafana" || true
pkill -f "port-forward.*prometheus" || true

# Start new port forwards
kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8080:80 > /dev/null 2>&1 &
kubectl port-forward svc/argocd-server -n argocd 8081:443 > /dev/null 2>&1 &
kubectl port-forward -n monitoring service/grafana 3000:3000 > /dev/null 2>&1 &
kubectl port-forward -n monitoring service/prometheus 9090:9090 > /dev/null 2>&1 &

sleep 3
echo -e "${GREEN}✓ Port forwarding configured${NC}"

# Step 9: Get ArgoCD password
echo -e "\n${YELLOW}Step 9: Getting credentials...${NC}"
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d || echo "Not yet available")

# Summary
echo -e "\n${GREEN}================================${NC}"
echo -e "${GREEN}✓ Cluster startup complete!${NC}"
echo -e "${GREEN}================================${NC}"

echo -e "\n📊 ${YELLOW}Access Points:${NC}"
echo "  Frontend:    http://localhost:8080 (Host: local.kn-tech.click)"
echo "  Backend API: http://localhost:8080 (Host: local-api.kn-tech.click)"
echo "  ArgoCD UI:   https://localhost:8081"
echo "  Grafana:     http://localhost:3000"
echo "  Prometheus:  http://localhost:9090"

echo -e "\n🔐 ${YELLOW}Credentials:${NC}"
echo "  ArgoCD:   admin / $ARGOCD_PASSWORD"
echo "  Grafana:  admin / admin"

echo -e "\n✅ ${YELLOW}Quick Tests:${NC}"
echo "  curl -H \"Host: local-api.kn-tech.click\" http://localhost:8080/v1/health"
echo "  curl -H \"Host: local.kn-tech.click\" http://localhost:8080/"
echo "  open https://localhost:8081  # ArgoCD"
echo "  open http://localhost:3000   # Grafana"

echo -e "\n📝 ${YELLOW}Check status:${NC}"
echo "  kubectl get pods --all-namespaces"
echo "  kubectl get application -n argocd"

echo -e "\n${GREEN}🚀 All services are starting up!${NC}"
echo "Note: It may take 1-2 minutes for all pods to be fully ready."
```

### Make it executable

```bash
chmod +x /Users/khoa.nguyen/Workings/Personal/devops/k8s-practise/start-cluster.sh
```

---

## 🛑 Shutdown Script

Create a clean shutdown script:

### Create `stop-cluster.sh`

```bash
#!/bin/bash

echo "🛑 Stopping Kubernetes Cluster..."
echo "================================"

# Stop port forwards
echo "Stopping port forwards..."
pkill -f "port-forward.*ingress-nginx" || true
pkill -f "port-forward.*argocd" || true
pkill -f "port-forward.*grafana" || true
pkill -f "port-forward.*prometheus" || true

# Stop cloudflared
echo "Stopping Cloudflare tunnel..."
pkill cloudflared || true

# Stop Minikube
echo "Stopping Minikube..."
minikube stop

echo "✓ Cluster stopped successfully!"
```

### Make it executable

```bash
chmod +x /Users/khoa.nguyen/Workings/Personal/devops/k8s-practise/stop-cluster.sh
```

---

## 🔍 Verification Checklist

After startup, verify each component:

### Check Namespaces
```bash
kubectl get namespaces
# Should see: production, monitoring, logging, argocd, ingress-nginx
```

### Check Pods
```bash
# All pods
kubectl get pods --all-namespaces | grep -v "kube-system"

# Production
kubectl get pods -n production

# Monitoring
kubectl get pods -n monitoring

# ArgoCD
kubectl get pods -n argocd

# Ingress
kubectl get pods -n ingress-nginx
```

### Check Services
```bash
kubectl get svc --all-namespaces | grep -v "kube-system"
```

### Check Ingress
```bash
kubectl get ingress -n production
```

### Check ArgoCD Applications
```bash
kubectl get application -n argocd
```

### Test Endpoints
```bash
# Backend health
curl -H "Host: local-api.kn-tech.click" http://localhost:8080/v1/health

# Frontend
curl -H "Host: local.kn-tech.click" http://localhost:8080/ | head -10

# ArgoCD
curl -k https://localhost:8081 | head -5

# Grafana
curl http://localhost:3000 | head -5

# Prometheus
curl http://localhost:9090/api/v1/query?query=up | jq
```

---

## 🔄 Restart Cloudflare Tunnel

If using Cloudflare Tunnel for public access:

```bash
# Check if running
ps aux | grep cloudflared

# Stop if needed
pkill cloudflared

# Start
cloudflared tunnel run demo-k8s-local-app > /tmp/cloudflared.log 2>&1 &

# Check logs
tail -f /tmp/cloudflared.log

# Verify
curl https://local-api.kn-tech.click/v1/health
```

---

## 🚨 Troubleshooting

### Minikube won't start
```bash
# Check status
minikube status

# Delete and recreate
minikube delete
minikube start

# Check logs
minikube logs
```

### Pods stuck in Pending
```bash
# Check why
kubectl describe pod <pod-name> -n <namespace>

# Common issues:
# - Image pull issues: Check image name and registry access
# - Resource constraints: Check Minikube resources
# - Node issues: Check node status
```

### NGINX Ingress not working
```bash
# Check NGINX pods
kubectl get pods -n ingress-nginx

# Check logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# Restart NGINX
kubectl rollout restart deployment/ingress-nginx-controller -n ingress-nginx
```

### Port forward not working
```bash
# Kill all port forwards
pkill -f "port-forward"

# Restart specific port forward
kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8080:80 &

# Check if port is in use
lsof -i :8080
```

### ArgoCD applications not syncing
```bash
# Check application status
kubectl get application -n argocd

# Check specific app
kubectl describe application backend -n argocd

# Force sync
kubectl patch application backend -n argocd \
  -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}' \
  --type merge
```

---

## 📊 Expected Timings

- **Minikube start**: 1-2 minutes
- **NGINX Ingress**: 1-2 minutes
- **Platform services**: 2-3 minutes
- **Applications**: 1-2 minutes
- **Total**: ~5-10 minutes

---

## 🎯 Quick Commands Reference

```bash
# Start everything
cd /Users/khoa.nguyen/Workings/Personal/devops/k8s-practise
./start-cluster.sh

# Stop everything
./stop-cluster.sh

# Check status
kubectl get pods --all-namespaces
kubectl get application -n argocd

# View logs
kubectl logs -f deployment/backend -n production
kubectl logs -f deployment/frontend -n production

# Restart deployment
kubectl rollout restart deployment/backend -n production
kubectl rollout restart deployment/frontend -n production

# Scale deployment
kubectl scale deployment/backend --replicas=3 -n production

# Access UIs
open https://localhost:8081  # ArgoCD
open http://localhost:3000   # Grafana
open http://localhost:9090   # Prometheus
```

---

## 💾 Save Your Configuration

To make this persistent:

1. **Commit to Git** (already done):
   ```bash
   cd /Users/khoa.nguyen/Workings/Personal/devops
   git add k8s-practise/
   git commit -m "Add startup scripts"
   git push origin main
   ```

2. **Backup Minikube** (optional):
   ```bash
   # Export cluster config
   kubectl config view > cluster-backup.yaml
   
   # Export all resources
   kubectl get all --all-namespaces -o yaml > all-resources-backup.yaml
   ```

3. **Document any customizations**:
   - ArgoCD credentials
   - Registry secrets
   - Custom configurations

---

## ✅ One-Time Setup Items

These only need to be done once (already completed):

✅ Minikube installation  
✅ kubectl configuration  
✅ Docker images built and pushed  
✅ Git repository setup  
✅ Cloudflare tunnel configured  
✅ Manifests created  

**After `minikube stop`, you only need to:**
1. Run `./start-cluster.sh`
2. Wait 5-10 minutes
3. Everything is back up! 🎉

---

## 🎉 Summary

**To restart after `minikube stop`:**

```bash
# Quick method
cd /Users/khoa.nguyen/Workings/Personal/devops/k8s-practise
./start-cluster.sh

# Wait 5-10 minutes
# Check: kubectl get pods --all-namespaces

# Access:
# - ArgoCD:   https://localhost:8081
# - Grafana:  http://localhost:3000
# - Frontend: https://local.kn-tech.click/
# - Backend:  https://local-api.kn-tech.click/v1/health
```

**That's it! Your entire infrastructure is back online.** 🚀

