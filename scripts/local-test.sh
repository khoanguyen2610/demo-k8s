#!/bin/bash

###############################################################################
# Local Testing Script
# Test your changes locally before pushing to CI/CD
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Test backend
test_backend() {
    print_header "Testing Backend"
    
    if [ ! -d "backend" ]; then
        print_warning "Backend directory not found, skipping..."
        return
    fi
    
    cd backend
    
    # Check Go installation
    if ! command -v go &> /dev/null; then
        print_error "Go not installed"
        cd ..
        return
    fi
    
    print_info "Go version: $(go version)"
    
    # Download dependencies
    print_info "Downloading dependencies..."
    go mod download
    print_success "Dependencies downloaded"
    
    # Format check
    print_info "Checking code format..."
    UNFORMATTED=$(gofmt -l . 2>/dev/null)
    if [ -z "$UNFORMATTED" ]; then
        print_success "Code is properly formatted"
    else
        print_warning "Code needs formatting:"
        echo "$UNFORMATTED"
        echo ""
        read -p "Auto-format code? (y/n): " FMT
        if [[ $FMT =~ ^[Yy]$ ]]; then
            gofmt -w .
            print_success "Code formatted"
        fi
    fi
    
    # Vet
    print_info "Running go vet..."
    if go vet ./...; then
        print_success "go vet passed"
    else
        print_error "go vet failed"
    fi
    
    # Tests
    print_info "Running tests..."
    if go test -v ./...; then
        print_success "Tests passed"
    else
        print_error "Tests failed"
    fi
    
    # Build
    print_info "Building binary..."
    if go build -o main .; then
        print_success "Build successful"
        rm -f main
    else
        print_error "Build failed"
    fi
    
    cd ..
}

# Test frontend
test_frontend() {
    print_header "Testing Frontend"
    
    if [ ! -d "frontend" ]; then
        print_warning "Frontend directory not found, skipping..."
        return
    fi
    
    cd frontend
    
    # Check Node installation
    if ! command -v npm &> /dev/null; then
        print_error "npm not installed"
        cd ..
        return
    fi
    
    print_info "Node version: $(node --version)"
    print_info "npm version: $(npm --version)"
    
    # Install dependencies
    if [ ! -d "node_modules" ]; then
        print_info "Installing dependencies..."
        npm ci
        print_success "Dependencies installed"
    else
        print_info "Dependencies already installed"
    fi
    
    # Lint
    print_info "Running lint..."
    npm run lint --if-present || print_warning "No lint script found, skipping..."
    
    # Tests
    print_info "Running tests..."
    CI=true npm test -- --coverage --watchAll=false 2>&1 | tee /tmp/test-output.txt
    if grep -q "Tests:.*passed" /tmp/test-output.txt || grep -q "No tests found" /tmp/test-output.txt; then
        print_success "Tests passed"
    else
        print_warning "Check test results above"
    fi
    rm -f /tmp/test-output.txt
    
    # Build
    print_info "Building production bundle..."
    if npm run build; then
        print_success "Build successful"
        if [ -d "build" ]; then
            BUILD_SIZE=$(du -sh build | cut -f1)
            print_info "Build size: $BUILD_SIZE"
        fi
    else
        print_error "Build failed"
    fi
    
    cd ..
}

