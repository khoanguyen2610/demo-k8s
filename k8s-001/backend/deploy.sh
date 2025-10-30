#!/bin/bash

# Deployment script for Go API
# Usage: ./deploy.sh [environment]

set -e

ENVIRONMENT=${1:-production}
DOCKER_IMAGE="go-api:latest"

echo "🚀 Starting deployment for environment: $ENVIRONMENT"

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed!"
    exit 1
fi

print_success "Docker is installed"

# Check if docker-compose is installed
if ! command -v docker-compose &> /dev/null; then
    print_warning "docker-compose is not installed, trying 'docker compose' instead"
    COMPOSE_CMD="docker compose"
else
    COMPOSE_CMD="docker-compose"
fi

# Pull latest changes (if using git)
if [ -d ".git" ]; then
    print_success "Pulling latest changes from git..."
    git pull origin main || git pull origin master || true
fi

# Build Docker image
print_success "Building Docker image..."
docker build -t $DOCKER_IMAGE .

# Stop existing containers
print_success "Stopping existing containers..."
$COMPOSE_CMD down

# Start new containers
print_success "Starting new containers..."
$COMPOSE_CMD up -d

# Wait for service to be healthy
print_success "Waiting for service to be healthy..."
sleep 5

# Health check
MAX_RETRIES=10
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if curl -f http://localhost:8080/api/v1/health > /dev/null 2>&1; then
        print_success "Service is healthy!"
        break
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
        print_error "Service failed to start properly"
        $COMPOSE_CMD logs
        exit 1
    fi
    
    print_warning "Waiting for service... (attempt $RETRY_COUNT/$MAX_RETRIES)"
    sleep 3
done

# Clean up old images
print_success "Cleaning up old images..."
docker image prune -f

print_success "Deployment completed successfully! 🎉"
echo ""
echo "API is running at: http://localhost:8080"
echo "Health check: http://localhost:8080/api/v1/health"
echo "Users endpoint: http://localhost:8080/api/v1/users"
echo ""
echo "To view logs: $COMPOSE_CMD logs -f"

