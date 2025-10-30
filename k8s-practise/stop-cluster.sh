#!/bin/bash

echo "🛑 Stopping Kubernetes Cluster..."
echo "================================"

# Colors
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# Stop port forwards
echo -e "\n${YELLOW}Stopping port forwards...${NC}"
pkill -f "port-forward.*ingress-nginx" 2>/dev/null || true
pkill -f "port-forward.*argocd" 2>/dev/null || true
pkill -f "port-forward.*grafana" 2>/dev/null || true
pkill -f "port-forward.*prometheus" 2>/dev/null || true
echo -e "${GREEN}✓ Port forwards stopped${NC}"

# Stop cloudflared (if running)
echo -e "\n${YELLOW}Stopping Cloudflare tunnel...${NC}"
pkill cloudflared 2>/dev/null || true
echo -e "${GREEN}✓ Cloudflare tunnel stopped${NC}"

# Stop Minikube
echo -e "\n${YELLOW}Stopping Minikube...${NC}"
minikube stop
echo -e "${GREEN}✓ Minikube stopped${NC}"

echo -e "\n${GREEN}================================${NC}"
echo -e "${GREEN}✓ Cluster stopped successfully!${NC}"
echo -e "${GREEN}================================${NC}"

echo -e "\n📝 ${YELLOW}To start again:${NC}"
echo "  cd /Users/khoa.nguyen/Workings/Personal/devops/k8s-practise"
echo "  ./start-cluster.sh"

