#!/bin/bash

# Development startup script
# This script helps you start the development environment

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   DevOps Project - Development Setup${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker is running${NC}"
echo ""

# Ask user for preferred mode
echo "Choose your development mode:"
echo "  1) Docker (Recommended - Full stack with containers)"
echo "  2) Local (Backend + Frontend running locally)"
echo ""
read -p "Enter your choice (1 or 2): " choice

case $choice in
    1)
        echo ""
        echo -e "${BLUE}Starting services with Docker Compose...${NC}"
        docker compose up -d
        
        echo ""
        echo -e "${GREEN}✓ Services started successfully!${NC}"
        echo ""
        echo -e "${YELLOW}Access your application:${NC}"
        echo "  Frontend:  http://localhost:3000"
        echo "  Backend:   http://localhost:8080"
        echo "  Health:    http://localhost:8080/api/v1/health"
        echo ""
        echo -e "${YELLOW}Useful commands:${NC}"
        echo "  View logs:        docker compose logs -f"
        echo "  Stop services:    docker compose down"
        echo "  Restart:          docker compose restart"
        echo ""
        
        # Ask if user wants to see logs
        read -p "Would you like to see the logs? (y/n): " show_logs
        if [ "$show_logs" = "y" ] || [ "$show_logs" = "Y" ]; then
            docker compose logs -f
        fi
        ;;
    
    2)
        echo ""
        echo -e "${BLUE}Setting up local development environment...${NC}"
        echo ""
        
        # Check if Go is installed
        if ! command -v go &> /dev/null; then
            echo -e "${YELLOW}⚠️  Go is not installed. Please install Go 1.21+ first.${NC}"
            exit 1
        fi
        echo -e "${GREEN}✓ Go is installed${NC}"
        
        # Check if Node.js is installed
        if ! command -v node &> /dev/null; then
            echo -e "${YELLOW}⚠️  Node.js is not installed. Please install Node.js 18+ first.${NC}"
            exit 1
        fi
        echo -e "${GREEN}✓ Node.js is installed${NC}"
        
        # Install frontend dependencies if needed
        if [ ! -d "frontend/node_modules" ]; then
            echo ""
            echo -e "${BLUE}Installing frontend dependencies...${NC}"
            cd frontend && npm install && cd ..
        fi
        
        echo ""
        echo -e "${GREEN}✓ Setup complete!${NC}"
        echo ""
        echo -e "${YELLOW}Starting local development servers...${NC}"
        echo ""
        echo "You need to run these commands in separate terminals:"
        echo ""
        echo -e "${BLUE}Terminal 1 - Backend:${NC}"
        echo "  cd backend && go run main.go"
        echo ""
        echo -e "${BLUE}Terminal 2 - Frontend:${NC}"
        echo "  cd frontend && npm start"
        echo ""
        
        read -p "Press Enter to continue..."
        ;;
    
    *)
        echo -e "${YELLOW}Invalid choice. Exiting.${NC}"
        exit 1
        ;;
esac

