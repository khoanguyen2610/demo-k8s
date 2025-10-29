#!/bin/bash

###############################################################################
# GitHub Secrets Setup Script
# This script helps you set up required secrets for GitHub Actions CI/CD
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if gh CLI is installed
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        print_error "GitHub CLI (gh) is not installed."
        echo ""
        echo "Please install it first:"
        echo "  macOS: brew install gh"
        echo "  Linux: https://github.com/cli/cli/blob/trunk/docs/install_linux.md"
        echo "  Windows: https://github.com/cli/cli/releases"
        exit 1
    fi
    print_success "GitHub CLI found"
}

# Check if authenticated
check_gh_auth() {
    if ! gh auth status &> /dev/null; then
        print_error "Not authenticated with GitHub CLI"
        echo ""
        echo "Please run: gh auth login"
        exit 1
    fi
    print_success "GitHub CLI authenticated"
}

# Check if in git repository
check_git_repo() {
    if ! git rev-parse --is-inside-work-tree &> /dev/null; then
        print_error "Not in a git repository"
        exit 1
    fi
    print_success "Git repository detected"
}

# Get repository info
get_repo_info() {
    REPO_OWNER=$(gh repo view --json owner -q .owner.login)
    REPO_NAME=$(gh repo view --json name -q .name)
    print_info "Repository: $REPO_OWNER/$REPO_NAME"
}

# Setup KUBECONFIG secret
setup_kubeconfig() {
    print_header "Setting up KUBECONFIG Secret"
    
    echo ""
    echo "This will encode your kubeconfig and upload it as a GitHub secret."
    echo ""
    read -p "Path to your kubeconfig file (default: ~/.kube/config): " KUBECONFIG_PATH
    KUBECONFIG_PATH=${KUBECONFIG_PATH:-~/.kube/config}
    
    # Expand tilde
    KUBECONFIG_PATH="${KUBECONFIG_PATH/#\~/$HOME}"
    
    if [ ! -f "$KUBECONFIG_PATH" ]; then
        print_error "File not found: $KUBECONFIG_PATH"
        return 1
    fi
    
    print_info "Encoding kubeconfig..."
    ENCODED_KUBECONFIG=$(cat "$KUBECONFIG_PATH" | base64)
    
    print_info "Uploading to GitHub..."
    echo "$ENCODED_KUBECONFIG" | gh secret set KUBECONFIG
    
    print_success "KUBECONFIG secret set successfully"
}

# Setup optional secrets
setup_optional_secrets() {
    print_header "Optional Secrets"
    
    echo ""
    read -p "Do you want to set REACT_APP_API_URL? (y/n): " SET_API_URL
    if [[ $SET_API_URL =~ ^[Yy]$ ]]; then
        read -p "Enter REACT_APP_API_URL: " API_URL
        echo "$API_URL" | gh secret set REACT_APP_API_URL
        print_success "REACT_APP_API_URL secret set"
    fi
    
    echo ""
    read -p "Do you want to set Docker Hub credentials? (y/n): " SET_DOCKER
    if [[ $SET_DOCKER =~ ^[Yy]$ ]]; then
        read -p "Docker Hub Username: " DOCKER_USERNAME
        read -sp "Docker Hub Password/Token: " DOCKER_PASSWORD
        echo ""
        
        echo "$DOCKER_USERNAME" | gh secret set DOCKER_USERNAME
        echo "$DOCKER_PASSWORD" | gh secret set DOCKER_PASSWORD
        print_success "Docker Hub credentials set"
    fi
}

# Enable GitHub Container Registry
enable_ghcr() {
    print_header "GitHub Container Registry Setup"
    
    print_info "To enable GitHub Container Registry (GHCR):"
    echo ""
    echo "1. Go to: https://github.com/$REPO_OWNER/$REPO_NAME/settings/actions"
    echo "2. Under 'Workflow permissions', select 'Read and write permissions'"
    echo "3. Check 'Allow GitHub Actions to create and approve pull requests'"
    echo ""
    read -p "Press Enter after completing these steps..."
    
    print_success "GHCR setup instructions displayed"
}

