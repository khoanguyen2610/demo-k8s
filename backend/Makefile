.PHONY: help build build-api build-consumer run run-consumer-email run-consumer-data run-consumer-report test clean docker-build docker-build-api docker-build-consumer docker-run docker-stop docker-clean docker compose-up docker compose-down

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: build-api build-consumer ## Build all applications

build-api: ## Build the API server
	go build -o api-server .

build-consumer: ## Build the consumer application
	go build -o consumer ./cmd/consumer

run: ## Run the API server locally
	go run main.go

run-consumer-email: ## Run email-processor consumer locally
	go run ./cmd/consumer/main.go --task=email-processor

run-consumer-data: ## Run data-sync consumer locally
	go run ./cmd/consumer/main.go --task=data-sync

run-consumer-report: ## Run report-generator consumer locally
	go run ./cmd/consumer/main.go --task=report-generator

test: ## Run tests
	go test -v ./...

clean: ## Clean build artifacts
	rm -f api-server consumer

docker-build: docker-build-api docker-build-consumer ## Build all Docker images

docker-build-api: ## Build API Docker image
	docker build --target api -t khoanguyen2610/backend:latest .

docker-build-consumer: ## Build consumer Docker image
	docker build --target consumer -t khoanguyen2610/backend:consumer-latest .

docker-run: ## Run API Docker container
	docker run -d --name go-api -p 8080:8080 khoanguyen2610/backend:latest

docker-run-consumer-email: ## Run email-processor consumer container
	docker run -d --name consumer-email khoanguyen2610/backend:consumer-latest --task=email-processor

docker-run-consumer-data: ## Run data-sync consumer container
	docker run -d --name consumer-data khoanguyen2610/backend:consumer-latest --task=data-sync

docker-run-consumer-report: ## Run report-generator consumer container
	docker run -d --name consumer-report khoanguyen2610/backend:consumer-latest --task=report-generator

docker-stop: ## Stop all Docker containers
	docker stop go-api || true
	docker rm go-api || true
	docker stop consumer-email || true
	docker rm consumer-email || true
	docker stop consumer-data || true
	docker rm consumer-data || true
	docker stop consumer-report || true
	docker rm consumer-report || true

docker-clean: docker-stop ## Clean Docker images and containers
	docker rmi khoanguyen2610/backend:latest || true
	docker rmi khoanguyen2610/backend:consumer-latest || true

docker-compose-up: ## Start services with docker compose
	docker compose up -d

docker-compose-down: ## Stop services with docker compose
	docker compose down

docker-compose-logs: ## View docker compose logs
	docker compose logs -f

docker-compose-rebuild: ## Rebuild and restart with docker compose
	docker compose down
	docker compose build --no-cache
	docker compose up -d

