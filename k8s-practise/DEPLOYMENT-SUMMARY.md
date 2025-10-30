# 🚀 Kubernetes Deployment Summary

## 📊 Overview

Complete Kubernetes deployment with backend API, frontend, and three background consumer workers.

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     NGINX Ingress Controller                     │
│              (Port 8080 via kubectl port-forward)                │
└────────────────────────┬────────────────────────────────────────┘
                         │
         ┌───────────────┴───────────────┐
         │                               │
         ▼                               ▼
┌─────────────────┐            ┌─────────────────┐
│    Backend API  │            │    Frontend     │
│  (2 replicas)   │            │  (2 replicas)   │
│  Port: 8080     │            │  Port: 3000     │
└─────────────────┘            └─────────────────┘
         │
         │ Same Image Base
         │
┌────────┴─────────────────────────────────────────┐
│           Background Consumer Workers             │
├───────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────┐    │
│  │  Email Processor (1 pod)                │    │
│  │  Task: email-processor                  │    │
│  └─────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────┐    │
│  │  Data Sync (1 pod)                      │    │
│  │  Task: data-sync                        │    │
│  └─────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────┐    │
│  │  Report Generator (1 pod)               │    │
│  │  Task: report-generator                 │    │
│  └─────────────────────────────────────────┘    │
└───────────────────────────────────────────────────┘
```

---

## 🎯 Deployed Components

### **1. Backend API**
- **Deployment**: `backend`
- **Replicas**: 2
- **Image**: `khoanguyen2610/backend:latest`
- **Port**: 8080
- **Endpoints**:
  - `GET /api/v1/health` - Health check
  - `GET /api/v1/users` - Get users

### **2. Frontend**
- **Deployment**: `frontend`
- **Replicas**: 2
- **Image**: `khoanguyen2610/frontend:latest`
- **Port**: 3000
- **Technology**: React + Node.js serve

### **3. Consumer Workers**

#### Email Processor
- **Deployment**: `consumer-email-processor`
- **Replicas**: 1
- **Image**: `khoanguyen2610/backend-consumer:latest`
- **Task**: `--task=email-processor`
- **Function**: Processes emails (sending, filtering, categorizing, archiving)

#### Data Sync
- **Deployment**: `consumer-data-sync`
- **Replicas**: 1
- **Image**: `khoanguyen2610/backend-consumer:latest`
- **Task**: `--task=data-sync`
- **Function**: Syncs data between systems (Database, API, File Storage, Cache)

#### Report Generator
- **Deployment**: `consumer-report-generator`
- **Replicas**: 1
- **Image**: `khoanguyen2610/backend-consumer:latest`
- **Task**: `--task=report-generator`
- **Function**: Generates reports (Daily, Weekly, Monthly, Quarterly)

---

## 🌐 Access URLs

### Via Port Forward (Current Setup)

Port forwarding is active on `localhost:8080`:

**Backend API:**
```bash
# Health check
curl -H "Host: local-api.kn-tech.com" http://localhost:8080/v1/health

# Get users
curl -H "Host: local-api.kn-tech.com" http://localhost:8080/v1/users

# Works with any version (v1, v2, v3, etc.)
curl -H "Host: local-api.kn-tech.com" http://localhost:8080/v2/endpoint
```

**Frontend:**
```bash
curl -H "Host: local.kn-tech.com" http://localhost:8080/
```

### With /etc/hosts Configuration

Add to `/etc/hosts`:
```
127.0.0.1 local-api.kn-tech.com
127.0.0.1 local.kn-tech.com
```

Then access directly:
- Backend: http://local-api.kn-tech.com:8080/v1/health
- Frontend: http://local.kn-tech.com:8080/

---

## 🔍 Monitoring & Management

### Check All Pods
```bash
kubectl get pods -n production
```

Expected output:
```
NAME                                         READY   STATUS    RESTARTS   AGE
backend-566b567869-68rzb                     1/1     Running   0          26m
backend-566b567869-wb8mw                     1/1     Running   0          26m
consumer-data-sync-5cb9557db7-88qfw          1/1     Running   0          2m
consumer-email-processor-7bfbd8489c-mjdc2    1/1     Running   0          2m
consumer-report-generator-6bb7685cd9-jg8p7   1/1     Running   0          2m
frontend-6c8b758dfd-5r7fv                    1/1     Running   0          26m
frontend-6c8b758dfd-7v98m                    1/1     Running   0          26m
```

### Check Deployments
```bash
kubectl get deployments -n production
```

### View Consumer Logs

**Email Processor:**
```bash
kubectl logs -n production -l task=email-processor --tail=20 -f
```

**Data Sync:**
```bash
kubectl logs -n production -l task=data-sync --tail=20 -f
```

**Report Generator:**
```bash
kubectl logs -n production -l task=report-generator --tail=20 -f
```

### View Backend API Logs
```bash
kubectl logs -n production -l app=backend --tail=20 -f
```

### View All Consumer Logs
```bash
kubectl logs -n production -l app=consumer --tail=50 -f
```

---

## 📈 Scaling

### Scale Backend API
```bash
kubectl scale deployment/backend --replicas=3 -n production
```

### Scale Frontend
```bash
kubectl scale deployment/frontend --replicas=3 -n production
```

### Scale Specific Consumer
```bash
# Scale email processor to 2 instances
kubectl scale deployment/consumer-email-processor --replicas=2 -n production

