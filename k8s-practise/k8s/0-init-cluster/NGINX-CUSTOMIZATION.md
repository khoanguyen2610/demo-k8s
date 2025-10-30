# 🔧 NGINX Ingress Controller Customization Guide

## 📋 Overview

This guide covers all methods to customize NGINX Ingress Controller in your Kubernetes cluster.

---

## Method 1: Global ConfigMap ⭐ (Applied)

**File**: `nginx-configmap.yaml`

Apply global settings that affect all ingresses:

```bash
kubectl apply -f k8s/0-init-cluster/nginx-configmap.yaml
```

### Common ConfigMap Settings

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ingress-nginx-controller
  namespace: ingress-nginx
data:
  # Proxy settings
  proxy-body-size: "100m"              # Max upload size
  proxy-connect-timeout: "600"         # Connection timeout
  proxy-read-timeout: "600"            # Read timeout
  proxy-send-timeout: "600"            # Send timeout
  
  # CORS
  enable-cors: "true"
  cors-allow-origin: "*"
  cors-allow-methods: "GET, POST, PUT, DELETE, OPTIONS"
  
  # Compression
  use-gzip: "true"
  gzip-level: "5"
  
  # Performance
  worker-processes: "auto"
  max-worker-connections: "16384"
  
  # SSL
  ssl-protocols: "TLSv1.2 TLSv1.3"
  ssl-redirect: "false"                # Force HTTPS
```

### Apply Changes
```bash
kubectl apply -f nginx-configmap.yaml

# Restart NGINX to apply (optional, usually auto-reloads)
kubectl rollout restart deployment/ingress-nginx-controller -n ingress-nginx
```

---

## Method 2: Per-Ingress Annotations

Add settings to specific ingress resources:

### Example: Backend Ingress with Custom Settings

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: backend-ingress
  namespace: production
  annotations:
    # URL Rewriting
    nginx.ingress.kubernetes.io/rewrite-target: /api/$1/$3
    nginx.ingress.kubernetes.io/use-regex: "true"
    
    # CORS
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-origin: "*"
    
    # Rate Limiting
    nginx.ingress.kubernetes.io/limit-rps: "100"
    nginx.ingress.kubernetes.io/limit-connections: "20"
    
    # Proxy Settings
    nginx.ingress.kubernetes.io/proxy-body-size: "50m"
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "300"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "300"
    
    # SSL/TLS
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
    
    # Backend Protocol
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
    
    # Custom Headers
    nginx.ingress.kubernetes.io/configuration-snippet: |
      more_set_headers "X-Custom-Header: MyValue";
      more_set_headers "X-Frame-Options: DENY";
      more_set_headers "X-Content-Type-Options: nosniff";
    
    # Websocket Support
    nginx.ingress.kubernetes.io/websocket-services: "backend"
    
    # Auth
    # nginx.ingress.kubernetes.io/auth-type: basic
    # nginx.ingress.kubernetes.io/auth-secret: basic-auth
spec:
  ingressClassName: nginx
  rules:
    - host: local-api.kn-tech.click
      http:
        paths:
          - path: /(v[0-9]+)(/|$)(.*)
            pathType: ImplementationSpecific
            backend:
              service:
                name: backend
                port:
                  number: 8080
```

---

## Method 3: Custom NGINX Snippets

Add raw NGINX configuration directly:

### Configuration Snippet (within http context)
```yaml
annotations:
  nginx.ingress.kubernetes.io/configuration-snippet: |
    # Add custom headers
    more_set_headers "X-Custom-Header: value";
    
    # IP whitelist
    allow 192.168.1.0/24;
    deny all;
    
    # Custom rate limiting
    limit_req_zone $binary_remote_addr zone=mylimit:10m rate=10r/s;
    limit_req zone=mylimit burst=20 nodelay;
```

### Server Snippet (within server context)
```yaml
annotations:
  nginx.ingress.kubernetes.io/server-snippet: |
    location /custom {
      return 200 "Custom location";
    }
```

### Location Snippet (within location context)
```yaml
annotations:
  nginx.ingress.kubernetes.io/location-snippet: |
    proxy_set_header X-Custom-Header "value";
    proxy_cache_bypass $http_upgrade;
```

