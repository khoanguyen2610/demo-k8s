#!/bin/bash

###############################################################################
# Deployment Verification Script
# Checks if backend and frontend are properly deployed and healthy
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

FAILED_CHECKS=0

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
    FAILED_CHECKS=$((FAILED_CHECKS + 1))
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl not found"
        exit 1
    fi
    print_success "kubectl is available"
}

# Check cluster connection
check_cluster() {
    print_header "Checking Cluster Connection"
    
    if kubectl cluster-info &> /dev/null; then
        print_success "Connected to Kubernetes cluster"
        kubectl cluster-info | head -1
    else
        print_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi
}

# Check namespaces
check_namespaces() {
    print_header "Checking Namespaces"
    
    for ns in backend frontend; do
        if kubectl get namespace $ns &> /dev/null; then
            print_success "Namespace '$ns' exists"
        else
            print_error "Namespace '$ns' not found"
        fi
    done
}

# Check deployments
check_deployments() {
    print_header "Checking Deployments"
    
    echo ""
    print_info "Backend Deployment:"
    if kubectl get deployment backend-api -n backend &> /dev/null; then
        BACKEND_REPLICAS=$(kubectl get deployment backend-api -n backend -o jsonpath='{.status.availableReplicas}')
        BACKEND_DESIRED=$(kubectl get deployment backend-api -n backend -o jsonpath='{.spec.replicas}')
        
        if [ "$BACKEND_REPLICAS" == "$BACKEND_DESIRED" ]; then
            print_success "Backend deployment is ready ($BACKEND_REPLICAS/$BACKEND_DESIRED replicas)"
        else
            print_error "Backend deployment not ready ($BACKEND_REPLICAS/$BACKEND_DESIRED replicas)"
        fi
        
        kubectl get deployment backend-api -n backend
    else
        print_error "Backend deployment not found"
    fi
    
    echo ""
    print_info "Frontend Deployment:"
    if kubectl get deployment frontend-app -n frontend &> /dev/null; then
        FRONTEND_REPLICAS=$(kubectl get deployment frontend-app -n frontend -o jsonpath='{.status.availableReplicas}')
        FRONTEND_DESIRED=$(kubectl get deployment frontend-app -n frontend -o jsonpath='{.spec.replicas}')
        
        if [ "$FRONTEND_REPLICAS" == "$FRONTEND_DESIRED" ]; then
            print_success "Frontend deployment is ready ($FRONTEND_REPLICAS/$FRONTEND_DESIRED replicas)"
        else
            print_error "Frontend deployment not ready ($FRONTEND_REPLICAS/$FRONTEND_DESIRED replicas)"
        fi
        
        kubectl get deployment frontend-app -n frontend
    else
        print_error "Frontend deployment not found"
    fi
}

