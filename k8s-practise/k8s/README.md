# 🧭 Kubernetes Cluster Setup Structure

This repository provides a complete, modular structure for managing Kubernetes manifests from scratch — covering cluster initialization, shared platform components, and individual application deployments.

---

## 📁 Folder Structure

```
k8s/
├── 0-init-cluster/
│   ├── namespace.yaml
│   ├── storageclass.yaml
│   ├── registry-secret.yaml
│   └── nginx-ingress.yaml
│
├── 1-platform/
│   ├── monitoring/
│   │   ├── prometheus.yaml
│   │   └── grafana.yaml
│   ├── logging/
│   │   ├── loki.yaml
│   │   └── promtail.yaml
│   ├── database/
│   │   └── postgres.yaml
│   └── redis/
│       └── redis.yaml
│
├── 2-apps/
│   ├── frontend/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   ├── ingress.yaml
│   │   └── configmap.yaml
│   │
│   └── backend/
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── ingress.yaml
│       └── configmap.yaml
│
└── README.md
```

---

## 🚀 Quick Start

### Prerequisites

- Kubernetes cluster (local or cloud)
- kubectl configured and connected to your cluster
- Docker credentials (for private image registries)

### Deployment Steps

#### 1. Initialize Cluster

Deploy cluster-level resources including namespaces, storage classes, registry credentials, and ingress controller:

```bash
# Create the production namespace
kubectl apply -f k8s/0-init-cluster/namespace.yaml

# Create storage class
kubectl apply -f k8s/0-init-cluster/storageclass.yaml

# Create registry secret for pulling private images
# Option A: Via CLI (recommended)
kubectl create secret docker-registry regcred \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=$DOCKER_USER \
  --docker-password=$DOCKER_PASS \
  --docker-email=$DOCKER_EMAIL \
  --namespace=production

# Option B: Via YAML (update credentials first)
kubectl apply -f k8s/0-init-cluster/registry-secret.yaml

# Install NGINX Ingress Controller
kubectl apply -f k8s/0-init-cluster/nginx-ingress.yaml

# Verify ingress controller is running
kubectl get pods -n ingress-nginx
```

#### 2. Deploy Platform Components

Deploy shared services that applications will use:

```bash
# Deploy monitoring stack (Prometheus + Grafana)
kubectl apply -f k8s/1-platform/monitoring/

# Deploy logging stack (Loki + Promtail)
kubectl apply -f k8s/1-platform/logging/

# Deploy PostgreSQL database
kubectl apply -f k8s/1-platform/database/

# Deploy Redis cache
kubectl apply -f k8s/1-platform/redis/

# Verify platform components are running
kubectl get pods -n monitoring
kubectl get pods -n logging
kubectl get pods -n production
```

#### 3. Deploy Applications

Deploy frontend and backend applications:

```bash
# Update image names in deployment files first
# Edit: k8s/2-apps/backend/deployment.yaml
# Edit: k8s/2-apps/frontend/deployment.yaml

# Deploy backend application
kubectl apply -f k8s/2-apps/backend/

# Deploy frontend application
kubectl apply -f k8s/2-apps/frontend/

# Verify applications are running
kubectl get pods -n production
kubectl get ingress -n production
```

#### 4. Verify Deployment

```bash
# Check all pods are running
kubectl get pods --all-namespaces

# Check services
kubectl get svc -n production

# Check ingress endpoints
kubectl get ingress -n production

# Test backend API (update host in /etc/hosts if needed)
curl https://api.example.com

# Test frontend (update host in /etc/hosts if needed)
curl https://www.example.com
```

---

## ⚙️ Component Details

### 0. Cluster Initialization

| Resource | Purpose | Notes |
|----------|---------|-------|
| **namespace.yaml** | Creates production namespace | Core namespace for apps |
| **storageclass.yaml** | Defines storage class | For PersistentVolumeClaims |
| **registry-secret.yaml** | Docker registry credentials | Required for private images |
| **nginx-ingress.yaml** | Installs ingress controller | Routes external traffic |

