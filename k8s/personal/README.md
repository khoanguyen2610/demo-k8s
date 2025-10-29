# Kubernetes Deployment Guide - Free Tier Optimized

This directory contains Kubernetes manifests for deploying the frontend (React) and backend (Go API) applications.

**🆓 Optimized for free tier / minimal resources:**
- Single replica for each service
- Minimal CPU (50m) and memory (64Mi) requests
- Low resource limits to fit on small instances (t3.micro)
- Extended health check intervals to reduce overhead

## Architecture Overview

```
┌─────────────────────────────────────────────┐
│              Ingress/LoadBalancer           │
│         (External Traffic Entry)            │
└──────────────┬──────────────────────────────┘
               │
       ┌───────┴────────┐
       │                │
       ▼                ▼
┌──────────────┐  ┌──────────────┐
│  Frontend    │  │   Backend    │
│  Namespace   │  │   Namespace  │
│              │  │              │
│ ┌──────────┐ │  │ ┌──────────┐ │
│ │ Frontend │ │  │ │ Backend  │ │
│ │   Pods   │ │  │ │   Pods   │ │
│ │(React+   │ │  │ │ (Go API) │ │
│ │ Nginx)   │ │  │ │          │ │
│ └────┬─────┘ │  │ └────┬─────┘ │
│      │       │  │      │       │
│ ┌────▼─────┐ │  │ ┌────▼─────┐ │
│ │ Service  │ │  │ │ Service  │ │
│ │  (Port   │ │  │ │  (Port   │ │
│ │   80)    │ │  │ │  8080)   │ │
│ └──────────┘ │  │ └──────────┘ │
└──────────────┘  └──────────────┘
```

## Files Description

1. **namespaces.yaml** - Creates frontend and backend namespaces
2. **backend-deployment.yaml** - Backend Go API Deployment + Service
3. **frontend-deployment.yaml** - Frontend React App Deployment + Service + ConfigMap
4. **ingress.yaml** - Ingress rules for external access
5. **minimal-cluster.yaml** - EKS cluster configuration

## Prerequisites

1. **Kubernetes Cluster**: Running cluster (EKS, GKE, Minikube, etc.)
2. **kubectl**: Configured to connect to your cluster
3. **Docker Images**: Built and pushed to a registry
4. **Ingress Controller** (optional): For ingress resources

### Build and Push Docker Images

```bash
# Backend
cd backend
docker build -t your-registry/backend:latest .
docker push your-registry/backend:latest

# Frontend
cd frontend
docker build -t your-registry/frontend:latest .
docker push your-registry/frontend:latest
```

## Deployment Steps

### Step 1: Create Namespaces

```bash
kubectl apply -f namespaces.yaml
```

Verify namespaces:
```bash
kubectl get namespaces
```

### Step 2: Deploy Backend

```bash
kubectl apply -f backend-deployment.yaml
```

Verify backend deployment:
```bash
# Check deployment
kubectl get deployment -n backend

# Check pods
kubectl get pods -n backend

# Check service
kubectl get service -n backend

# Check logs
kubectl logs -n backend -l app=backend-api

# Test backend health
kubectl port-forward -n backend service/backend-api-service 8080:8080
# Then visit: http://localhost:8080/api/v1/health
```

### Step 3: Deploy Frontend

```bash
kubectl apply -f frontend-deployment.yaml
```

Verify frontend deployment:
```bash
# Check deployment
kubectl get deployment -n frontend

# Check pods
kubectl get pods -n frontend

# Check service
kubectl get service -n frontend

# Check ConfigMap
kubectl get configmap -n frontend

# Check logs
kubectl logs -n frontend -l app=frontend-app
```

### Step 4: Setup Ingress (Optional - May incur additional costs)

⚠️ **Free Tier Warning**: Ingress controllers and LoadBalancers may incur additional costs. Consider using NodePort or port-forwarding for development.

If you want external access via domain name:

**Install Nginx Ingress Controller** (if not already installed):
```bash
# For EKS/Cloud (this creates a LoadBalancer - may cost extra)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# For Minikube (free, local only)
minikube addons enable ingress
```

Update the ingress.yaml with your domain, then apply:
```bash
kubectl apply -f ingress.yaml
```

**Free Tier Alternative**: Use port-forwarding instead (see Option 2 below)

Verify ingress:
```bash
kubectl get ingress -n frontend
kubectl get ingress -n backend
kubectl describe ingress app-ingress -n frontend
```

## Access Your Application

### Option 1: Via LoadBalancer (if supported)

```bash
# Get external IP
kubectl get service frontend-app-service -n frontend

# Access via: http://<EXTERNAL-IP>
```

### Option 2: Via Port-Forward (local development)

```bash
# Forward frontend
kubectl port-forward -n frontend service/frontend-app-service 3000:80

# Forward backend (in another terminal)
kubectl port-forward -n backend service/backend-api-service 8080:8080

# Access:
# Frontend: http://localhost:3000
# Backend: http://localhost:8080/api/v1/health
```

### Option 3: Via Ingress

```bash
# Get ingress address
kubectl get ingress -n frontend

# Update your /etc/hosts file (for testing):
# <INGRESS-IP> your-domain.com
# <INGRESS-IP> api.your-domain.com

# Access:
# Frontend: http://your-domain.com
# Backend: http://api.your-domain.com/api/v1/health
```

## Monitoring and Debugging

### Check Pod Status

```bash
# All pods
kubectl get pods --all-namespaces

# Backend pods
kubectl get pods -n backend -o wide

# Frontend pods
kubectl get pods -n frontend -o wide
```

### View Logs

```bash
# Backend logs
kubectl logs -n backend -l app=backend-api --tail=50 -f

# Frontend logs
kubectl logs -n frontend -l app=frontend-app --tail=50 -f

# Specific pod logs
kubectl logs -n backend <pod-name> -f
```

### Describe Resources

```bash
# Describe deployment
kubectl describe deployment backend-api -n backend
kubectl describe deployment frontend-app -n frontend

# Describe pod
kubectl describe pod <pod-name> -n backend

# Describe service
kubectl describe service backend-api-service -n backend
```

### Execute Commands in Pod

```bash
# Get shell in backend pod
kubectl exec -it -n backend <backend-pod-name> -- /bin/sh

# Get shell in frontend pod
kubectl exec -it -n frontend <frontend-pod-name> -- /bin/sh

# Test internal connectivity from frontend to backend
kubectl exec -it -n frontend <frontend-pod-name> -- curl http://backend-api-service.backend.svc.cluster.local:8080/api/v1/health
```

### Test Internal DNS Resolution

```bash
# From frontend namespace, test backend service DNS
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -n frontend -- curl http://backend-api-service.backend.svc.cluster.local:8080/api/v1/health
```

## Scaling (Optional - requires more resources)

⚠️ **Note**: Free tier may not support multiple replicas. Only scale if you have sufficient resources.

```bash
# Scale backend (only if you have resources)
kubectl scale deployment backend-api -n backend --replicas=2

# Scale frontend (only if you have resources)
kubectl scale deployment frontend-app -n frontend --replicas=2

# Check scaling
kubectl get deployment -n backend
kubectl get pods -n backend
```

## Updates and Rolling Updates

```bash
# Update image
kubectl set image deployment/backend-api backend-api=your-registry/backend:v2 -n backend

# Check rollout status
kubectl rollout status deployment/backend-api -n backend

# Check rollout history
kubectl rollout history deployment/backend-api -n backend

# Rollback if needed
kubectl rollout undo deployment/backend-api -n backend
```

## Configuration Updates

### Update Backend ConfigMap (if you add one)

```bash
# Edit ConfigMap
kubectl edit configmap backend-config -n backend

# Restart pods to pick up changes
kubectl rollout restart deployment/backend-api -n backend
```

### Update Frontend ConfigMap

