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

# Resolve script directory using BASH_SOURCE for robust path resolution
# This works even when the script is sourced or symlinked
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect platform
detect_platform() {
    case "$(uname -s)" in
        Darwin*)
            echo "macos"
            ;;
        Linux*)
            echo "linux"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            echo "windows"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Check if Docker is running
check_docker() {
    print_header "Checking Docker"
    
    if ! command_exists docker; then
        print_error "Docker is not installed"
        local platform=$(detect_platform)
        case "$platform" in
            macos)
                print_info "Install Docker Desktop from https://www.docker.com/products/docker-desktop"
                print_info "Or run: brew install --cask docker"
                ;;
            linux)
                print_info "Install Docker from https://docs.docker.com/get-docker/"
                print_info "Or use your distribution's package manager"
                ;;
            windows)
                print_info "Install Docker Desktop from https://www.docker.com/products/docker-desktop"
                ;;
            *)
                print_info "Install Docker from https://www.docker.com/get-started"
                ;;
        esac
        return 1
    fi
    
    if ! docker ps >/dev/null 2>&1; then
        print_error "Docker is installed but not running"
        local platform=$(detect_platform)
        case "$platform" in
            macos|windows)
                print_info "Please start Docker Desktop and wait for it to fully start"
                ;;
            linux)
                print_info "Start Docker with: sudo systemctl start docker"
                print_info "Or: sudo service docker start"
                ;;
            *)
                print_info "Please start Docker and wait for it to fully start"
                ;;
        esac
        return 1
    fi
    
    print_success "Docker is installed and running"
    return 0
}

# Get installation instructions for a tool based on platform
get_install_instructions() {
    local tool=$1
    local platform=$(detect_platform)
    
    case "$platform" in
        macos)
            if command_exists brew; then
                echo "brew install $tool"
            else
                echo "Install Homebrew first, then: brew install $tool"
            fi
            ;;
        linux)
            case "$tool" in
                k3d)
                    echo "curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash"
                    ;;
                kubectl)
                    echo "See: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/"
                    ;;
                kustomize)
                    echo "curl -s \"https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh\" | bash"
                    ;;
                tilt)
                    echo "curl -fsSL https://raw.githubusercontent.com/tilt-dev/tilt/master/scripts/install.sh | bash"
                    ;;
                helm)
                    echo "curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
                    ;;
                *)
                    echo "Install $tool using your distribution's package manager"
                    ;;
            esac
            ;;
        windows)
            case "$tool" in
                k3d|kubectl|kustomize|tilt|helm)
                    echo "Install $tool using Chocolatey: choco install $tool"
                    echo "Or download from: https://github.com/$tool"
                    ;;
                *)
                    echo "Install $tool from https://github.com/$tool"
                    ;;
            esac
            ;;
        *)
            echo "Install $tool from https://github.com/$tool"
            ;;
    esac
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    local missing=0
    local platform=$(detect_platform)
    
    if ! command_exists k3d; then
        print_error "k3d is not installed"
        print_info "Install with: $(get_install_instructions k3d)"
        missing=$((missing + 1))
    else
        print_success "k3d is installed"
    fi
    
    if ! command_exists kubectl; then
        print_error "kubectl is not installed"
        print_info "Install with: $(get_install_instructions kubectl)"
        missing=$((missing + 1))
    else
        print_success "kubectl is installed"
    fi
    
    if ! command_exists kustomize; then
        print_error "kustomize is not installed"
        print_info "Install with: $(get_install_instructions kustomize)"
        missing=$((missing + 1))
    else
        print_success "kustomize is installed"
    fi
    
    if ! command_exists tilt; then
        print_error "tilt is not installed"
        print_info "Install with: $(get_install_instructions tilt)"
        missing=$((missing + 1))
    else
        print_success "tilt is installed"
    fi
    
    if ! command_exists helm; then
        print_error "helm is not installed"
        print_info "Install with: $(get_install_instructions helm)"
        missing=$((missing + 1))
    else
        print_success "helm is installed"
    fi
    
    if [ $missing -gt 0 ]; then
        print_warning "$missing prerequisite(s) missing"
        if [ "$platform" = "macos" ] && command_exists brew; then
            print_info "On macOS with Homebrew, you can install all prerequisites with: brew bundle"
        fi
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

# Check integration setup (non-blocking)
check_integrations() {
    print_header "Checking Integration Setup"
    
    local github_env="$REPO_ROOT/collectors/githubreceiver/.env"
    local gitlab_env="$REPO_ROOT/collectors/gitlabreceiver/.env"
    local integrations_configured=0
    
    # Check GitHub
    if [ -f "$github_env" ]; then
        if grep -q "GH_PAT=" "$github_env" && ! grep -q "GH_PAT=$" "$github_env" && ! grep -q "GH_PAT=YOUR_TOKEN_HERE" "$github_env"; then
            print_success "GitHub integration is configured"
            integrations_configured=$((integrations_configured + 1))
        else
            print_info "GitHub: Not configured (run 'make setup-github' to set up)"
        fi
    else
        print_info "GitHub: Not configured (run 'make setup-github' to set up)"
    fi
    
    # Check GitLab
    if [ -f "$gitlab_env" ]; then
        if grep -q "GL_PAT=" "$gitlab_env" && ! grep -q "GL_PAT=$" "$gitlab_env" && ! grep -q "GL_PAT=YOUR_TOKEN_HERE" "$gitlab_env"; then
            print_success "GitLab integration is configured"
            integrations_configured=$((integrations_configured + 1))
        else
            print_info "GitLab: Not configured (run 'make setup-gitlab' to set up)"
        fi
    else
        print_info "GitLab: Not configured (run 'make setup-gitlab' to set up)"
    fi
    
    if [ $integrations_configured -eq 0 ]; then
        print_info "No integrations configured. This is optional - you can run 'make' without them."
        print_info "To add integrations later:"
        print_info "  - GitHub: make setup-github, then make deploy-github"
        print_info "  - GitLab: make setup-gitlab, then make deploy-gitlab"
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
    
    # Check integrations (non-fatal, informational only)
    check_integrations
    
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

