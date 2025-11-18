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

ENV_FILE="./collectors/githubreceiver/.env"

echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   GitHub Receiver Setup                                  ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}\n"

print_info "This script will help you configure the GitHub receiver."
echo ""

# Check if .env file already exists
if [ -f "$ENV_FILE" ]; then
    if grep -q "GH_PAT=" "$ENV_FILE" && ! grep -q "GH_PAT=$" "$ENV_FILE" && ! grep -q "GH_PAT=YOUR_TOKEN_HERE" "$ENV_FILE"; then
        print_warning "GitHub PAT is already configured in $ENV_FILE"
        read -p "Do you want to update it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Keeping existing configuration."
            exit 0
        fi
    fi
fi

print_info "To create a GitHub Personal Access Token (PAT):"
echo "  1. Go to: https://github.com/settings/tokens"
echo "  2. Click 'Generate new token' → 'Generate new token (classic)'"
echo "  3. Give it a name (e.g., 'OpenTelemetry Collector')"
echo "  4. Select these permissions:"
echo "     - repo (Full control of private repositories)"
echo "     - read:org (Read org and team membership)"
echo "  5. Click 'Generate token'"
echo "  6. Copy the token (you won't see it again!)"
echo ""

print_warning "If your organization uses SSO, you'll need to authorize the token:"
echo "  - After creating the token, you'll see a banner"
echo "  - Click 'Configure SSO' and authorize for your organization"
echo ""

read -p "Enter your GitHub PAT: " -s GH_PAT
echo ""

if [ -z "$GH_PAT" ]; then
    echo "Error: No token provided"
    exit 1
fi

# Create directory if it doesn't exist
mkdir -p "$(dirname "$ENV_FILE")"

# Write the token to .env file
echo "GH_PAT=$GH_PAT" > "$ENV_FILE"
print_success "GitHub PAT saved to $ENV_FILE"

echo ""
print_info "Next steps:"
echo "  1. (Optional) Edit ./collectors/githubreceiver/colconfig.yaml to customize:"
echo "     - github_org: Your organization name"
echo "     - search_query: Repository search query"
echo "  2. Deploy the GitHub receiver:"
echo "     make deploy-github"
echo "     (You can also use 'make ghr' - both commands do the same thing)"
echo "  3. Check the logs:"
echo "     kubectl logs -n collector -l app.kubernetes.io/name=opentelemetry-collector | grep github"

