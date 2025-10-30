# Simple Go API & Consumer Application

A simple Go REST API with mock data endpoints and a consumer application for background task processing.

## Components

### 1. API Server
REST API with mock data endpoints for health checks and user data.

### 2. Consumer Application
Background task processor that runs three types of tasks:
- **Email Processor**: Handles email operations (sending, filtering, categorizing, archiving)
- **Data Sync**: Syncs data between systems (database, API, file storage, cache)
- **Report Generator**: Generates various reports (daily, weekly, monthly, quarterly)

See [Consumer Documentation](cmd/consumer/README.md) for detailed information.

## API Endpoints

### Health Check
- **GET** `/api/v1/health`
- Returns server health status, timestamp, and uptime

### Users List
- **GET** `/api/v1/users`
- Returns a list of randomly generated mock users

## Installation & Running

1. Make sure you have Go installed (1.21+)

2. Navigate to the backend directory:
```bash
cd backend
```

3. Run the server:
```bash
go run main.go
```

The server will start on `http://localhost:8080`

## Testing the API

### Health Check
```bash
curl http://localhost:8080/api/v1/health
```

Response example:
```json
{
  "status": "healthy",
  "timestamp": "2025-10-29T10:30:45.123Z",
  "uptime": "1m30.5s"
}
```

### Get Users
```bash
curl http://localhost:8080/api/v1/users
```

Response example:
```json
{
  "users": [
    {
      "id": 1,
      "name": "John Smith",
      "email": "John.Smith@example.com",
      "age": 32,
      "country": "USA",
      "created_at": "2024-03-15T10:30:45.123Z"
    },
    ...
  ],
  "total": 7
}
```

## Build

### Build API Server
```bash
make build-api
# or
go build -o api-server .
```

Then run:
```bash
./api-server
```

### Build Consumer Application
```bash
make build-consumer
# or
go build -o consumer ./cmd/consumer
```

Then run (specify task):
```bash
./consumer --task=email-processor
./consumer --task=data-sync
./consumer --task=report-generator
```

### Build All Applications
```bash
make build
```

## Docker Deployment

### Using Docker

Build Docker images:
```bash
# Build API server image
make docker-build-api

# Build consumer image
make docker-build-consumer

# Build both
make docker-build
```

Run containers:
```bash
# Run API server
make docker-run

# Run consumer tasks
make docker-run-consumer-email
make docker-run-consumer-data
make docker-run-consumer-report
```

Stop containers:
```bash
make docker-stop
```

### Using Docker Compose

Start the service:
```bash
docker-compose up -d
```

View logs:
```bash
docker-compose logs -f
```

Stop the service:
```bash
docker-compose down
```

### Using Makefile

The project includes a Makefile for common tasks:

```bash
# View all available commands
make help

# Local development - API Server
make run                    # Run API server locally
make build-api              # Build API server binary
make test                   # Run tests

# Local development - Consumer
make build-consumer         # Build consumer binary
make run-consumer-email     # Run email-processor
make run-consumer-data      # Run data-sync
make run-consumer-report    # Run report-generator

# Build all
make build                  # Build both API and consumer

# Docker commands - API
make docker-build-api       # Build API Docker image
make docker-run             # Run API container

# Docker commands - Consumer
make docker-build-consumer          # Build consumer Docker image
make docker-run-consumer-email      # Run email-processor container
make docker-run-consumer-data       # Run data-sync container
make docker-run-consumer-report     # Run report-generator container

# Docker commands - All
make docker-build           # Build all Docker images
make docker-stop            # Stop all containers
make docker-clean           # Clean Docker images and containers

# Docker Compose commands
make docker-compose-up       # Start with docker-compose
make docker-compose-down     # Stop docker-compose
make docker-compose-logs     # View logs
make docker-compose-rebuild  # Rebuild and restart
```

## CI/CD

### GitHub Actions

The project includes a GitHub Actions workflow (`.github/workflows/docker-build.yml`) that:
- Builds and pushes Docker images on push to main/master/develop branches
- Tags images with branch name, commit SHA, and version tags
- Runs security scanning with Trivy
- Uses Docker layer caching for faster builds

**Required Secrets:**
- `DOCKER_USERNAME`: Your Docker Hub username
- `DOCKER_PASSWORD`: Your Docker Hub password/token

### GitLab CI

The project includes a GitLab CI configuration (`.gitlab-ci.yml`) that:
- Builds Docker images and pushes to GitLab Container Registry
- Runs health check tests on the built image
- Deploys to production server (manual trigger)

**Required Variables:**
- `CI_REGISTRY_USER`: GitLab registry username (auto-provided)
- `CI_REGISTRY_PASSWORD`: GitLab registry password (auto-provided)
- `SSH_PRIVATE_KEY`: SSH key for deployment server
- `DEPLOY_SERVER`: Deployment server hostname/IP
- `DEPLOY_USER`: SSH user for deployment

### Deployment

The CI/CD pipelines can deploy to any environment. For manual deployment via SSH:

```bash
ssh user@server
cd /opt/app
docker-compose pull
docker-compose up -d
```

## Kubernetes Deployment

The consumer tasks are designed to run as separate pods in Kubernetes. Each task has its own deployment file.

### Deploy Consumer Tasks

```bash
# Deploy all consumer tasks at once
cd ../k8s/personal
./deploy-consumers.sh

# Or deploy individually
kubectl apply -f k8s/personal/consumer-email-processor.yaml
kubectl apply -f k8s/personal/consumer-data-sync.yaml
kubectl apply -f k8s/personal/consumer-report-generator.yaml
```

### Monitor Consumer Tasks

```bash
# View all consumer pods
kubectl get pods -n backend -l app=consumer

# View logs from specific task
kubectl logs -n backend -l task=email-processor -f
kubectl logs -n backend -l task=data-sync -f
kubectl logs -n backend -l task=report-generator -f

# View resource usage
kubectl top pods -n backend -l app=consumer
```

See the [Consumer Documentation](cmd/consumer/README.md) for more details on Kubernetes deployment.

## Project Structure

```
backend/
├── main.go                           # API server application
├── cmd/
│   └── consumer/
│       ├── main.go                   # Consumer application
│       └── README.md                 # Consumer documentation
├── go.mod                            # Go module definition
├── Dockerfile                        # Multi-stage Docker build (API + Consumer)
├── docker-compose.yml                # Docker Compose configuration
├── .dockerignore                     # Docker ignore file
├── .github/workflows/docker-build.yml # GitHub Actions CI/CD
├── .gitlab-ci.yml                    # GitLab CI/CD
├── Makefile                          # Common tasks for both API and Consumer
└── README.md                         # This file
```

