#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if Docker is running
check_docker() {
    print_header "Checking Docker"
    
    if ! command_exists docker; then
        print_error "Docker is not installed"
        print_info "Install Docker Desktop from https://www.docker.com/products/docker-desktop"
        print_info "Or run: brew install --cask docker"
        return 1
    fi
    
    if ! docker ps >/dev/null 2>&1; then
        print_error "Docker is installed but not running"
        print_info "Please start Docker Desktop and wait for it to fully start"
        return 1
    fi
    
    print_success "Docker is installed and running"
    return 0
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    local missing=0
    
    if ! command_exists k3d; then
        print_error "k3d is not installed"
        print_info "Install with: brew install k3d"
        missing=$((missing + 1))
    else
        print_success "k3d is installed"
    fi
    
    if ! command_exists kubectl; then
        print_error "kubectl is not installed"
        print_info "Install with: brew install kubectl"
        missing=$((missing + 1))
    else
        print_success "kubectl is installed"
    fi
    
    if ! command_exists kustomize; then
        print_error "kustomize is not installed"
        print_info "Install with: brew install kustomize"
        missing=$((missing + 1))
    else
        print_success "kustomize is installed"
    fi
    
    if ! command_exists tilt; then
        print_error "tilt is not installed"
        print_info "Install with: brew install tilt"
        missing=$((missing + 1))
    else
        print_success "tilt is installed"
    fi
    
    if ! command_exists helm; then
        print_error "helm is not installed"
        print_info "Install with: brew install helm"
        missing=$((missing + 1))
    else
        print_success "helm is installed"
    fi
    
    if [ $missing -gt 0 ]; then
        print_warning "$missing prerequisite(s) missing"
        print_info "Install all prerequisites with: brew bundle"
        return 1
    fi
    
    return 0
}

# Configure kubectl context
configure_kubectl() {
    print_header "Configuring kubectl Context"
    
    # Check if cluster exists
    if k3d cluster list --no-headers otel-basic 2>/dev/null | grep -q otel-basic; then
        print_info "k3d cluster 'otel-basic' exists"
    else
        print_info "k3d cluster 'otel-basic' will be created when you run 'make'"
    fi
    
    # Write kubeconfig
    if k3d kubeconfig write otel-basic 2>/dev/null; then
        print_success "kubeconfig written for otel-basic cluster"
    else
        print_warning "Could not write kubeconfig (cluster may not exist yet)"
        print_info "This is normal if you haven't run 'make' yet"
    fi
    
    # Set KUBECONFIG environment variable
    export KUBECONFIG=$HOME/.config/k3d/kubeconfig-otel-basic.yaml
    
    # Verify context
    if kubectl config current-context 2>/dev/null | grep -q "k3d-otel-basic"; then
        print_success "kubectl context is set to k3d-otel-basic"
    else
        print_warning "kubectl context is not set to k3d-otel-basic"
        print_info "Set it with: export KUBECONFIG=\$HOME/.config/k3d/kubeconfig-otel-basic.yaml"
    fi
}

# Check GitHub receiver setup
check_github_setup() {
    print_header "Checking GitHub Receiver Setup"
    
    local env_file="./collectors/githubreceiver/.env"
    
    if [ -f "$env_file" ]; then
        if grep -q "GH_PAT=" "$env_file" && ! grep -q "GH_PAT=$" "$env_file" && ! grep -q "GH_PAT=YOUR_TOKEN_HERE" "$env_file"; then
            print_success "GitHub PAT is configured"
        else
            print_warning "GitHub PAT file exists but token may not be set"
            print_info "Edit $env_file and set your GH_PAT"
        fi
    else
        print_warning "GitHub PAT not configured"
        print_info "To set up GitHub integration:"
        print_info "  1. Create a GitHub PAT with 'repo' and 'read:org' permissions"
        print_info "  2. Run: echo 'GH_PAT=your_token_here' > $env_file"
        print_info "  3. Run: make ghr"
    fi
}

# Main setup function
main() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║   tag-o11y Quick Start - Setup Check                    ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}\n"
    
    local errors=0
    
    # Check Docker
    if ! check_docker; then
        errors=$((errors + 1))
    fi
    
    # Check prerequisites
    if ! check_prerequisites; then
        errors=$((errors + 1))
    fi
    
    # Configure kubectl (non-fatal)
    configure_kubectl
    
    # Check GitHub setup (non-fatal)
    check_github_setup
    
    echo ""
    print_header "Setup Check Complete"
    
    if [ $errors -eq 0 ]; then
        print_success "All checks passed! You're ready to run 'make'"
        echo ""
        print_info "Next steps:"
        echo "  1. Run: make"
        echo "  2. Wait 2-5 minutes for services to start"
        echo "  3. Access OpenObserve at: http://localhost:5080"
        echo "     Username: root@example.com"
        echo "     Password: Complexpass#123"
    else
        print_error "Some checks failed. Please fix the issues above before running 'make'"
        exit 1
    fi
}

# Run main function
main "$@"

