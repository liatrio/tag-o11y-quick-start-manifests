#!/bin/bash

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

ENV_FILE="./collectors/gitlabreceiver/.env"

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   GitLab Receiver Setup                                  ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}\n"

print_info "This script will help you configure the GitLab receiver."
echo ""

# Check if .env file already exists
if [ -f "$ENV_FILE" ]; then
    if grep -q "GL_PAT=" "$ENV_FILE" && ! grep -q "GL_PAT=$" "$ENV_FILE" && ! grep -q "GL_PAT=YOUR_TOKEN_HERE" "$ENV_FILE"; then
        print_warning "GitLab PAT is already configured in $ENV_FILE"
        read -p "Do you want to update it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Keeping existing configuration."
            exit 0
        fi
    fi
fi

print_info "To create a GitLab Personal Access Token (PAT):"
echo "  1. Go to: https://gitlab.com/-/user_settings/personal_access_tokens"
echo "     (Or your GitLab instance: <your-gitlab-url>/-/user_settings/personal_access_tokens)"
echo "  2. Click 'Add new token'"
echo "  3. Give it a name (e.g., 'OpenTelemetry Collector')"
echo "  4. Set an expiration date (optional)"
echo "  5. Select these scopes:"
echo "     - read_api (Read API)"
echo "     - read_repository (Read repository)"
echo "     - read_user (Read user)"
echo "  6. Click 'Create personal access token'"
echo "  7. Copy the token (you won't see it again!)"
echo ""

print_warning "If using a self-hosted GitLab instance:"
echo "  - Update the 'endpoint' field in ./collectors/gitlabreceiver/colconfig.yaml"
echo "  - Default endpoint is https://gitlab.com/ for GitLab.com"
echo ""

read -p "Enter your GitLab PAT: " -s GL_PAT
echo ""

if [ -z "$GL_PAT" ]; then
    echo "Error: No token provided"
    exit 1
fi

# Create directory if it doesn't exist
mkdir -p "$(dirname "$ENV_FILE")"

# Write the token to .env file
echo "GL_PAT=$GL_PAT" > "$ENV_FILE"
print_success "GitLab PAT saved to $ENV_FILE"

echo ""
print_info "Next steps:"
echo "  1. (Optional) Edit ./collectors/gitlabreceiver/colconfig.yaml to customize:"
echo "     - gitlab_org: Your GitLab organization/group name"
echo "     - endpoint: Your GitLab instance URL (if self-hosted)"
echo "     - team.name: Your team name"
echo "  2. Deploy the GitLab receiver:"
echo "     make glr"
echo "  3. Check the logs:"
echo "     kubectl logs -n collector -l app.kubernetes.io/name=opentelemetry-collector | grep gitlab"