---

## Method 4: Custom Error Pages

Create custom error pages:

### Step 1: Create ConfigMap with HTML
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: custom-error-pages
  namespace: ingress-nginx
data:
  404.html: |
    <!DOCTYPE html>
    <html>
    <head><title>404 - Not Found</title></head>
    <body>
      <h1>Page Not Found</h1>
      <p>The page you're looking for doesn't exist.</p>
    </body>
    </html>
  
  503.html: |
    <!DOCTYPE html>
    <html>
    <head><title>503 - Service Unavailable</title></head>
    <body>
      <h1>Service Unavailable</h1>
      <p>We're experiencing technical difficulties.</p>
    </body>
    </html>
```

### Step 2: Configure NGINX
Add to nginx-configmap.yaml:
```yaml
data:
  custom-http-errors: "404,503"
  default-backend-service: "ingress-nginx/custom-error-backend"
```

---

## Method 5: Rate Limiting

### Global Rate Limiting
In nginx-configmap.yaml:
```yaml
data:
  # Limit requests per second globally
  limit-req-status-code: "429"
  limit-conn-status-code: "429"
```

### Per-Ingress Rate Limiting
```yaml
annotations:
  # 100 requests per second
  nginx.ingress.kubernetes.io/limit-rps: "100"
  
  # 20 concurrent connections
  nginx.ingress.kubernetes.io/limit-connections: "20"
  
  # Whitelist IPs (no rate limit)
  nginx.ingress.kubernetes.io/limit-whitelist: "192.168.1.0/24,10.0.0.0/8"
```

---

## Method 6: Authentication

### Basic Auth

Step 1: Create htpasswd secret
```bash
# Create password file
htpasswd -c auth myuser

# Create secret
kubectl create secret generic basic-auth --from-file=auth -n production
```

Step 2: Add to ingress
```yaml
annotations:
  nginx.ingress.kubernetes.io/auth-type: basic
  nginx.ingress.kubernetes.io/auth-secret: basic-auth
  nginx.ingress.kubernetes.io/auth-realm: "Authentication Required"
```

### OAuth/External Auth
```yaml
annotations:
  nginx.ingress.kubernetes.io/auth-url: "https://auth.example.com/verify"
  nginx.ingress.kubernetes.io/auth-signin: "https://auth.example.com/login"
```

---

## Method 7: SSL/TLS Configuration

### Force HTTPS
```yaml
annotations:
  nginx.ingress.kubernetes.io/ssl-redirect: "true"
  nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
```

### Custom SSL Certificate
```bash
# Create TLS secret
kubectl create secret tls my-tls-cert \
  --cert=path/to/cert.crt \
  --key=path/to/cert.key \
  -n production
```

```yaml
spec:
  tls:
    - hosts:
        - local-api.kn-tech.click
      secretName: my-tls-cert
```

---

## Method 8: Load Balancing Algorithms

```yaml
annotations:
  # Load balancing method
  nginx.ingress.kubernetes.io/upstream-hash-by: "$request_uri"
  
  # Session affinity (sticky sessions)
  nginx.ingress.kubernetes.io/affinity: "cookie"
  nginx.ingress.kubernetes.io/session-cookie-name: "route"
  nginx.ingress.kubernetes.io/session-cookie-expires: "172800"
  nginx.ingress.kubernetes.io/session-cookie-max-age: "172800"
```

---

## Method 9: Caching

### Enable Response Caching
```yaml
annotations:
  nginx.ingress.kubernetes.io/configuration-snippet: |
    proxy_cache my_cache;
    proxy_cache_valid 200 302 10m;
    proxy_cache_valid 404 1m;
    add_header X-Cache-Status $upstream_cache_status;
```

In ConfigMap:
```yaml
data:
  proxy-buffering: "on"
  proxy-cache-path: "/tmp/nginx-cache levels=1:2 keys_zone=my_cache:10m max_size=1g inactive=60m"
```

---

## Method 10: Monitoring & Logging

### Custom Log Format
In nginx-configmap.yaml:
```yaml
data:
  log-format-upstream: >
    $remote_addr - $remote_user [$time_local] "$request"
    $status $body_bytes_sent "$http_referer" "$http_user_agent"
    $request_time $upstream_response_time
