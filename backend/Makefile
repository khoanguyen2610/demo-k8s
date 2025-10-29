.PHONY: help build run test clean docker-build docker-run docker-stop docker-clean docker compose-up docker compose-down

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build the Go application
	go build -o main .

run: ## Run the Go application locally
	go run main.go

test: ## Run tests
	go test -v ./...

clean: ## Clean build artifacts
	rm -f main

docker-build: ## Build Docker image
	docker build -t go-api:latest .

docker-run: ## Run Docker container
	docker run -d --name go-api -p 8080:8080 go-api:latest

docker-stop: ## Stop Docker container
	docker stop go-api || true
	docker rm go-api || true

docker-clean: docker-stop ## Clean Docker image and container
	docker rmi go-api:latest || true

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

