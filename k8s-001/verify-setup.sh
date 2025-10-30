#!/bin/bash

# Setup verification script

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   DevOps Project - Setup Verification${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

check_file() {
    if [ -f "$1" ]; then
        echo -e "${GREEN}✓${NC} $1"
        return 0
    else
        echo -e "${RED}✗${NC} $1 ${RED}(missing)${NC}"
        return 1
    fi
}

check_dir() {
    if [ -d "$1" ]; then
        echo -e "${GREEN}✓${NC} $1/"
        return 0
    else
        echo -e "${RED}✗${NC} $1/ ${RED}(missing)${NC}"
        return 1
    fi
}

echo -e "${YELLOW}Checking Backend Files:${NC}"
check_file "backend/main.go"
check_file "backend/go.mod"
check_file "backend/Dockerfile"
check_file "backend/Makefile"
check_file "backend/README.md"

echo ""
echo -e "${YELLOW}Checking Frontend Files:${NC}"
check_dir "frontend/src"
check_dir "frontend/public"
check_file "frontend/package.json"
check_file "frontend/Dockerfile"
check_file "frontend/nginx.conf"
check_file "frontend/README.md"

echo ""
echo -e "${YELLOW}Checking Docker Configuration:${NC}"
check_file "docker-compose.yml"
check_file "backend/Dockerfile"
check_file "frontend/Dockerfile"

echo ""
echo -e "${YELLOW}Checking CI/CD Configuration:${NC}"
check_file ".github/workflows/docker-build.yml"
check_file ".gitlab-ci.yml"

echo ""
echo -e "${YELLOW}Checking Documentation:${NC}"
check_file "README.md"
check_file "Makefile"
check_file "start-dev.sh"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Setup verification complete!${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Start development: ./start-dev.sh"
echo "2. Or use Docker: make docker-up"
echo "3. View all commands: make help"
echo ""

