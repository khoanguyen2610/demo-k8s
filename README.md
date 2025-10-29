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

## 🚢 CI/CD

![Build and Deploy](https://github.com/YOUR_USERNAME/devops/actions/workflows/build-deploy.yml/badge.svg)

Simple GitHub Actions CI/CD pipeline that builds and deploys both backend and frontend to AWS EKS.

### 🚀 Quick Setup

```bash
# Set GitHub secrets for AWS
gh secret set AWS_ACCESS_KEY_ID
gh secret set AWS_SECRET_ACCESS_KEY
gh secret set AWS_REGION
gh secret set EKS_CLUSTER_NAME

# Push and deploy automatically
git push origin main
gh run watch
```

### 📋 What's Included

**Single Workflow:** `.github/workflows/build-deploy.yml`

- 🐳 Parallel Docker builds (backend + frontend)
- 📦 Push to GitHub Container Registry
- ☸️ Deploy to AWS EKS
- ✅ Verify deployments
- ↩️ Automatic rollback on failure

### 📦 Container Registry

Images are automatically built and pushed to **GitHub Container Registry (GHCR)**:
- `ghcr.io/your-username/devops/backend:latest`
- `ghcr.io/your-username/devops/frontend:latest`

Tagged with:
- Branch name (e.g., `main`, `develop`)
- Git SHA (e.g., `main-abc123`)
- Semantic versions (e.g., `v1.0.0`, `1.0`)

### 🔐 Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | AWS access key |
| `AWS_SECRET_ACCESS_KEY` | AWS secret key |
| `AWS_REGION` | AWS region (e.g., us-east-1) |
| `EKS_CLUSTER_NAME` | Your EKS cluster name |

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