# Check pods
check_pods() {
    print_header "Checking Pods"
    
    echo ""
    print_info "Backend Pods:"
    kubectl get pods -n backend
    
    BACKEND_RUNNING=$(kubectl get pods -n backend -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' | wc -w)
    if [ "$BACKEND_RUNNING" -gt 0 ]; then
        print_success "$BACKEND_RUNNING backend pod(s) running"
    else
        print_error "No backend pods running"
    fi
    
    echo ""
    print_info "Frontend Pods:"
    kubectl get pods -n frontend
    
    FRONTEND_RUNNING=$(kubectl get pods -n frontend -o jsonpath='{.items[?(@.status.phase=="Running")].metadata.name}' | wc -w)
    if [ "$FRONTEND_RUNNING" -gt 0 ]; then
        print_success "$FRONTEND_RUNNING frontend pod(s) running"
    else
        print_error "No frontend pods running"
    fi
}

# Check services
check_services() {
    print_header "Checking Services"
    
    echo ""
    print_info "Backend Service:"
    if kubectl get service backend-api-service -n backend &> /dev/null; then
        print_success "Backend service exists"
        kubectl get service backend-api-service -n backend
    else
        print_error "Backend service not found"
    fi
    
    echo ""
    print_info "Frontend Service:"
    if kubectl get service frontend-app-service -n frontend &> /dev/null; then
        print_success "Frontend service exists"
        kubectl get service frontend-app-service -n frontend
    else
        print_error "Frontend service not found"
    fi
}

# Health checks
health_checks() {
    print_header "Running Health Checks"
    
    echo ""
    print_info "Backend Health Check:"
    BACKEND_IP=$(kubectl get service backend-api-service -n backend -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
    
    if [ -n "$BACKEND_IP" ]; then
        print_info "Backend service IP: $BACKEND_IP"
        
        HEALTH_CHECK=$(kubectl run health-check-backend --image=curlimages/curl --rm -i --restart=Never --quiet -- \
            curl -sf http://${BACKEND_IP}:8080/api/v1/health 2>/dev/null || echo "FAILED")
        
        if [ "$HEALTH_CHECK" != "FAILED" ] && [ -n "$HEALTH_CHECK" ]; then
            print_success "Backend health check passed"
            echo "$HEALTH_CHECK" | jq '.' 2>/dev/null || echo "$HEALTH_CHECK"
        else
            print_error "Backend health check failed"
        fi
    else
        print_error "Could not get backend service IP"
    fi
    
    echo ""
    print_info "Frontend Health Check:"
    FRONTEND_IP=$(kubectl get service frontend-app-service -n frontend -o jsonpath='{.spec.clusterIP}' 2>/dev/null)
    
    if [ -n "$FRONTEND_IP" ]; then
        print_info "Frontend service IP: $FRONTEND_IP"
        
        HTTP_CODE=$(kubectl run health-check-frontend --image=curlimages/curl --rm -i --restart=Never --quiet -- \
            curl -sf -o /dev/null -w "%{http_code}" http://${FRONTEND_IP}:80 2>/dev/null || echo "000")
        
        if [ "$HTTP_CODE" == "200" ]; then
            print_success "Frontend health check passed (HTTP $HTTP_CODE)"
        else
            print_error "Frontend health check failed (HTTP $HTTP_CODE)"
        fi
    else
        print_error "Could not get frontend service IP"
    fi
}

# Check recent events
check_events() {
    print_header "Recent Events"
    
    echo ""
    print_info "Backend Events (last 10):"
    kubectl get events -n backend --sort-by='.lastTimestamp' | tail -10
    
    echo ""
    print_info "Frontend Events (last 10):"
    kubectl get events -n frontend --sort-by='.lastTimestamp' | tail -10
}

# Check pod logs
check_logs() {
    print_header "Recent Logs"
    
    echo ""
    print_info "Backend Logs (last 20 lines):"
    kubectl logs -n backend deployment/backend-api --tail=20 2>/dev/null || print_warning "Could not fetch backend logs"
    
    echo ""
    print_info "Frontend Logs (last 20 lines):"
    kubectl logs -n frontend deployment/frontend-app --tail=20 2>/dev/null || print_warning "Could not fetch frontend logs"
}

# Check resource usage
check_resources() {
    print_header "Resource Usage"
    
    echo ""
    print_info "Node Resources:"
    kubectl top nodes 2>/dev/null || print_warning "Metrics not available (metrics-server not installed?)"
    
    echo ""
    print_info "Pod Resources:"
    echo "Backend:"
    kubectl top pods -n backend 2>/dev/null || print_warning "Metrics not available"
    
    echo ""
    echo "Frontend:"
    kubectl top pods -n frontend 2>/dev/null || print_warning "Metrics not available"
}

# Summary
print_summary() {
    print_header "Verification Summary"
    
    echo ""
    if [ $FAILED_CHECKS -eq 0 ]; then
        print_success "All checks passed! ✨"
        echo ""
        print_info "Your deployment is healthy and ready to use."
    else
        print_error "$FAILED_CHECKS check(s) failed"
        echo ""
        print_warning "Please review the errors above and fix any issues."
        echo ""
        print_info "Common fixes:"
        echo "  - Check pod logs: kubectl logs -n <namespace> <pod-name>"
        echo "  - Describe pod: kubectl describe pod -n <namespace> <pod-name>"
        echo "  - Check events: kubectl get events -n <namespace>"
    fi
    
    echo ""
    print_info "Access your services:"
    echo "  Backend:  kubectl port-forward -n backend svc/backend-api-service 8080:8080"
    echo "  Frontend: kubectl port-forward -n frontend svc/frontend-app-service 8080:80"
    echo ""
    echo "  Then visit:"
    echo "  - Backend API:  http://localhost:8080/api/v1/health"
    echo "  - Frontend App: http://localhost:8080"
}

# Main execution
main() {
    clear
    print_header "Deployment Verification"
    echo ""
    
    check_kubectl
    check_cluster
    echo ""
    
    check_namespaces
    echo ""
    
    check_deployments
    echo ""
    
    check_pods
    echo ""
    
    check_services
    echo ""
    
    health_checks
    echo ""
    
    check_events
    echo ""
    
    check_logs
    echo ""
    
    check_resources
    echo ""
    
    print_summary
    
    # Exit with error if checks failed
    if [ $FAILED_CHECKS -gt 0 ]; then
        exit 1
    fi
}

# Run main
main