```bash
# Edit ConfigMap
kubectl edit configmap frontend-config -n frontend

# Restart pods to pick up changes
kubectl rollout restart deployment/frontend-app -n frontend
```

## Resource Monitoring

```bash
# Check resource usage
kubectl top nodes
kubectl top pods -n backend
kubectl top pods -n frontend

# Get events
kubectl get events -n backend --sort-by='.lastTimestamp'
kubectl get events -n frontend --sort-by='.lastTimestamp'
```

## Cleanup

```bash
# Delete all resources in namespaces
kubectl delete all --all -n backend
kubectl delete all --all -n frontend

# Delete namespaces (this deletes everything inside)
kubectl delete namespace backend
kubectl delete namespace frontend

# Or delete specific resources
kubectl delete -f backend-deployment.yaml
kubectl delete -f frontend-deployment.yaml
kubectl delete -f ingress.yaml
kubectl delete -f namespaces.yaml
```

## Troubleshooting

### Common Issues

1. **Pods not starting**
   ```bash
   kubectl describe pod <pod-name> -n <namespace>
   kubectl logs <pod-name> -n <namespace>
   ```

2. **Image pull errors**
   - Check image name and tag
   - Verify registry credentials
   - Add imagePullSecrets if using private registry

3. **Service not accessible**
   ```bash
   kubectl get endpoints -n backend
   kubectl get endpoints -n frontend
   ```

4. **Frontend can't reach backend**
   - Check ConfigMap has correct backend service URL
   - Verify backend service is running
   - Test DNS resolution from frontend pod

5. **Health checks failing**
   - Check liveness/readiness probe paths
   - Verify application is listening on correct port
   - Check application startup time vs initialDelaySeconds

### Get All Resources

```bash
# Backend namespace
kubectl get all -n backend

# Frontend namespace
kubectl get all -n frontend

# Across all namespaces
kubectl get all --all-namespaces
```

## Security Best Practices

1. **Use NetworkPolicies** to restrict traffic between namespaces
2. **Set resource limits** (already configured in deployments)
3. **Use secrets** for sensitive data instead of ConfigMaps
4. **Enable RBAC** for access control
5. **Use private registries** for container images
6. **Scan images** for vulnerabilities

## Resource Usage Summary (Free Tier)

**Current Configuration:**
```
Backend:
  - CPU Request: 50m (0.05 cores)
  - CPU Limit: 200m (0.2 cores)
  - Memory Request: 64Mi
  - Memory Limit: 128Mi
  - Replicas: 1

Frontend:
  - CPU Request: 50m (0.05 cores)
  - CPU Limit: 150m (0.15 cores)  
  - Memory Request: 64Mi
  - Memory Limit: 128Mi
  - Replicas: 1

Total Resources:
  - CPU Request: 100m (~10% of 1 vCPU)
  - CPU Limit: 350m (~35% of 1 vCPU)
  - Memory Request: 128Mi
  - Memory Limit: 256Mi
```

This fits comfortably on a **t3.micro** (1 vCPU, 1GB RAM) instance! 🎉

## Next Steps (Optional)

1. **Setup CI/CD** for automated deployments
2. **Add NetworkPolicies** for security
3. **Configure TLS/SSL** for Ingress
4. **Setup basic monitoring** (CloudWatch or metrics-server)
5. **Configure logging** (CloudWatch Logs)

**Note**: Skip heavy monitoring tools like Prometheus/Grafana on free tier - they consume too many resources.

## Reference Commands Quick Sheet

```bash
# Quick status check
kubectl get all -n backend && kubectl get all -n frontend

# Quick logs
kubectl logs -n backend -l app=backend-api --tail=20
kubectl logs -n frontend -l app=frontend-app --tail=20

# Quick port-forward for testing
kubectl port-forward -n frontend svc/frontend-app-service 3000:80 &
kubectl port-forward -n backend svc/backend-api-service 8080:8080 &

# Quick cleanup
kubectl delete -f .
```

## Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)

