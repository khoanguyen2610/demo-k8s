# 🧭 Kubernetes Cluster Setup Structure — Best Practice

This guide provides a clear, modular structure for managing Kubernetes manifests from scratch — covering cluster initialization, shared platform components, and individual application deployments.

---

## 📁 Folder Structure

```
k8s/
├── 0-init-cluster/
│   ├── namespace.yaml
│   ├── storageclass.yaml
│   ├── registry-secret.yaml        # docker credentials (for private images)
│   └── nginx-ingress.yaml          # ingress controller installation (nginx)
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

## ⚙️ Cluster Initialization (`0-init-cluster`)

### **namespace.yaml**

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
```

---

### **registry-secret.yaml**

Used for pulling private Docker images (e.g., from DockerHub, GitHub, GitLab registry).

#### ✅ Option A — via CLI (Recommended)
```bash
kubectl create secret docker-registry regcred   --docker-server=https://index.docker.io/v1/   --docker-username=$DOCKER_USER   --docker-password=$DOCKER_PASS   --docker-email=$DOCKER_EMAIL   --namespace=production
```

#### 🧾 Option B — via YAML

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: regcred
  namespace: production
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: <base64-encoded-json>
```

You can generate the value via:
```bash
cat ~/.docker/config.json | base64 -w0
```

---

### **nginx-ingress.yaml**
(Example for a single NGINX ingress controller)

```yaml
apiVersion: helm.cattle.io/v1
kind: HelmChart
metadata:
  name: nginx-ingress
  namespace: kube-system
spec:
  chart: ingress-nginx
  repo: https://kubernetes.github.io/ingress-nginx
  targetNamespace: ingress-nginx
  version: 4.9.0
```

---

## 🧩 Platform Components (`1-platform`)

Optional shared services — installed once, reused by multiple apps.

| Component | Purpose | Notes |
|------------|----------|-------|
| **Prometheus / Grafana** | Monitoring | Basic cluster and app metrics |
| **Loki / Promtail** | Logging | Collect & visualize logs |
| **Postgres / Redis** | Shared data stores | Used by backend services |

Each subfolder (`monitoring/`, `database/`, etc.) includes its own deployment YAMLs.

---

## 🚀 Application Deployment (`2-apps`)

Each app is **self-contained**, with its own configuration and ingress.

---

### Example: **Backend Service**

#### `2-apps/backend/deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: production
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      imagePullSecrets:
        - name: regcred
      containers:
        - name: backend
          image: your-dockerhub-user/backend:latest
          ports:
            - containerPort: 8080
          envFrom:
            - configMapRef:
                name: backend-config
          resources:
            requests:
              cpu: 100m
              memory: 256Mi
            limits:
              cpu: 500m
              memory: 512Mi
```

---

#### `2-apps/backend/configmap.yaml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: backend-config
  namespace: production
data:
  DATABASE_URL: "postgres://postgres:password@postgres:5432/app"
  REDIS_URL: "redis://redis:6379"
```

---

#### `2-apps/backend/service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend
  namespace: production
spec:
  selector:
    app: backend
  ports:
    - port: 8080
      targetPort: 8080
  type: ClusterIP
```

---

#### `2-apps/backend/ingress.yaml`

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: backend-ingress
  namespace: production
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - host: api.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: backend
                port:
                  number: 8080
```

---

### Example: **Frontend Service**

Same structure, different host and config.

#### `2-apps/frontend/configmap.yaml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: frontend-config
  namespace: production
data:
  API_BASE_URL: "https://api.example.com"
```

---

## 🧱 Apply All Resources

```bash
# 1. Init cluster
kubectl apply -f k8s/0-init-cluster/

# 2. Deploy platform dependencies
kubectl apply -f k8s/1-platform/

# 3. Deploy applications
kubectl apply -f k8s/2-apps/backend/
kubectl apply -f k8s/2-apps/frontend/
```

---

## 🔄 CI/CD Integration (GitHub or GitLab)

### Example: GitHub Actions step

```yaml
- name: Create image pull secret
  run: |
    kubectl create secret docker-registry regcred       --docker-server=https://index.docker.io/v1/       --docker-username=${{ secrets.DOCKER_USER }}       --docker-password=${{ secrets.DOCKER_PASS }}       --docker-email=ci@example.com       --namespace=production       --dry-run=client -o yaml | kubectl apply -f -
```

Then apply manifests automatically after building and pushing your images.

---

## ✅ Summary

| Area | Purpose | Notes |
|------|----------|-------|
| `0-init-cluster/` | Cluster bootstrap (namespace, registry, ingress) | Run first |
| `1-platform/` | Shared services (DB, monitoring, logging) | Optional |
| `2-apps/` | Independent app deployments | Each has configmap, svc, ingress |
| `imagePullSecrets` | Docker credentials | Used by all pods |
| `CI/CD` | Automate updates and secret management | via GitHub/GitLab pipelines |
