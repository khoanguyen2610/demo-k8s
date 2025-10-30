# 📊 Monitoring & Logging Guide

## ✅ Deployed Services

### **Monitoring** (fully operational)
✅ **Prometheus** - Metrics collection and storage  
✅ **Grafana** - Visualization and dashboards  

### **Logging** (partially deployed)
✅ **Promtail** - Log collection (3 DaemonSets running)  
⚠️ **Loki** - Log aggregation (pending permission fix)

---

## 🚀 Quick Access

### Grafana Dashboard
**URL**: http://localhost:3000

```bash
# Already port-forwarded and running!
open http://localhost:3000
```

**Default Credentials**:
- Username: `admin`
- Password: `admin`

### Prometheus UI
**URL**: http://localhost:9090

```bash
# Already port-forwarded and running!
open http://localhost:9090
```

---

## 📊 Using Grafana

### Step 1: Login
1. Open http://localhost:3000
2. Login with `admin/admin`
3. Skip or change password

### Step 2: Prometheus Datasource (Pre-configured!)
Grafana is already configured to use Prometheus automatically:
- **Name**: Prometheus
- **URL**: http://prometheus:9090
- **Status**: ✅ Connected

### Step 3: Create Your First Dashboard

#### Quick Dashboard - Pod Metrics
1. Click **"+"** → **"Dashboard"** → **"Add visualization"**
2. Select **"Prometheus"** datasource
3. Try these queries:

**CPU Usage by Pod:**
```promql
rate(container_cpu_usage_seconds_total{namespace="production"}[5m])
```

**Memory Usage by Pod:**
```promql
container_memory_usage_bytes{namespace="production"} / 1024 / 1024
```

**Pod Count:**
```promql
count(kube_pod_info{namespace="production"})
```

**HTTP Request Rate:**
```promql
rate(nginx_ingress_controller_requests[5m])
```

### Step 4: Import Pre-built Dashboards

1. Click **"+"** → **"Import"**
2. Enter dashboard ID:

**Popular Kubernetes Dashboards:**
- **6417** - Kubernetes Cluster Monitoring
- **8588** - Kubernetes Deployment Statefulset Daemonset metrics
- **9797** - NGINX Ingress Controller
- **12006** - Kubernetes API Server

3. Click **"Load"**
4. Select **Prometheus** datasource
5. Click **"Import"**

---

## 🔍 Using Prometheus

### Access Prometheus UI
```bash
open http://localhost:9090
```

### Useful Queries

#### Application Metrics

**Backend API Requests:**
```promql
rate(http_requests_total{job="backend"}[5m])
```

**Pod CPU Usage:**
```promql
sum(rate(container_cpu_usage_seconds_total{namespace="production"}[5m])) by (pod)
```

**Pod Memory Usage (MB):**
```promql
sum(container_memory_usage_bytes{namespace="production"}) by (pod) / 1024 / 1024
```

**Network Traffic:**
```promql
rate(container_network_receive_bytes_total{namespace="production"}[5m])
rate(container_network_transmit_bytes_total{namespace="production"}[5m])
```

#### Kubernetes Metrics

**Running Pods:**
```promql
kube_pod_status_phase{namespace="production", phase="Running"}
```

**Pod Restart Count:**
```promql
kube_pod_container_status_restarts_total{namespace="production"}
```

**Deployment Replicas:**
```promql
kube_deployment_status_replicas{namespace="production"}
```

#### NGINX Ingress Metrics

**Request Rate:**
```promql
rate(nginx_ingress_controller_requests[5m])
```

**Request Duration (95th percentile):**
```promql
histogram_quantile(0.95, rate(nginx_ingress_controller_request_duration_seconds_bucket[5m]))
```

**Error Rate:**
```promql
rate(nginx_ingress_controller_requests{status=~"5.."}[5m])
```

---

## 📈 Monitoring Your Apps

### Add Metrics to Your Application

#### Backend (Go) Example
```go
import (
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
    httpRequests = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "http_requests_total",
            Help: "Total HTTP requests",
        },
        []string{"method", "endpoint", "status"},
    )
)

func init() {
    prometheus.MustRegister(httpRequests)
}

// In your main.go
http.Handle("/metrics", promhttp.Handler())
```

#### Add Prometheus Annotations to Deployment
```yaml
spec:
  template:
    metadata:
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
```

---

## 🔧 Configuration

### View Prometheus Config
```bash
kubectl get configmap prometheus-config -n monitoring -o yaml
```

### View Grafana Datasources
```bash
kubectl get configmap grafana-datasources -n monitoring -o yaml
```

### Check Service Status
```bash
# Monitoring namespace
kubectl get all -n monitoring

# Check pods
kubectl get pods -n monitoring
```

---

## 📊 Current Metrics Available

### Kubernetes Metrics (Auto-discovered)
✅ Pod metrics (CPU, memory, network)  
✅ Node metrics  
✅ Deployment metrics  
✅ Service metrics  
✅ NGINX Ingress metrics  

### Application Metrics
To collect custom metrics:
1. Add Prometheus client library to your app
2. Expose `/metrics` endpoint
3. Add Prometheus annotations to pod spec

