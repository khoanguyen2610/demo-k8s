.PHONY: help dev-backend dev-frontend dev-all docker-up docker-down docker-logs docker-rebuild clean

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

dev-backend: ## Run backend locally
	cd backend && go run main.go

dev-frontend: ## Run frontend locally
	cd frontend && npm start

dev-all: ## Run both backend and frontend locally (requires 2 terminals)
	@echo "Run 'make dev-backend' in one terminal and 'make dev-frontend' in another"

docker-up: ## Start all services with Docker Compose
	docker compose up -d

docker-down: ## Stop all services
	docker compose down

docker-logs: ## View logs from all services
	docker compose logs -f

docker-rebuild: ## Rebuild and restart all services
	docker compose down
	docker compose build --no-cache
	docker compose up -d

docker-backend-logs: ## View backend logs only
	docker compose logs -f api

docker-frontend-logs: ## View frontend logs only
	docker compose logs -f frontend

clean: ## Clean up Docker containers and images
	docker compose down -v
	docker system prune -f

status: ## Show status of services
	docker compose ps

restart: ## Restart all services
	docker compose restart

backend-shell: ## Open shell in backend container
	docker compose exec api sh

frontend-shell: ## Open shell in frontend container
	docker compose exec frontend sh