### 1. Platform Components

Optional shared services — installed once, reused by multiple apps.

| Component | Purpose | Access |
|-----------|---------|--------|
| **Prometheus** | Metrics collection | Internal: `prometheus:9090` |
| **Grafana** | Metrics visualization | Internal: `grafana:3000` |
| **Loki** | Log aggregation | Internal: `loki:3100` |
| **Promtail** | Log collection | DaemonSet on all nodes |
| **PostgreSQL** | Relational database | Internal: `postgres:5432` |
| **Redis** | In-memory cache | Internal: `redis:6379` |

### 2. Applications

Each app is **self-contained**, with its own configuration and ingress.

| Application | Replicas | Resources | Ingress |
|-------------|----------|-----------|---------|
| **Backend** | 2 | 100m CPU, 256Mi RAM | api.example.com |
| **Frontend** | 2 | 100m CPU, 128Mi RAM | www.example.com |

---

## 🔧 Configuration

### Update Docker Registry

Edit `k8s/2-apps/backend/deployment.yaml` and `k8s/2-apps/frontend/deployment.yaml`:

```yaml
containers:
  - name: backend
    image: your-dockerhub-user/backend:latest  # Update this
```

### Update Database Credentials

Edit `k8s/1-platform/database/postgres.yaml`:

```yaml
data:
  POSTGRES_PASSWORD: <your-base64-encoded-password>
```

Generate base64 password:
```bash
echo -n "your-password" | base64
```

### Update Application Config

Edit `k8s/2-apps/backend/configmap.yaml`:

```yaml
data:
  DATABASE_URL: "postgres://postgres:password@postgres:5432/app"
  REDIS_URL: "redis://redis:6379"
```

Edit `k8s/2-apps/frontend/configmap.yaml`:

```yaml
data:
  API_BASE_URL: "https://api.example.com"
```

### Update Ingress Hosts

Edit ingress files to use your domain:
- `k8s/2-apps/backend/ingress.yaml` - Update `api.example.com`
- `k8s/2-apps/frontend/ingress.yaml` - Update `www.example.com`

For local testing, add to `/etc/hosts`:
```
127.0.0.1 api.example.com
127.0.0.1 www.example.com
```

---

## 🔄 CI/CD Integration

### GitHub Actions Example

```yaml
name: Deploy to Kubernetes

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build and push Docker images
        run: |
          docker build -t ${{ secrets.DOCKER_USER }}/backend:${{ github.sha }} ./backend
          docker build -t ${{ secrets.DOCKER_USER }}/frontend:${{ github.sha }} ./frontend
          echo ${{ secrets.DOCKER_PASS }} | docker login -u ${{ secrets.DOCKER_USER }} --password-stdin
          docker push ${{ secrets.DOCKER_USER }}/backend:${{ github.sha }}
          docker push ${{ secrets.DOCKER_USER }}/frontend:${{ github.sha }}
      
      - name: Set up kubectl
        uses: azure/setup-kubectl@v3
      
      - name: Configure kubeconfig
        run: |
          echo "${{ secrets.KUBE_CONFIG }}" | base64 -d > kubeconfig
          export KUBECONFIG=./kubeconfig
      
      - name: Create image pull secret
        run: |
          kubectl create secret docker-registry regcred \
            --docker-server=https://index.docker.io/v1/ \
            --docker-username=${{ secrets.DOCKER_USER }} \
            --docker-password=${{ secrets.DOCKER_PASS }} \
            --docker-email=ci@example.com \
            --namespace=production \
            --dry-run=client -o yaml | kubectl apply -f -
      
      - name: Deploy to Kubernetes
        run: |
          kubectl set image deployment/backend backend=${{ secrets.DOCKER_USER }}/backend:${{ github.sha }} -n production
          kubectl set image deployment/frontend frontend=${{ secrets.DOCKER_USER }}/frontend:${{ github.sha }} -n production
          kubectl rollout status deployment/backend -n production
          kubectl rollout status deployment/frontend -n production
```