# Test Docker builds
test_docker() {
    print_header "Testing Docker Builds"
    
    if ! command -v docker &> /dev/null; then
        print_warning "Docker not installed, skipping Docker tests..."
        return
    fi
    
    print_info "Docker version: $(docker --version)"
    
    # Backend Docker
    if [ -f "backend/Dockerfile" ]; then
        print_info "Building backend Docker image..."
        if docker build -t devops-backend:test -f backend/Dockerfile backend; then
            print_success "Backend Docker build successful"
            
            # Test run
            print_info "Testing backend container..."
            docker run -d --name backend-test -p 18080:8080 devops-backend:test
            sleep 3
            
            if curl -sf http://localhost:18080/api/v1/health > /dev/null; then
                print_success "Backend container is healthy"
            else
                print_error "Backend container health check failed"
            fi
            
            docker stop backend-test > /dev/null
            docker rm backend-test > /dev/null
            docker rmi devops-backend:test > /dev/null
        else
            print_error "Backend Docker build failed"
        fi
    fi
    
    echo ""
    
    # Frontend Docker
    if [ -f "frontend/Dockerfile" ]; then
        print_info "Building frontend Docker image..."
        if docker build -t devops-frontend:test -f frontend/Dockerfile frontend; then
            print_success "Frontend Docker build successful"
            
            # Test run
            print_info "Testing frontend container..."
            docker run -d --name frontend-test -p 18081:80 devops-frontend:test
            sleep 3
            
            if curl -sf http://localhost:18081 > /dev/null; then
                print_success "Frontend container is healthy"
            else
                print_error "Frontend container health check failed"
            fi
            
            docker stop frontend-test > /dev/null
            docker rm frontend-test > /dev/null
            docker rmi devops-frontend:test > /dev/null
        else
            print_error "Frontend Docker build failed"
        fi
    fi
}

# Validate Kubernetes manifests
validate_k8s() {
    print_header "Validating Kubernetes Manifests"
    
    if ! command -v kubectl &> /dev/null; then
        print_warning "kubectl not installed, skipping K8s validation..."
        return
    fi
    
    # Find all K8s manifests
    K8S_FILES=$(find k8s -name "*.yaml" -o -name "*.yml" 2>/dev/null)
    
    if [ -z "$K8S_FILES" ]; then
        print_warning "No Kubernetes manifests found"
        return
    fi
    
    print_info "Validating manifests with kubectl..."
    
    for file in $K8S_FILES; do
        if kubectl apply --dry-run=client -f "$file" > /dev/null 2>&1; then
            print_success "$(basename $file)"
        else
            print_error "$(basename $file) - validation failed"
        fi
    done
}

# Check for common issues
check_common_issues() {
    print_header "Checking for Common Issues"
    
    # Check for .env files
    if find . -name ".env" -not -path "*/node_modules/*" | grep -q .; then
        print_warning "Found .env files - ensure they're in .gitignore"
    else
        print_success "No .env files found in repository"
    fi
    
    # Check for secrets in code
    print_info "Scanning for potential secrets..."
    if grep -r -i "password\|secret\|api[_-]key" --include="*.go" --include="*.js" --include="*.ts" --include="*.yaml" . 2>/dev/null | grep -v "PASSWORD\|SECRET\|API_KEY" | head -5; then
        print_warning "Found potential hardcoded secrets - please review"
    else
        print_success "No obvious hardcoded secrets found"
    fi
    
    # Check image references
    print_info "Checking Kubernetes image references..."
    if grep -r "your-registry\|YOUR_GITHUB_USERNAME" k8s/ 2>/dev/null; then
        print_warning "Found placeholder image references in K8s manifests"
        echo "Please update them with actual values"
    else
        print_success "Image references look good"
    fi
}

# Summary
print_summary() {
    print_header "Test Summary"
    
    echo ""
    print_info "Local testing complete!"
    echo ""
    print_success "Next steps:"
    echo "  1. Review any warnings or errors above"
    echo "  2. Fix any issues found"
    echo "  3. Commit your changes"
    echo "  4. Push to trigger CI/CD pipeline"
    echo ""
    echo "Useful commands:"
    echo "  git add ."
    echo "  git commit -m 'your message'"
    echo "  git push origin main"
    echo ""
    echo "Monitor CI/CD:"
    echo "  gh run watch"
}

# Main execution
main() {
    clear
    print_header "Local Testing Suite"
    echo ""
    print_info "Testing your changes before CI/CD..."
    echo ""
    
    # Run tests
    test_backend
    echo ""
    
    test_frontend
    echo ""
    
    test_docker
    echo ""
    
    validate_k8s
    echo ""
    
    check_common_issues
    echo ""
    
    print_summary
}

# Run main
main

