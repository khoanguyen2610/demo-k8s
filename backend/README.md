# Simple Go API

A simple Go REST API with mock data endpoints.

## Endpoints

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

To build the executable:
```bash
go build -o api-server main.go
```

Then run:
```bash
./api-server
```

## Docker Deployment

### Using Docker

Build the Docker image:
```bash
docker build -t go-api:latest .
```

Run the container:
```bash
docker run -d --name go-api -p 8080:8080 go-api:latest
```

Stop the container:
```bash
docker stop go-api
docker rm go-api
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

# Local development
make run              # Run locally
make build            # Build binary
make test             # Run tests

# Docker commands
make docker-build     # Build Docker image
make docker-run       # Run container
make docker-stop      # Stop container

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

## Project Structure

```
backend/
├── main.go                           # Main application
├── go.mod                            # Go module definition
├── Dockerfile                        # Docker image configuration
├── docker-compose.yml                # Docker Compose configuration
├── .dockerignore                     # Docker ignore file
├── .github/workflows/docker-build.yml # GitHub Actions CI/CD
├── .gitlab-ci.yml                    # GitLab CI/CD
├── Makefile                          # Common tasks
└── README.md                         # This file
```

