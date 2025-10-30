#!/bin/bash

# Kubernetes Deployment Script
# This script deploys the DevOps application to Kubernetes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Print banner
echo ""
echo "╔════════════════════════════════════════╗"
echo "║   DevOps Kubernetes Deployment        ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Please install kubectl first."
    exit 1
fi

print_success "kubectl is installed"

# Check if we can connect to cluster
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
    exit 1
fi

print_success "Connected to Kubernetes cluster"

# Get current context
CONTEXT=$(kubectl config current-context)
print_info "Current context: $CONTEXT"
echo ""

# Ask for confirmation
read -p "Deploy to this cluster? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Deployment cancelled"
    exit 0
fi

echo ""
print_info "Starting deployment..."
echo ""

# Deploy Backend
print_info "Deploying backend (API + Consumers)..."
kubectl apply -k backend/
print_success "Backend deployed"
echo ""

# Deploy Frontend
print_info "Deploying frontend (App + Ingress)..."
kubectl apply -k frontend/
print_success "Frontend deployed"
echo ""

# Wait for deployments to be ready
print_info "Waiting for deployments to be ready..."
echo ""

print_info "Waiting for backend API..."
kubectl rollout status deployment/backend-api -n backend --timeout=120s

print_info "Waiting for frontend app..."
kubectl rollout status deployment/frontend-app -n frontend --timeout=120s

print_info "Waiting for consumers..."
kubectl wait --for=condition=ready pod -l component=consumer -n backend --timeout=120s || true

echo ""
print_success "All deployments are ready!"
echo ""

# Print status
echo "╔════════════════════════════════════════╗"
echo "║   Deployment Status                    ║"
echo "╚════════════════════════════════════════╝"
echo ""

print_info "Backend Pods:"
kubectl get pods -n backend
echo ""

print_info "Frontend Pods:"
kubectl get pods -n frontend
echo ""

print_info "Services:"
kubectl get svc -n backend
kubectl get svc -n frontend
echo ""

print_info "Ingress:"
kubectl get ingress -n frontend
echo ""

# Print access information
echo "╔════════════════════════════════════════╗"
echo "║   Access Information                   ║"
echo "╚════════════════════════════════════════╝"
echo ""
print_success "Frontend: http://kn-tech.click"
print_success "Backend API: http://api.kn-tech.click"
echo ""
print_info "API Endpoints:"
echo "  - http://api.kn-tech.click/api/v1/health"
echo "  - http://api.kn-tech.click/api/v1/users"
echo ""

print_success "Deployment completed successfully! 🚀"
echo ""

