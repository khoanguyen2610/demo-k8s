# 🌐 Public Access via Cloudflare Tunnel

## ✅ Live Public URLs

Your Kubernetes applications are now accessible worldwide via HTTPS through Cloudflare Tunnel!

### **Frontend Application**
🔗 **https://local.kn-tech.click/**

React application serving the user interface.

### **Backend API**
🔗 **https://local-api.kn-tech.click/v1/health**  
🔗 **https://local-api.kn-tech.click/v1/users**

RESTful API with versioned endpoints (supports v1, v2, v3, etc.)

---

## 🧪 Test Commands

### Frontend
```bash
# Check frontend HTML
curl https://local.kn-tech.click/

# Open in browser
open https://local.kn-tech.click/
```

### Backend API
```bash
# Health check
curl https://local-api.kn-tech.click/v1/health

# Get users (pretty print)
curl https://local-api.kn-tech.click/v1/users | jq

# Get users count
curl -s https://local-api.kn-tech.click/v1/users | jq '.total'
```

### Test with different versions
```bash
# v1 endpoint
curl https://local-api.kn-tech.click/v1/health

# v2 endpoint (if implemented)
curl https://local-api.kn-tech.click/v2/health

# v3, v4, v5... all work automatically!
curl https://local-api.kn-tech.click/v{n}/endpoint
```

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Internet (HTTPS)                    │
│         https://local.kn-tech.click                  │
│         https://local-api.kn-tech.click              │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│            Cloudflare Edge Network                   │
│         (Global CDN + DDoS Protection)               │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│              Cloudflare Tunnel                       │
│          (cloudflared on localhost:8080)             │
└────────────────────┬────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────┐
│          NGINX Ingress Controller                    │
│         (kubectl port-forward :8080)                 │
└────────────────────┬────────────────────────────────┘
                     │
         ┌───────────┴───────────┐
         │                       │
         ▼                       ▼
┌─────────────────┐    ┌─────────────────┐
│  Backend API    │    │    Frontend     │
│  (2 replicas)   │    │  (2 replicas)   │
│  Port: 8080     │    │  Port: 3000     │
└─────────────────┘    └─────────────────┘
         │
         │
┌────────┴─────────────────────────┐
│   Background Consumer Workers    │
│  • email-processor               │
│  • data-sync                     │
│  • report-generator              │
└──────────────────────────────────┘
```

---

## 🔧 Configuration Files

### Cloudflare Tunnel Config
**File**: `~/.cloudflared/config.yml`
```yaml
tunnel: demo-k8s-local-app
credentials-file: /Users/khoa.nguyen/.cloudflared/3370c511-67ca-4bde-99de-28f22348a06e.json

ingress:
  - hostname: local.kn-tech.click
    service: http://localhost:8080
  - hostname: local-api.kn-tech.click
    service: http://localhost:8080
  - service: http_status:404
```

### Backend Ingress
**File**: `k8s/2-apps/backend/ingress.yaml`
```yaml
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

### Frontend Ingress
**File**: `k8s/2-apps/frontend/ingress.yaml`
```yaml
spec:
  ingressClassName: nginx
  rules:
    - host: local.kn-tech.click
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend
                port:
                  number: 80
```

---

## 🚀 Managing the Tunnel

### Check Tunnel Status
```bash
cloudflared tunnel info demo-k8s-local-app
```

### View Tunnel Logs
```bash
tail -f /tmp/cloudflared.log
```

### Restart Tunnel
```bash
# Stop existing tunnel
pkill cloudflared

# Start tunnel
cloudflared tunnel run demo-k8s-local-app > /tmp/cloudflared.log 2>&1 &
```

### Check if Tunnel is Running
```bash
ps aux | grep cloudflared
```

---

## 🔐 Security Features

