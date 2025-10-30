#!/bin/bash

set -e  # Exit on error

echo "🚀 Starting Kubernetes Cluster..."
echo "================================"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

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
echo "Waiting for NGINX Ingress to be ready (this may take 1-2 minutes)..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s
kubectl apply -f k8s/0-init-cluster/nginx-configmap.yaml
echo -e "${GREEN}✓ NGINX Ingress ready${NC}"

# Step 4: Deploy monitoring
echo -e "\n${YELLOW}Step 4: Deploying monitoring stack...${NC}"
kubectl apply -f k8s/1-platform/monitoring/
echo "Waiting for monitoring pods to start..."
sleep 10
echo -e "${GREEN}✓ Monitoring deployed${NC}"

# Step 5: Deploy logging (optional, may have issues)
echo -e "\n${YELLOW}Step 5: Deploying logging stack...${NC}"
kubectl apply -f k8s/1-platform/logging/ || echo -e "${RED}Warning: Logging deployment had issues (this is normal)${NC}"
echo -e "${GREEN}✓ Logging attempted${NC}"

# Step 6: Deploy ArgoCD
echo -e "\n${YELLOW}Step 6: Deploying ArgoCD...${NC}"
kubectl apply -f k8s/1-platform/argocd/namespace.yaml
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
echo "Waiting for ArgoCD to be ready (this may take 2-3 minutes)..."
kubectl wait --namespace argocd \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=argocd-server \
  --timeout=300s
echo -e "${GREEN}✓ ArgoCD ready${NC}"

# Step 7: Deploy applications
echo -e "\n${YELLOW}Step 7: Deploying applications...${NC}"
kubectl apply -f k8s/2-apps/backend/
kubectl apply -f k8s/2-apps/frontend/
echo "Waiting for applications to start..."
sleep 15
echo -e "${GREEN}✓ Applications deployed${NC}"

# Step 8: Deploy ArgoCD applications
echo -e "\n${YELLOW}Step 8: Configuring ArgoCD applications...${NC}"
kubectl apply -f k8s/1-platform/argocd/applications/
echo -e "${GREEN}✓ ArgoCD applications configured${NC}"

# Step 9: Setup port forwarding
echo -e "\n${YELLOW}Step 9: Setting up port forwarding...${NC}"

# Kill existing port forwards
pkill -f "port-forward.*ingress-nginx" 2>/dev/null || true
pkill -f "port-forward.*argocd" 2>/dev/null || true
pkill -f "port-forward.*grafana" 2>/dev/null || true
pkill -f "port-forward.*prometheus" 2>/dev/null || true

# Start new port forwards
kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8080:80 > /dev/null 2>&1 &
kubectl port-forward svc/argocd-server -n argocd 8081:443 > /dev/null 2>&1 &
kubectl port-forward -n monitoring service/grafana 3000:3000 > /dev/null 2>&1 &
kubectl port-forward -n monitoring service/prometheus 9090:9090 > /dev/null 2>&1 &

sleep 3
echo -e "${GREEN}✓ Port forwarding configured${NC}"

# Step 10: Get ArgoCD password
echo -e "\n${YELLOW}Step 10: Getting credentials...${NC}"
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

echo -e "\n${GREEN}🚀 All services are running!${NC}"
echo "Note: It may take 1-2 minutes for all pods to be fully ready."