---

## 🔍 Monitoring & Debugging

### View Logs

```bash
# Application logs
kubectl logs -f deployment/backend -n production
kubectl logs -f deployment/frontend -n production

# Platform logs
kubectl logs -f deployment/prometheus -n monitoring
kubectl logs -f deployment/loki -n logging
```

### Access Services

```bash
# Port-forward Grafana
kubectl port-forward svc/grafana 3000:3000 -n monitoring
# Access at http://localhost:3000 (admin/admin)

# Port-forward Prometheus
kubectl port-forward svc/prometheus 9090:9090 -n monitoring
# Access at http://localhost:9090

# Port-forward PostgreSQL
kubectl port-forward svc/postgres 5432:5432 -n production

# Port-forward Redis
kubectl port-forward svc/redis 6379:6379 -n production
```

### Common Issues

**Pods not starting:**
```bash
kubectl describe pod <pod-name> -n production
kubectl logs <pod-name> -n production
```

**Image pull errors:**
```bash
# Verify registry secret exists
kubectl get secret regcred -n production

# Check secret content
kubectl get secret regcred -n production -o yaml
```

**Database connection issues:**
```bash
# Check PostgreSQL is running
kubectl get pods -n production | grep postgres

# Test connection from a pod
kubectl run -it --rm --image=postgres:15-alpine --namespace=production postgres-client -- psql -h postgres -U postgres -d app
```

---

## 📊 Resource Requirements

### Minimum Cluster Resources

| Component | CPU Request | Memory Request | CPU Limit | Memory Limit |
|-----------|-------------|----------------|-----------|--------------|
| Backend (×2) | 200m | 512Mi | 1000m | 1Gi |
| Frontend (×2) | 200m | 256Mi | 600m | 512Mi |
| PostgreSQL | 250m | 512Mi | 1000m | 2Gi |
| Redis | 100m | 256Mi | 500m | 512Mi |
| Prometheus | 200m | 512Mi | 1000m | 2Gi |
| Grafana | 100m | 256Mi | 500m | 512Mi |
| Loki | 100m | 256Mi | 500m | 1Gi |
| **Total** | **~1.15 CPU** | **~2.5Gi RAM** | **~5.1 CPU** | **~9Gi RAM** |

**Recommended:** 3-node cluster with 2 CPU and 4GB RAM per node minimum.

---

## 🧹 Cleanup

To remove all resources:

```bash
# Delete applications
kubectl delete -f k8s/2-apps/backend/
kubectl delete -f k8s/2-apps/frontend/

# Delete platform components
kubectl delete -f k8s/1-platform/redis/
kubectl delete -f k8s/1-platform/database/
kubectl delete -f k8s/1-platform/logging/
kubectl delete -f k8s/1-platform/monitoring/

# Delete cluster initialization resources
kubectl delete -f k8s/0-init-cluster/

# Delete namespaces (this will delete all resources in them)
kubectl delete namespace production
kubectl delete namespace monitoring
kubectl delete namespace logging
```

---

## ✅ Summary

| Area | Purpose | Deploy Order |
|------|---------|-------------|
| `0-init-cluster/` | Cluster bootstrap | 1st - Run once per cluster |
| `1-platform/` | Shared services | 2nd - Optional but recommended |
| `2-apps/` | Applications | 3rd - Your actual workloads |

### Key Features

✅ **Modular structure** - Easy to understand and maintain  
✅ **Production-ready** - Includes monitoring, logging, and resource limits  
✅ **Scalable** - Ready for horizontal scaling  
✅ **Secure** - Private registry support, proper RBAC  
✅ **Observable** - Full monitoring and logging stack  
✅ **CI/CD ready** - Easy integration with automation pipelines

---

## 📚 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
- [Prometheus Operator](https://prometheus-operator.dev/)
- [Grafana Loki](https://grafana.com/docs/loki/latest/)

---

**Happy Kubernetes Deployment! 🚀**

