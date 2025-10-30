# Consumer Application

A Go-based consumer application that simulates background task processing. This application supports multiple task types that can run independently as separate processes or pods in Kubernetes.

## Available Tasks

### 1. Email Processor (`email-processor`)
Simulates email processing operations including:
- Sending emails
- Filtering spam
- Categorizing messages
- Archiving old emails

### 2. Data Sync (`data-sync`)
Simulates data synchronization between systems:
- Database syncing
- API data synchronization
- File storage syncing
- Cache updates

### 3. Report Generator (`report-generator`)
Simulates report generation tasks:
- Daily summaries
- Weekly analytics
- Monthly reports
- Quarterly reviews

## Running Locally

### Build the Consumer App

```bash
# Build the consumer binary
make build-consumer

# Or build directly with Go
go build -o consumer ./cmd/consumer
```

### Run Individual Tasks

```bash
# Run email processor
make run-consumer-email

# Run data sync
make run-consumer-data

# Run report generator
make run-consumer-report
```

Or run directly with the binary:

```bash
# Run specific task
./consumer --task=email-processor
./consumer --task=data-sync
./consumer --task=report-generator
```

## Running with Docker

### Build Docker Images

```bash
# Build consumer Docker image
make docker-build-consumer

# Or build directly
docker build --target consumer -t khoanguyen2610/backend:consumer-latest .
```

### Run Consumer Containers

```bash
# Run email processor container
make docker-run-consumer-email

# Run data sync container
make docker-run-consumer-data

# Run report generator container
make docker-run-consumer-report
```

Or run directly with Docker:

```bash
docker run -d --name consumer-email khoanguyen2610/backend:consumer-latest --task=email-processor
docker run -d --name consumer-data khoanguyen2610/backend:consumer-latest --task=data-sync
docker run -d --name consumer-report khoanguyen2610/backend:consumer-latest --task=report-generator
```

### View Container Logs

```bash
# View logs for specific consumer
docker logs -f consumer-email
docker logs -f consumer-data
docker logs -f consumer-report
```

## Kubernetes Deployment

Each task runs as a separate deployment with its own pod in the `backend` namespace.

### Deployment Files

Located in `/k8s/personal/`:
- `consumer-email-processor.yaml` - Email processor deployment
- `consumer-data-sync.yaml` - Data sync deployment
- `consumer-report-generator.yaml` - Report generator deployment

### Deploy to Kubernetes

```bash
# Deploy all consumer tasks
kubectl apply -f k8s/personal/consumer-email-processor.yaml
kubectl apply -f k8s/personal/consumer-data-sync.yaml
kubectl apply -f k8s/personal/consumer-report-generator.yaml

# Check deployment status
kubectl get deployments -n backend
kubectl get pods -n backend -l app=consumer

# View logs from specific task
kubectl logs -n backend -l task=email-processor -f
kubectl logs -n backend -l task=data-sync -f
kubectl logs -n backend -l task=report-generator -f
```

### Delete Deployments

```bash
# Delete specific task
kubectl delete -f k8s/personal/consumer-email-processor.yaml

# Delete all consumer tasks
kubectl delete -f k8s/personal/consumer-email-processor.yaml
kubectl delete -f k8s/personal/consumer-data-sync.yaml
kubectl delete -f k8s/personal/consumer-report-generator.yaml
```

## Architecture

```
┌─────────────────────────────────────────────────────┐
│               Consumer Application                   │
├─────────────────────────────────────────────────────┤
│                                                       │
│  ┌──────────────────┐  ┌──────────────────┐         │
│  │ Email Processor  │  │   Data Sync      │         │
│  │      Pod         │  │      Pod         │         │
│  │                  │  │                  │         │
│  │  - Send emails   │  │  - DB sync       │         │
│  │  - Filter spam   │  │  - API sync      │         │
│  │  - Categorize    │  │  - File sync     │         │
│  │  - Archive       │  │  - Cache update  │         │
│  └──────────────────┘  └──────────────────┘         │
│                                                       │
│         ┌──────────────────┐                         │
│         │ Report Generator │                         │
│         │      Pod         │                         │
│         │                  │                         │
│         │  - Daily reports │                         │
│         │  - Weekly stats  │                         │
│         │  - Monthly data  │                         │
│         │  - Quarterly     │                         │
│         └──────────────────┘                         │
│                                                       │
└─────────────────────────────────────────────────────┘
```

## Configuration

### Environment Variables

- `TASK_NAME`: Name of the task to run (set automatically in K8s)
- `ENV`: Environment (production/development)

### Resource Limits

Each consumer pod is configured with:
- **CPU Request**: 50m
- **CPU Limit**: 200m
- **Memory Request**: 64Mi
- **Memory Limit**: 128Mi

### Task Arguments

The consumer application accepts the following command-line argument:
- `--task`: Specifies which task to run (required)
  - Values: `email-processor`, `data-sync`, `report-generator`

## Monitoring

### Check Pod Status

```bash
# Get all consumer pods
kubectl get pods -n backend -l app=consumer

# Describe specific pod
kubectl describe pod -n backend -l task=email-processor
```

### View Logs

```bash
# Stream logs from all consumer pods
kubectl logs -n backend -l app=consumer -f --tail=100

# View logs from specific task
kubectl logs -n backend -l task=email-processor -f
kubectl logs -n backend -l task=data-sync -f
kubectl logs -n backend -l task=report-generator -f
```

### Check Resource Usage

```bash
# View CPU and memory usage
kubectl top pods -n backend -l app=consumer
```

## Troubleshooting

### Pod Not Starting

```bash
# Check pod events
kubectl describe pod -n backend -l app=consumer

# Check pod logs
kubectl logs -n backend -l app=consumer --previous
```

### Task Argument Errors

Make sure the `--task` argument is correctly set in the deployment YAML:

```yaml
args:
- "--task=email-processor"  # Must be one of: email-processor, data-sync, report-generator
```

### Image Pull Errors

Ensure the Docker image is built and pushed to the registry:

```bash
# Build and push consumer image
docker build --target consumer -t khoanguyen2610/backend:consumer-latest .
docker push khoanguyen2610/backend:consumer-latest
```

## Development

### Adding New Tasks

1. Create a new task type implementing the `Task` interface:

```go
type NewTask struct{}

func (t *NewTask) Name() string {
    return "new-task"
}

func (t *NewTask) Run() error {
    // Task implementation
    return nil
}
```

2. Add the task to the switch statement in `main.go`:

```go
case "new-task":
    task = &NewTask{}
```

3. Create a new Kubernetes deployment file for the task

4. Update the Makefile with new commands

## Testing

```bash
# Run tests
make test

# Run a consumer task locally for testing
make run-consumer-email
```

## Clean Up

```bash
# Stop all Docker containers
make docker-stop

# Clean build artifacts
make clean

# Delete K8s deployments
kubectl delete -n backend deployments -l app=consumer
```