---

## 🎯 Alerting (Optional)

### Create Alert Rules

Add to `prometheus-config.yaml`:
```yaml
data:
  alerts.yml: |
    groups:
      - name: example
        rules:
          - alert: HighPodMemory
            expr: container_memory_usage_bytes{namespace="production"} > 500000000
            for: 5m
            labels:
              severity: warning
            annotations:
              summary: "High memory usage on {{ $labels.pod }}"
              
          - alert: PodDown
            expr: kube_pod_status_phase{namespace="production", phase="Running"} == 0
            for: 5m
            labels:
              severity: critical
            annotations:
              summary: "Pod {{ $labels.pod }} is down"
```

---

## 📱 Grafana Features

### Dashboards
- Create custom dashboards
- Import community dashboards
- Share dashboards with team

### Alerts
- Set up alert rules
- Configure notification channels (Slack, Email, etc.)
- View alert history

### Explore
- Ad-hoc query interface
- Quick data exploration
- Log correlation (when Loki is fixed)

### Users & Teams
- Add team members
- Set permissions
- Create organizations

---

## 🔄 Logging (Promtail + Loki)

### Current Status

✅ **Promtail**: Running on all nodes, collecting logs  
⚠️ **Loki**: Needs volume permissions fix

### View Collected Logs (via Promtail)

```bash
# Check Promtail status
kubectl get pods -n logging -l app=promtail

# View Promtail logs
kubectl logs -n logging -l app=promtail -f
```

### Fix Loki (Optional)

To fix Loki's permission issue, add volume mounts:

```yaml
# In loki deployment
volumeMounts:
  - name: wal
    mountPath: /wal
  - name: storage
    mountPath: /tmp/loki
volumes:
  - name: wal
    emptyDir: {}
  - name: storage
    emptyDir: {}
```

Or use a PersistentVolumeClaim for production.

---

## 🌐 Expose Grafana Publicly (Optional)

### Via Cloudflare Tunnel

Add to `~/.cloudflared/config.yml`:
```yaml
ingress:
  - hostname: grafana.kn-tech.click
    service: http://localhost:3000
  # ... other services
```

### Via Ingress

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: grafana-ingress
  namespace: monitoring
spec:
  ingressClassName: nginx
  rules:
    - host: grafana.local.kn-tech.click
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: grafana
                port:
                  number: 3000
```

---

## 🔍 Troubleshooting

### Grafana Won't Load
```bash
# Check pod status
kubectl get pods -n monitoring

# Check logs
kubectl logs -n monitoring -l app=grafana

# Restart
kubectl rollout restart deployment/grafana -n monitoring
```

### Prometheus No Data
```bash
# Check Prometheus targets
# Go to: http://localhost:9090/targets

# Check pod logs
kubectl logs -n monitoring -l app=prometheus

# Verify scrape config
kubectl describe configmap prometheus-config -n monitoring
```

### Port Forward Not Working
```bash
# Kill existing port forwards
pkill -f "port-forward.*monitoring"

# Restart Grafana port forward
kubectl port-forward -n monitoring service/grafana 3000:3000 &

# Restart Prometheus port forward
kubectl port-forward -n monitoring service/prometheus 9090:9090 &
```

---

## 📚 Quick Command Reference

```bash
# Access Grafana
open http://localhost:3000

# Access Prometheus
open http://localhost:9090

# Check monitoring pods
kubectl get pods -n monitoring

# Check logging pods
kubectl get pods -n logging

# View Grafana logs
kubectl logs -n monitoring -l app=grafana -f

# View Prometheus logs
kubectl logs -n monitoring -l app=prometheus -f

# View Promtail logs
kubectl logs -n logging -l app=promtail -f

# Restart Grafana
kubectl rollout restart deployment/grafana -n monitoring

# Restart Prometheus
kubectl rollout restart deployment/prometheus -n monitoring

# Delete monitoring (cleanup)
kubectl delete namespace monitoring

# Delete logging (cleanup)
kubectl delete namespace logging
```

---

## 🎯 Next Steps

1. **✅ Login to Grafana**: http://localhost:3000 (admin/admin)
2. **✅ Check Prometheus**: http://localhost:9090
3. **📊 Import Dashboards**: Use dashboard IDs 6417, 8588, 9797, 12006
4. **🔍 Explore Metrics**: Try the PromQL queries above
5. **🔔 Set up Alerts**: Configure alert rules in Prometheus
6. **📱 Customize**: Create your own dashboards
7. **🔧 Fix Loki** (Optional): Add volume mounts for persistence

---

## ✅ Current Status

| Service | Status | URL | Credentials |
|---------|--------|-----|-------------|
| **Grafana** | ✅ Running | http://localhost:3000 | admin/admin |
| **Prometheus** | ✅ Running | http://localhost:9090 | - |
| **Promtail** | ✅ Running (3 pods) | - | - |
| **Loki** | ⚠️ Needs fix | - | - |

**Your monitoring stack is operational!** 🎉

Start exploring your metrics in Grafana! 📊

