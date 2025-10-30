# DevOps Project - Full Stack Application

A full-stack application with Go backend API and React frontend, fully containerized with Docker.

## 🏗️ Architecture

```
┌─────────────────────────────────────────────┐
│              Docker Network                  │
│                                             │
│  ┌──────────────┐      ┌──────────────┐   │
│  │   Frontend   │      │   Backend    │   │
│  │   (React)    │─────▶│    (Go)      │   │
│  │  Port: 3000  │      │  Port: 8080  │   │
│  └──────────────┘      └──────────────┘   │
│       Nginx                  Go API         │
└─────────────────────────────────────────────┘
```

## 📦 Services

### Backend (Go API)
- **Technology**: Go 1.21
- **Port**: 8080
- **Endpoints**:
  - `GET /api/v1/health` - Health check
  - `GET /api/v1/users` - Get mock users
- **Consumer Workers**: 3 background task processors
  - email-processor: Handles email operations
  - data-sync: Syncs data between systems
  - report-generator: Generates reports

### Frontend (React)
- **Technology**: React 18 + Nginx
- **Port**: 3000
- **Features**:
  - Modern responsive UI
  - Real-time health monitoring
  - User list display
  - Refresh functionality

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose
- (Optional) Go 1.21+ for local backend development
- (Optional) Node.js 18+ for local frontend development

### Start Everything with Docker

```bash
# Start all services
make docker-up

# Or manually
docker compose up -d
```

**Access the application:**
- Frontend: http://localhost:3000
- Backend API: http://localhost:8080
- Health Check: http://localhost:8080/api/v1/health

### View Logs

```bash
# All services
make docker-logs

# Backend only
make docker-backend-logs

# Frontend only
make docker-frontend-logs
```

### Stop Services

```bash
make docker-down
```

## 🛠️ Development

### Local Development (without Docker)

**Terminal 1 - Backend:**
```bash
cd backend
go run main.go
```

**Terminal 2 - Frontend:**
```bash
cd frontend
npm install
npm start
```

### Using Makefile

```bash
# View all commands
make help

# Development
make dev-backend          # Run backend locally
make dev-frontend         # Run frontend locally

# Docker operations
make docker-up            # Start all services
make docker-down          # Stop all services
make docker-logs          # View all logs
make docker-rebuild       # Rebuild and restart

# Utilities
make status               # Show service status
make restart              # Restart services
make clean                # Clean up containers
```

## 🐳 Docker Commands

### Build and Run

```bash
# Build all services
docker compose build

# Start services in background
docker compose up -d

# Start with logs
docker compose up

# Stop services
docker compose down
```

### Individual Service Management

```bash
# Build specific service
docker compose build api
docker compose build frontend

# Restart specific service
docker compose restart api
docker compose restart frontend

# View specific logs
docker compose logs -f api
docker compose logs -f frontend
```

## 📁 Project Structure

```
devops/
├── backend/                    # Go API service
│   ├── main.go                # Main application
│   ├── go.mod                 # Go dependencies
│   ├── Dockerfile             # Backend Docker config
│   ├── docker-compose.yml     # Backend-only compose file
│   ├── Makefile              # Backend commands
│   └── README.md             # Backend documentation
│
├── frontend/                  # React application
│   ├── public/               # Public assets
│   ├── src/                  # React source code
│   │   ├── App.js           # Main component
│   │   ├── App.css          # Styles
│   │   └── index.js         # Entry point
│   ├── Dockerfile           # Frontend Docker config
│   ├── nginx.conf           # Nginx configuration
│   ├── package.json         # Node dependencies
│   └── README.md            # Frontend documentation
│
├── k8s/                      # Kubernetes configurations
│
├── docker-compose.yml        # Main compose file (both services)
├── Makefile                  # Root-level commands
└── README.md                 # This file
```

## 🔧 Configuration

### Environment Variables

**Backend:**
- `ENV`: Environment mode (default: production)

