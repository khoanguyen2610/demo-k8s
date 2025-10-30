# 📋 Quick Reference Card

## 🚀 Start/Stop Cluster

```bash
# Start everything (one command)
cd /Users/khoa.nguyen/Workings/Personal/devops/k8s-practise
./start-cluster.sh

# Stop everything
./stop-cluster.sh
```

---

## 🌐 Access URLs

```bash
# Public (via Cloudflare)
Frontend:  https://local.kn-tech.click/
Backend:   https://local-api.kn-tech.click/v1/health

# Local (via port-forward)
ArgoCD:    https://localhost:8081
Grafana:   http://localhost:3000
Prometheus: http://localhost:9090
```

---

## 🔐 Credentials

```bash
# ArgoCD
Username: admin
Password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Grafana
Username: admin
Password: admin
```

---

## 📊 Check Status

```bash
# All pods
kubectl get pods --all-namespaces

# Production apps
kubectl get pods -n production

# Applications in ArgoCD
kubectl get application -n argocd

# Ingress
kubectl get ingress -n production
```

---

## 🔄 Common Operations

```bash
# Restart deployment
kubectl rollout restart deployment/backend -n production
kubectl rollout restart deployment/frontend -n production

# Scale deployment
kubectl scale deployment/backend --replicas=3 -n production

# View logs
kubectl logs -f deployment/backend -n production
kubectl logs -f deployment/frontend -n production

# Force sync in ArgoCD
kubectl patch application backend -n argocd \
  -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}' \
  --type merge
```

---

## 🧪 Test Endpoints

```bash
# Backend health
curl -H "Host: local-api.kn-tech.click" http://localhost:8080/v1/health

# Backend users
curl -H "Host: local-api.kn-tech.click" http://localhost:8080/v1/users | jq

# Frontend
curl -H "Host: local.kn-tech.click" http://localhost:8080/ | head -10

# Public URLs (if Cloudflare tunnel running)
curl https://local-api.kn-tech.click/v1/health
```

---

## 🔧 Port Forwarding

```bash
# NGINX Ingress
kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8080:80 &

# ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8081:443 &

# Grafana
kubectl port-forward -n monitoring service/grafana 3000:3000 &

# Prometheus
kubectl port-forward -n monitoring service/prometheus 9090:9090 &

# Kill all port forwards
pkill -f "port-forward"
```

---

## ☁️ Cloudflare Tunnel

```bash
# Start tunnel
cloudflared tunnel run demo-k8s-local-app > /tmp/cloudflared.log 2>&1 &

# Check status
ps aux | grep cloudflared

# View logs
tail -f /tmp/cloudflared.log

# Stop tunnel
pkill cloudflared
```

---

## 🐳 Docker Operations

```bash
# Build and push backend
cd k8s-001/backend
docker build --target api -t khoanguyen2610/backend:latest .
docker push khoanguyen2610/backend:latest

# Build and push frontend
cd k8s-001/frontend
docker build -t khoanguyen2610/frontend:latest .
docker push khoanguyen2610/frontend:latest

# Build consumer
docker build --target consumer -t khoanguyen2610/backend-consumer:latest .
docker push khoanguyen2610/backend-consumer:latest
```

---

## 📦 GitOps Workflow

```bash
# Make changes to manifests
vi k8s-practise/k8s/2-apps/backend/deployment.yaml

# Commit and push
git add k8s-practise/
git commit -m "Update backend to v2.0"
git push origin main

# ArgoCD auto-syncs in 3 minutes
# Or force refresh in UI: https://localhost:8081
```

---

## 🔍 Troubleshooting

```bash
# Check pod details
kubectl describe pod <pod-name> -n production

# Check pod logs
kubectl logs <pod-name> -n production

# Check events
kubectl get events -n production --sort-by='.lastTimestamp'

# Check ArgoCD application
kubectl describe application backend -n argocd

# Restart NGINX Ingress
kubectl rollout restart deployment/ingress-nginx-controller -n ingress-nginx

# Delete and recreate pod
kubectl delete pod <pod-name> -n production
```

---

## 📚 Documentation

```
k8s-practise/
├── STARTUP-GUIDE.md           # Complete startup instructions
├── QUICK-REFERENCE.md         # This file
├── DEPLOYMENT-SUMMARY.md      # Architecture overview
├── MONITORING-GUIDE.md        # Prometheus & Grafana
├── ARGOCD-GUIDE.md           # GitOps guide
├── PUBLIC-ACCESS.md          # Cloudflare tunnel
├── SYNC-TO-ARGOCD.md         # ArgoCD sync guide
└── k8s/
    ├── README.md             # Kubernetes setup guide
    └── 1-platform/argocd/
        ├── README.md         # ArgoCD detailed docs
        └── SETUP-GUIDE.md    # ArgoCD quick start
```

---

## 🎯 Daily Workflow

```bash
# Morning startup
cd /Users/khoa.nguyen/Workings/Personal/devops/k8s-practise
./start-cluster.sh

# Check everything is running
kubectl get pods --all-namespaces

# Work on your apps...

# Evening shutdown
./stop-cluster.sh
```

---

## 📊 Cluster Architecture

```
Minikube Cluster
├── Namespaces
│   ├── production         (apps)
│   ├── monitoring         (prometheus, grafana)
│   ├── logging           (loki, promtail)
│   ├── argocd            (gitops)
│   └── ingress-nginx     (traffic routing)
│
├── Applications
│   ├── Backend API       (2 replicas)
│   ├── Frontend          (2 replicas)
│   ├── Email Processor   (1 pod)
│   ├── Data Sync         (1 pod)
│   └── Report Generator  (1 pod)
│
└── Platform
    ├── NGINX Ingress     (traffic routing)
    ├── ArgoCD            (gitops)
    ├── Prometheus        (metrics)
    └── Grafana           (dashboards)
```

---

## 🔢 Resource Count

- **Total Pods**: 37+
- **Namespaces**: 6
- **Deployments**: 10+
- **Services**: 15+
- **Ingress Rules**: 2

---

## ✅ Health Checks

```bash
# Quick health check
curl -H "Host: local-api.kn-tech.click" http://localhost:8080/v1/health

# All pods running?
kubectl get pods --all-namespaces | grep -v Running | grep -v Completed

# ArgoCD sync status
kubectl get application -n argocd

# Check ingress
kubectl get ingress -n production
```

---

## 🎉 One-Liners

```bash
# Restart everything in production
kubectl rollout restart deployment -n production

# Get all ArgoCD passwords
kubectl -n argocd get secrets -o json | jq -r '.items[] | select(.metadata.name | contains("admin")) | .data.password' | base64 -d

# Watch all pods
watch kubectl get pods --all-namespaces

# Delete all failed pods
kubectl delete pods --field-selector=status.phase=Failed --all-namespaces

# Get resource usage
kubectl top nodes
kubectl top pods -n production
```

---

**Keep this card handy for daily operations!** 📋