✅ **HTTPS/TLS Encryption** - All traffic encrypted via Cloudflare  
✅ **DDoS Protection** - Cloudflare's global network  
✅ **No Open Ports** - No inbound firewall rules needed  
✅ **Private Origin** - Your local server remains private  
✅ **Certificate Management** - Automatic SSL certificates  

---

## 📊 Access Patterns

### Local Access (via port-forward)
```bash
curl -H "Host: local-api.kn-tech.click" http://localhost:8080/v1/health
```

### Public Access (via Cloudflare)
```bash
curl https://local-api.kn-tech.click/v1/health
```

Both methods work simultaneously!

---

## 🌍 Public Sharing

You can now share these URLs with anyone:

- **Frontend**: https://local.kn-tech.click/
- **API**: https://local-api.kn-tech.click/v1/users

They will work from anywhere in the world! 🌎

---

## 📱 Browser Testing

Open in your browser:
- https://local.kn-tech.click/
- https://local-api.kn-tech.click/v1/users

**Note**: The API will return JSON, which browsers display as raw text or formatted JSON.

---

## 🔍 Monitoring

### Check Kubernetes Ingress
```bash
kubectl get ingress -n production
```

### Check Pod Status
```bash
kubectl get pods -n production
```

### View Backend Logs
```bash
kubectl logs -n production -l app=backend -f
```

### View Frontend Logs
```bash
kubectl logs -n production -l app=frontend -f
```

### View Consumer Logs
```bash
# All consumers
kubectl logs -n production -l app=consumer -f

# Specific consumer
kubectl logs -n production -l task=email-processor -f
```

---

## 🔄 Update Workflow

When you make code changes:

1. **Build and push new image**:
```bash
cd k8s-001/backend
docker build --target api -t khoanguyen2610/backend:latest .
docker push khoanguyen2610/backend:latest
```

2. **Restart deployment**:
```bash
kubectl rollout restart deployment/backend -n production
```

3. **Verify**:
```bash
# Check pods are updated
kubectl get pods -n production

# Test via public URL
curl https://local-api.kn-tech.click/v1/health
```

---

## 🎯 Performance

### Latency Breakdown
- **Local**: ~1-5ms (direct to localhost)
- **Cloudflare**: ~50-200ms (depends on user location to Cloudflare edge)
- **Total**: Fast global access with CDN benefits

### Cloudflare Benefits
✅ Global CDN caching  
✅ Automatic HTTPS  
✅ DDoS protection  
✅ Analytics & insights  
✅ No infrastructure changes needed  

---

## 🛠️ Troubleshooting

### Tunnel Not Working
```bash
# Check if cloudflared is running
ps aux | grep cloudflared

# Check tunnel logs
tail -50 /tmp/cloudflared.log

# Restart tunnel
pkill cloudflared
cloudflared tunnel run demo-k8s-local-app > /tmp/cloudflared.log 2>&1 &
```

### 502 Bad Gateway
```bash
# Check if port-forward is active
kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8080:80

# Verify pods are running
kubectl get pods -n production
```

### DNS Not Resolving
- Wait 1-2 minutes for DNS propagation
- Clear browser cache
- Try incognito/private mode

---

## 📈 Next Steps

1. **Add Authentication**:
   - Implement JWT tokens
   - Add Cloudflare Access for SSO

2. **Add Rate Limiting**:
   - Configure Cloudflare rate limits
   - Implement API rate limiting

3. **Add Monitoring**:
   - Set up Cloudflare analytics
   - Add application metrics

4. **Custom Domain**:
   - Point your own domain to Cloudflare
   - Update tunnel configuration

---

## ✅ Status

**Tunnel**: ✅ Running  
**Backend API**: ✅ https://local-api.kn-tech.click/v1/  
**Frontend**: ✅ https://local.kn-tech.click/  
**Consumers**: ✅ 3 workers running  
**Security**: ✅ HTTPS + DDoS Protection  

**Your apps are live and accessible worldwide!** 🚀🌍