**Frontend:**
- `REACT_APP_API_URL`: Backend API URL (default: http://localhost:8080)

### Ports

- Frontend: `3000` (external) → `80` (internal)
- Backend: `8080` (internal only, accessed via frontend proxy)

The frontend Nginx server proxies `/api/*` requests to the backend, enabling seamless communication between services.

## ☸️ Kubernetes Deployment (Helm)

This project uses **Helm charts** for simplified Kubernetes deployment with templates, loops, and variables.

### Quick Start with Helm

```bash
# Install Helm (if not already installed)
brew install helm  # macOS
# or visit https://helm.sh/docs/intro/install/

# Deploy entire application (backend + frontend + consumers + ingress)
cd /Users/khoa.nguyen/Workings/Personal/devops
helm install myapp k8s/personal/devops-app/ --create-namespace

# Check status
helm status myapp
kubectl get all -n backend
kubectl get all -n frontend
```

### Deploy to Specific Environment

```bash
# Development environment (lower resources, debug logging)
helm install dev k8s/personal/devops-app/ \
  -f k8s/personal/devops-app/values-dev.yaml

# Production environment (multiple replicas, specific versions)
helm install prod k8s/personal/devops-app/ \
  -f k8s/personal/devops-app/values-prod.yaml
```

### What's Deployed

The Helm chart deploys:
- **Backend API** (Go REST server) in `backend` namespace
- **Frontend** (React app) in `frontend` namespace
- **Consumer Workers** (3 background tasks) in `backend` namespace
  - email-processor
  - data-sync
  - report-generator
- **Ingress** routing for both frontend and backend
- **Namespaces** automatically created

### Common Operations

```bash
# Update backend image
helm upgrade myapp k8s/personal/devops-app/ \
  --set backend.image.tag=v1.2.3

# Update frontend image
helm upgrade myapp k8s/personal/devops-app/ \
  --set frontend.image.tag=v2.0.0

# Scale backend to 3 replicas
helm upgrade myapp k8s/personal/devops-app/ \
  --set backend.replicas=3

# Rollback to previous version
helm rollback myapp

# Uninstall
helm uninstall myapp
```

### Why Helm?

**Before (Plain YAML):**
- 10+ separate YAML files to manage
- 340+ lines of repetitive code
- Update image = edit 5+ files
- Add consumer = copy/paste 44 lines
- Environment configs = duplicate all files

**After (Helm):**
- 1 chart with templates and loops
- ~100 effective lines of config
- Update image = 1 command
- Add consumer = 3 lines
- Environment = different values file

**Result: 10x simpler, 30x faster, infinitely easier to maintain!** 🚀

### Charts Available

#### 1. devops-app (Main Chart)
Complete application stack - recommended for most use cases.

```bash
helm install myapp k8s/personal/devops-app/
```

[📖 Full Documentation](k8s/personal/devops-app/README.md)

#### 2. consumer-chart (Standalone)
Just the consumer workers, if needed separately.

```bash
helm install consumers k8s/personal/consumer-chart/ -n backend
```

[📖 Full Documentation](k8s/personal/consumer-chart/README.md)

### Configuration

All settings in one file: `k8s/personal/devops-app/values.yaml`

```yaml
# Enable/disable components
components:
  backend: true
  frontend: true
  consumers: true
  ingress: true

# Configure each component
backend:
  replicas: 1
  image:
    repository: khoanguyen2610/backend
    tag: latest

# Consumer tasks (with loop!)
consumers:
  tasks:
    - name: email-processor
      replicas: 1
    - name: data-sync
      replicas: 1
    # Add more - just 3 lines!
```

### Kubernetes Documentation

- [Main K8s README](k8s/personal/README.md) - Comprehensive guide
- [Quick Reference](k8s/personal/QUICK-REFERENCE.md) - Command cheat sheet
- [Helm Transformation](k8s/personal/HELM-TRANSFORMATION.md) - Before/after comparison
- [Consumer Quick Start](k8s/personal/CONSUMER-QUICK-START.md) - Consumer tasks guide

## 🚢 CI/CD

![Build and Deploy](https://github.com/YOUR_USERNAME/devops/actions/workflows/build-deploy.yml/badge.svg)

Simple GitHub Actions CI/CD pipeline that builds and deploys both backend and frontend to AWS EKS.

### 🚀 Quick Setup

```bash
# Set GitHub secrets for AWS EKS
gh secret set AWS_ACCESS_KEY_ID
gh secret set AWS_SECRET_ACCESS_KEY
gh secret set AWS_REGION
gh secret set EKS_CLUSTER_NAME

# Set Docker Hub credentials
gh secret set DOCKER_USERNAME
gh secret set DOCKER_PASSWORD

# Push and deploy automatically
git push origin main
gh run watch
```

### 📋 What's Included

**Single Workflow:** `.github/workflows/build-deploy.yml`

- 🐳 Parallel Docker builds (backend + frontend)
- 📦 Push to Docker Hub
- ☸️ Deploy to AWS EKS
- ✅ Verify deployments
- ↩️ Automatic rollback on failure

### 📦 Container Registry

Images are automatically built and pushed to **Docker Hub**:
- `khoanguyen2610/backend:latest`
- `khoanguyen2610/frontend:latest`

Tagged with:
- Branch name (e.g., `main`, `develop`)
- Git SHA (e.g., `main-abc123`)

### 🔐 Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | AWS access key |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key |
| `AWS_REGION` | AWS region (e.g., us-east-1) |
| `EKS_CLUSTER_NAME` | Your EKS cluster name |
| `DOCKER_USERNAME` | Docker Hub username |
| `DOCKER_PASSWORD` | Docker Hub password/token |

### 🎯 How It Works

```
Push Code → Build (Parallel) → Deploy to EKS → Verify → ✅ Done
              ├─ Backend                          ↓
              └─ Frontend                    Auto Rollback (if fails)
```

### 🛠️ Helper Script

- `scripts/verify-deployment.sh` - Verify deployment health after deploy

### 📊 Monitor Deployment

```bash
# Watch workflow
gh run watch

# Verify deployment
./scripts/verify-deployment.sh

# Check pods
kubectl get pods -n backend
kubectl get pods -n frontend
```

## 📊 Monitoring

### Health Checks

Backend health endpoint is automatically monitored:
```bash
curl http://localhost:8080/api/v1/health
```

Frontend displays backend health status in the UI.

### Docker Health Checks

```bash
# View service health status
docker compose ps

# View detailed container info
docker inspect go-api
```

## 🧪 Testing

### Test Backend API

```bash
# Health check
curl http://localhost:8080/api/v1/health

# Get users
curl http://localhost:8080/api/v1/users
```

### Test Frontend

Open http://localhost:3000 in your browser.

## 🐛 Troubleshooting

### Services won't start

```bash
# Check logs
docker compose logs

# Rebuild from scratch
make docker-rebuild

# Check port conflicts
lsof -i :3000
lsof -i :8080
```

### Frontend can't connect to backend

1. Check if backend is running: `docker compose ps`
2. Verify backend health: `curl http://localhost:8080/api/v1/health`
3. Check Docker network: `docker network inspect devops_app-network`

### Clean slate restart

```bash
# Stop and remove everything
docker compose down -v

# Remove all images
docker rmi $(docker images -q go-api react-frontend)

# Rebuild
make docker-rebuild
```

## 📝 License

This is a personal DevOps project for learning and demonstration purposes.

## 🤝 Contributing

This is a personal project, but suggestions and improvements are welcome!

