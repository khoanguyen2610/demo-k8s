# Free Tier Kubernetes Setup 🆓

This is a **fully optimized** Kubernetes configuration for running on **free tier / minimal resources**.

## What's Optimized?

### ✅ Minimal Resource Allocation

| Component | CPU Request | CPU Limit | Memory Request | Memory Limit | Replicas |
|-----------|-------------|-----------|----------------|--------------|----------|
| Backend   | 50m         | 200m      | 64Mi          | 128Mi        | 1        |
| Frontend  | 50m         | 150m      | 64Mi          | 128Mi        | 1        |
| **TOTAL** | **100m**    | **350m**  | **128Mi**     | **256Mi**    | **2**    |

### 💰 Cost Optimization Features

✅ **Single replica per service** - No redundancy overhead  
✅ **Minimal CPU requests** (50m = 0.05 cores each)  
✅ **Minimal memory** (64Mi requests)  
✅ **Extended health check intervals** (30s instead of 10s)  
✅ **NodePort instead of LoadBalancer** - No extra LB costs  
✅ **No autoscaling** - Fixed resource usage  
✅ **Reduced revision history** (2 instead of 3)  

### 🖥️ Instance Requirements

**Minimum**: `t3.micro` (1 vCPU, 1GB RAM)
- Your apps use ~10-15% CPU baseline
- Peak usage: ~35% CPU, ~256Mi memory
- Leaves ~650Mi for system processes
- **Perfect fit for AWS free tier!**

## Quick Start (3 Commands)

```bash
# 1. Create namespaces
kubectl apply -f namespaces.yaml

# 2. Deploy backend & frontend
kubectl apply -f backend-deployment.yaml
kubectl apply -f frontend-deployment.yaml

# 3. Access via port-forward (no LoadBalancer costs!)
kubectl port-forward -n frontend svc/frontend-app-service 3000:80
```

Visit: http://localhost:3000 🎉

## Resource Comparison

### Before (Standard Setup)
```
CPU Request:  200m (2 replicas × 100m)
Memory:       512Mi
Replicas:     4 total (2 FE + 2 BE)
Services:     LoadBalancer type
Health Checks: Every 10 seconds
Minimum Instance: t3.small or larger
```

### After (Free Tier Optimized) ✨
```
CPU Request:  100m (2 replicas × 50m)
Memory:       256Mi  
Replicas:     2 total (1 FE + 1 BE)
Services:     NodePort type
Health Checks: Every 30 seconds
Minimum Instance: t3.micro
```

**Savings**: ~50% fewer resources!

## Access Methods (Free Tier Friendly)

### Option 1: Port-Forward (Recommended for Development)
```bash
# Frontend
kubectl port-forward -n frontend svc/frontend-app-service 3000:80

# Backend
kubectl port-forward -n backend svc/backend-api-service 8080:8080
```
**Cost**: $0 💚

### Option 2: NodePort (For team access)
```bash
# Get node IP
kubectl get nodes -o wide

# Get NodePort
kubectl get svc -n frontend

# Access via: http://<NODE-IP>:<NODE-PORT>
```
**Cost**: $0 (if within free tier limits) 💚

### Option 3: LoadBalancer (NOT RECOMMENDED for free tier)
```bash
# Changes service type to LoadBalancer
kubectl patch svc frontend-app-service -n frontend -p '{"spec":{"type":"LoadBalancer"}}'
```
**Cost**: ~$18/month per LoadBalancer ⚠️

## Monitoring Resource Usage

```bash
# Check if metrics-server is installed
kubectl top nodes

# View pod resource usage
kubectl top pods -n backend
kubectl top pods -n frontend

# Detailed resource view
kubectl describe nodes
```

## What if I run out of resources?

### Symptoms:
- Pods stuck in "Pending" state
- OOMKilled errors
- CPU throttling

### Solutions:

#### Option 1: Reduce further (bare minimum)
```bash
# Backend: 25m CPU, 32Mi memory
# Frontend: 25m CPU, 32Mi memory
# Edit deployment files and apply again
```

#### Option 2: Increase instance size
```bash
# In minimal-cluster.yaml, change:
instanceType: t3.small  # 2 vCPU, 2GB RAM (costs extra)
```

#### Option 3: Simplify
```bash
# Run only backend OR frontend
kubectl delete namespace frontend  # Keep only backend
# Or
kubectl delete namespace backend   # Keep only frontend
```

## Common Issues & Solutions

### Issue: Pod OOMKilled
```bash
# Increase memory limit slightly
memory:
  limits: 192Mi  # Instead of 128Mi
```

### Issue: Pod CrashLoopBackOff
```bash
# Check logs
kubectl logs -n backend <pod-name>

# Increase startup time
initialDelaySeconds: 20  # Instead of 15
```

### Issue: Health checks failing
```bash
# Increase timeouts
timeoutSeconds: 10       # Instead of 5
periodSeconds: 60        # Instead of 30
failureThreshold: 5      # Instead of 3
```

## Production Checklist (When Leaving Free Tier)

When you're ready to scale:

- [ ] Increase replicas to 2+ for high availability
- [ ] Add Horizontal Pod Autoscaler (HPA)
- [ ] Switch to LoadBalancer or Ingress for production traffic
- [ ] Add monitoring (Prometheus + Grafana)
- [ ] Add logging (ELK stack)
- [ ] Increase resource limits
- [ ] Add persistent volumes for stateful apps
- [ ] Setup CI/CD pipelines
- [ ] Configure TLS/SSL certificates
- [ ] Add NetworkPolicies for security

## FAQ

**Q: Can I run both apps on t3.micro?**  
A: Yes! The combined resource usage (100m CPU, 128Mi memory) fits comfortably.

**Q: What about database?**  
A: This setup assumes external managed database (RDS free tier, etc.). Running DB in-cluster requires more resources.

**Q: Is this production-ready?**  
A: For learning and small personal projects, yes. For production traffic, consider at least 2 replicas and larger instances.

**Q: How much will this cost on AWS?**  
A: Using t3.micro + free tier = ~$0-5/month (depending on data transfer)

**Q: Can I use this on GKE/AKS?**  
A: Yes! Just adjust the cluster config for your cloud provider. Resource limits are cloud-agnostic.

## Support & Next Steps

See the main [README.md](./README.md) for:
- Full deployment guide
- Troubleshooting steps
- Monitoring commands
- Scaling options

Happy deploying! 🚀