```

### Access Logs
```yaml
data:
  access-log-path: "/var/log/nginx/access.log"
  error-log-path: "/var/log/nginx/error.log"
  error-log-level: "warn"
```

---

## 🚀 Quick Examples

### Example 1: API with Rate Limiting
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api-ingress
  annotations:
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/limit-rps: "10"
    nginx.ingress.kubernetes.io/limit-connections: "5"
```

### Example 2: Frontend with Caching
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: frontend-ingress
  annotations:
    nginx.ingress.kubernetes.io/configuration-snippet: |
      expires 7d;
      add_header Cache-Control "public, immutable";
```

### Example 3: WebSocket Support
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: websocket-ingress
  annotations:
    nginx.ingress.kubernetes.io/websocket-services: "ws-service"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"
```

---

## 🔍 Verification

### Check Applied Configuration
```bash
# View ConfigMap
kubectl get configmap ingress-nginx-controller -n ingress-nginx -o yaml

# View NGINX config (inside pod)
kubectl exec -n ingress-nginx \
  $(kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller -o name | head -1) \
  -- cat /etc/nginx/nginx.conf

# Test configuration
kubectl exec -n ingress-nginx \
  $(kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller -o name | head -1) \
  -- nginx -t
```

### View Logs
```bash
# Controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller -f

# Access logs
kubectl exec -n ingress-nginx \
  $(kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller -o name | head -1) \
  -- tail -f /var/log/nginx/access.log
```

---

## 📚 Common ConfigMap Keys Reference

| Key | Description | Example |
|-----|-------------|---------|
| `proxy-body-size` | Max request body size | `100m` |
| `proxy-connect-timeout` | Backend connection timeout | `600` |
| `proxy-read-timeout` | Backend read timeout | `600` |
| `proxy-send-timeout` | Backend send timeout | `600` |
| `use-gzip` | Enable gzip compression | `true` |
| `gzip-level` | Compression level (1-9) | `5` |
| `ssl-protocols` | Allowed SSL/TLS versions | `TLSv1.2 TLSv1.3` |
| `ssl-redirect` | Force HTTPS | `true` |
| `enable-cors` | Enable CORS | `true` |
| `cors-allow-origin` | CORS allowed origins | `*` |
| `use-http2` | Enable HTTP/2 | `true` |
| `worker-processes` | Number of worker processes | `auto` |
| `max-worker-connections` | Max connections per worker | `16384` |

Full reference: https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/

---

## 📝 Annotation Reference

| Annotation | Description | Example |
|------------|-------------|---------|
| `nginx.ingress.kubernetes.io/rewrite-target` | URL rewriting | `/api/$1` |
| `nginx.ingress.kubernetes.io/ssl-redirect` | Force HTTPS | `true` |
| `nginx.ingress.kubernetes.io/limit-rps` | Rate limit (req/sec) | `100` |
| `nginx.ingress.kubernetes.io/proxy-body-size` | Max upload size | `50m` |
| `nginx.ingress.kubernetes.io/enable-cors` | Enable CORS | `true` |
| `nginx.ingress.kubernetes.io/auth-type` | Auth type | `basic` |
| `nginx.ingress.kubernetes.io/configuration-snippet` | Custom NGINX config | See examples |
| `nginx.ingress.kubernetes.io/backend-protocol` | Backend protocol | `HTTP`, `HTTPS`, `GRPC` |

Full reference: https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/

---

## ✅ Your Current Setup

✅ ConfigMap applied with optimized settings  
✅ CORS enabled globally  
✅ Compression enabled  
✅ Reasonable timeouts configured  
✅ HTTP/2 enabled  

**Changes are active!** NGINX auto-reloads configuration.

---

## 🔄 Apply Custom Settings

1. **Edit ConfigMap**:
   ```bash
   kubectl edit configmap ingress-nginx-controller -n ingress-nginx
   ```

2. **Or update file and reapply**:
   ```bash
   kubectl apply -f k8s/0-init-cluster/nginx-configmap.yaml
   ```

3. **Verify**:
   ```bash
   kubectl describe configmap ingress-nginx-controller -n ingress-nginx
   ```

**Configuration reloads automatically!** 🚀