# Scale data sync to 3 instances
kubectl scale deployment/consumer-data-sync --replicas=3 -n production
```

---

## 🔄 Update Deployments

### Update Backend Image
```bash
docker build --target api -t khoanguyen2610/backend:v2 .
docker push khoanguyen2610/backend:v2
kubectl set image deployment/backend backend=khoanguyen2610/backend:v2 -n production
kubectl rollout status deployment/backend -n production
```

### Update Consumer Image
```bash
docker build --target consumer -t khoanguyen2610/backend-consumer:v2 .
docker push khoanguyen2610/backend-consumer:v2

# Update all consumers
kubectl set image deployment/consumer-email-processor consumer=khoanguyen2610/backend-consumer:v2 -n production
kubectl set image deployment/consumer-data-sync consumer=khoanguyen2610/backend-consumer:v2 -n production
kubectl set image deployment/consumer-report-generator consumer=khoanguyen2610/backend-consumer:v2 -n production
```

---

## 📊 Resource Usage

| Component | CPU Request | Memory Request | CPU Limit | Memory Limit |
|-----------|-------------|----------------|-----------|--------------|
| Backend (×2) | 200m | 512Mi | 1000m | 1Gi |
| Frontend (×2) | 200m | 256Mi | 600m | 512Mi |
| Email Processor | 50m | 128Mi | 200m | 256Mi |
| Data Sync | 50m | 128Mi | 200m | 256Mi |
| Report Generator | 50m | 128Mi | 200m | 256Mi |
| **Total** | **~550m** | **~1.15Gi** | **~2.6 CPU** | **~2.3Gi** |

---

## 🗂️ File Structure

```
k8s-practise/k8s/
├── 0-init-cluster/
│   ├── namespace.yaml
│   ├── storageclass.yaml
│   ├── registry-secret.yaml
│   └── nginx-ingress.yaml
│
├── 1-platform/
│   ├── monitoring/
│   ├── logging/
│   ├── database/
│   └── redis/
│
└── 2-apps/
    ├── backend/
    │   ├── configmap.yaml
    │   ├── deployment.yaml
    │   ├── service.yaml
    │   ├── ingress.yaml
    │   ├── consumer-email-processor-deployment.yaml
    │   ├── consumer-data-sync-deployment.yaml
    │   └── consumer-report-generator-deployment.yaml
    │
    └── frontend/
        ├── configmap.yaml
        ├── deployment.yaml
        ├── service.yaml
        └── ingress.yaml
```

---

## ✅ Verification Commands

### Test Backend API
```bash
# Health check
curl -H "Host: local-api.kn-tech.com" http://localhost:8080/v1/health

# Get users
curl -H "Host: local-api.kn-tech.com" http://localhost:8080/v1/users | jq
```

### Test Consumers
```bash
# Watch email processor logs
kubectl logs -n production -l task=email-processor -f

# Watch data sync logs  
kubectl logs -n production -l task=data-sync -f

# Watch report generator logs
kubectl logs -n production -l task=report-generator -f
```

### Check Ingress
```bash
kubectl get ingress -n production
kubectl describe ingress backend-ingress -n production
```

---

## 🧹 Cleanup

### Delete All Consumers
```bash
kubectl delete deployment consumer-email-processor -n production
kubectl delete deployment consumer-data-sync -n production
kubectl delete deployment consumer-report-generator -n production
```

### Delete Everything
```bash
kubectl delete namespace production
```

---

## 🎯 Next Steps

1. **Add Monitoring**:
   - Deploy Prometheus metrics
   - Add Grafana dashboards
   - Monitor consumer performance

2. **Add Database**:
   - Deploy PostgreSQL
   - Connect consumers to real database
   - Add data persistence

3. **Add Message Queue**:
   - Deploy Redis or RabbitMQ
   - Implement proper task queuing
   - Add retry logic

4. **Add CI/CD**:
   - GitHub Actions workflow
   - Automatic image building
   - Automatic deployment

5. **Production Readiness**:
   - Add health checks
   - Configure horizontal pod autoscaling
   - Set up backup strategies
   - Implement proper logging

---

**Status**: ✅ All systems operational!
**Total Pods**: 7 (2 backend + 2 frontend + 3 consumers)
**Namespace**: `production`
**Cluster**: Minikube (local)