# Setup environments
setup_environments() {
    print_header "GitHub Environments Setup"
    
    print_info "Setting up deployment environments..."
    echo ""
    echo "To configure environments manually:"
    echo "1. Go to: https://github.com/$REPO_OWNER/$REPO_NAME/settings/environments"
    echo "2. Create environments: production, staging, development"
    echo "3. Configure protection rules as needed"
    echo ""
    read -p "Press Enter to continue..."
}

# Verify secrets
verify_secrets() {
    print_header "Verifying Secrets"
    
    echo ""
    print_info "Current repository secrets:"
    gh secret list
    
    echo ""
    print_info "Required secrets checklist:"
    
    REQUIRED_SECRETS=("KUBECONFIG")
    OPTIONAL_SECRETS=("REACT_APP_API_URL" "DOCKER_USERNAME" "DOCKER_PASSWORD")
    
    for secret in "${REQUIRED_SECRETS[@]}"; do
        if gh secret list | grep -q "^$secret"; then
            print_success "$secret (required)"
        else
            print_error "$secret (required) - MISSING"
        fi
    done
    
    for secret in "${OPTIONAL_SECRETS[@]}"; do
        if gh secret list | grep -q "^$secret"; then
            print_success "$secret (optional)"
        else
            print_warning "$secret (optional) - not set"
        fi
    done
}

# Update deployment files
update_deployment_files() {
    print_header "Update Deployment Files"
    
    echo ""
    print_info "Updating Kubernetes deployment files with correct image references..."
    
    GITHUB_REPO="$REPO_OWNER/$REPO_NAME"
    
    # Update backend deployment
    if [ -f "k8s/personal/backend-deployment.yaml" ]; then
        sed -i.bak "s|image: ghcr.io/.*/backend:latest|image: ghcr.io/${GITHUB_REPO}/backend:latest|g" \
            k8s/personal/backend-deployment.yaml
        rm k8s/personal/backend-deployment.yaml.bak 2>/dev/null || true
        print_success "Updated backend-deployment.yaml"
    fi
    
    # Update frontend deployment
    if [ -f "k8s/personal/frontend-deployment.yaml" ]; then
        sed -i.bak "s|image: ghcr.io/.*/frontend:latest|image: ghcr.io/${GITHUB_REPO}/frontend:latest|g" \
            k8s/personal/frontend-deployment.yaml
        rm k8s/personal/frontend-deployment.yaml.bak 2>/dev/null || true
        print_success "Updated frontend-deployment.yaml"
    fi
}

# Main execution
main() {
    clear
    print_header "GitHub Actions CI/CD Setup"
    echo ""
    echo "This script will help you set up GitHub secrets for CI/CD"
    echo ""
    
    # Pre-flight checks
    check_gh_cli
    check_gh_auth
    check_git_repo
    get_repo_info
    
    echo ""
    read -p "Continue with setup? (y/n): " CONTINUE
    if [[ ! $CONTINUE =~ ^[Yy]$ ]]; then
        print_warning "Setup cancelled"
        exit 0
    fi
    
    # Setup steps
    setup_kubeconfig
    setup_optional_secrets
    enable_ghcr
    setup_environments
    update_deployment_files
    
    echo ""
    verify_secrets
    
    echo ""
    print_header "Setup Complete!"
    
    echo ""
    print_success "All secrets have been configured"
    print_info "Next steps:"
    echo "  1. Review and commit any changes to deployment files"
    echo "  2. Push changes to trigger CI/CD pipeline"
    echo "  3. Monitor workflow runs in GitHub Actions tab"
    echo ""
    print_info "Documentation: .github/CICD_SETUP.md"
}

# Run main function
main

