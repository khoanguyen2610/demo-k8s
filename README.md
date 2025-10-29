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

![Backend CI/CD](https://github.com/YOUR_USERNAME/devops/actions/workflows/backend-cicd.yml/badge.svg)
![Frontend CI/CD](https://github.com/YOUR_USERNAME/devops/actions/workflows/frontend-cicd.yml/badge.svg)

This project includes comprehensive GitHub Actions CI/CD pipelines for automated testing, building, and deployment to Kubernetes.

### 🚀 Quick Setup

Get your CI/CD pipeline running in 5 minutes:

```bash
# Run the automated setup script
./scripts/setup-github-secrets.sh

# Test locally before pushing
./scripts/local-test.sh

# Push and watch the magic happen
git push origin main
gh run watch
```

📖 **[Quick Start Guide →](QUICKSTART_CICD.md)**

### 📋 What's Included

**Three GitHub Actions Workflows:**

1. **Backend CI/CD** (`.github/workflows/backend-cicd.yml`)
   - ✅ Go tests with coverage
   - 🔍 golangci-lint static analysis
   - 🐳 Multi-platform Docker builds (amd64, arm64)
   - 🔒 Trivy security scanning
   - 🚀 Automated Kubernetes deployment
   - ↩️ Automatic rollback on failure

2. **Frontend CI/CD** (`.github/workflows/frontend-cicd.yml`)
   - ✅ React/Jest tests with coverage
   - 🔍 ESLint code quality checks
   - 📦 Production build optimization
   - 🐳 Multi-platform Docker builds
   - 🔒 Trivy security scanning
   - 🚀 Automated Kubernetes deployment
   - ↩️ Automatic rollback on failure

3. **Full Stack Deployment** (`.github/workflows/deploy-stack.yml`)
   - 🎯 Manual workflow dispatch
   - 🔄 Deploy both services together
   - 🏷️ Support for specific image tags
   - 🔍 Comprehensive health checks
   - 📊 Deployment summary

**PR Checks Workflow:**
- 📝 PR title validation (semantic commits)
- 🔍 File change detection
- ⚠️ Sensitive file scanning
- 🐛 Backend/Frontend linting and tests
- ☸️ Kubernetes manifest validation
- 🔒 Security scanning
- 📏 PR size checking

### 📦 Container Registry

Images are automatically built and pushed to **GitHub Container Registry (GHCR)**:
- `ghcr.io/your-username/devops/backend:latest`
- `ghcr.io/your-username/devops/frontend:latest`

Tagged with:
- Branch name (e.g., `main`, `develop`)
- Git SHA (e.g., `main-abc123`)
- Semantic versions (e.g., `v1.0.0`, `1.0`)

### 🔐 Required Secrets

Set up in `Settings > Secrets and variables > Actions`:

| Secret | Required | Description |
|--------|----------|-------------|
| `KUBECONFIG` | ✅ Yes | Base64-encoded Kubernetes config |
| `REACT_APP_API_URL` | ❌ No | Backend API URL for frontend |
| `DOCKER_USERNAME` | ❌ No | Docker Hub username (if not using GHCR) |
| `DOCKER_PASSWORD` | ❌ No | Docker Hub password (if not using GHCR) |

Use the setup script for easy configuration:
```bash
./scripts/setup-github-secrets.sh
```

### 🎯 How It Works

```
┌──────────────────────────────────────────────────────────────┐
│  Developer pushes to main/develop                             │
└──────────────┬───────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────────┐
│  GitHub Actions Triggers (path-based)                         │
├──────────────────────────────────────────────────────────────┤
│  • backend/** → Backend CI/CD                                 │
│  • frontend/** → Frontend CI/CD                               │
└──────────────┬───────────────────────────────────────────────┘
               │
               ├──► Test & Lint ──► Build Docker ──► Security Scan ──┐
               │                                                       │
               └───────────────────────────────────────────────────┬─┘
                                                                    │
                                                                    ▼
┌──────────────────────────────────────────────────────────────────┐
│  Deploy to Kubernetes                                             │
├──────────────────────────────────────────────────────────────────┤
│  • Update deployment with new image                              │
│  • Wait for rollout completion                                   │
│  • Run health checks                                             │
│  • ✅ Success or ↩️ Automatic rollback                           │
└──────────────────────────────────────────────────────────────────┘
```

### 🛠️ Helper Scripts

Located in `scripts/`:

| Script | Purpose |
|--------|---------|
| `setup-github-secrets.sh` | Interactive GitHub secrets configuration |
| `local-test.sh` | Test everything locally before pushing |
| `verify-deployment.sh` | Verify Kubernetes deployment health |

### 📚 Documentation

- 📖 **[Quick Start Guide](QUICKSTART_CICD.md)** - Get started in 5 minutes
- 📘 **[Complete CI/CD Setup](.github/CICD_SETUP.md)** - Detailed documentation
- 📝 **[PR Template](.github/pull_request_template.md)** - Standard PR format

### 🚦 CI/CD Status

View workflow status and logs:

```bash
# View all workflows
gh workflow list

# View recent runs
gh run list

# Watch current run
gh run watch

# View logs
gh run view <run-id> --log
```

Or visit: `https://github.com/YOUR_USERNAME/devops/actions`

### 🔄 Manual Deployment

Deploy manually using GitHub Actions UI or CLI:

```bash
# Deploy full stack
gh workflow run deploy-stack.yml \
  --field environment=production \
  --field backend_image_tag=latest \
  --field frontend_image_tag=latest
```

### 📊 Verify Deployment

After deployment, verify everything is healthy:

```bash
# Run verification script
./scripts/verify-deployment.sh

# Or manually check
kubectl get pods -n backend
kubectl get pods -n frontend
kubectl get svc --all-namespaces
```

### 🔧 Local Testing

Test your changes locally before pushing:

```bash
# Run comprehensive local tests
./scripts/local-test.sh

# This will:
# - Run backend tests and linting
# - Run frontend tests and builds
# - Test Docker builds locally
# - Validate Kubernetes manifests
# - Check for common issues
```

### 🎓 Best Practices

- ✅ Always test locally before pushing (`./scripts/local-test.sh`)
- ✅ Use meaningful commit messages (follows semantic commit format)
- ✅ Monitor CI/CD runs after pushing (`gh run watch`)
- ✅ Review security scan results in GitHub Security tab
- ✅ Use PR template for consistent pull requests
- ✅ Verify deployments with health checks (`./scripts/verify-deployment.sh`)

### 🆘 Troubleshooting CI/CD

Common issues and solutions:

**Pipeline fails with "KUBECONFIG not found"**
```bash
./scripts/setup-github-secrets.sh
```

**Docker image push fails**
- Enable GHCR in repository settings (see [Quick Start](QUICKSTART_CICD.md))

**Deployment timeout**
```bash
kubectl describe pod -n backend <pod-name>
kubectl logs -n backend deployment/backend-api
```

See [Complete Troubleshooting Guide](.github/CICD_SETUP.md#troubleshooting)

### 📈 Features

- 🚀 Automated testing and deployment
- 🐳 Multi-platform Docker builds
- 🔒 Security scanning with Trivy
- 📊 Code coverage reporting
- ↩️ Automatic rollback on failure
- 🎯 Path-based workflow triggers
- 🏷️ Semantic versioning support
- 📝 PR validation and checks
- 🔍 Comprehensive health checks

### GitLab CI (Legacy)

If you prefer GitLab CI, configurations are also available:
- `backend/.gitlab-ci.yml` - GitLab CI for backend
- Build → Test → Deploy pipeline
- Manual production deployment

---

**Next Steps:**
1. 📖 Read the [Quick Start Guide](QUICKSTART_CICD.md)
2. 🔐 Run `./scripts/setup-github-secrets.sh`
3. 🧪 Test locally with `./scripts/local-test.sh`
4. 🚀 Push and watch your deployment!

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

