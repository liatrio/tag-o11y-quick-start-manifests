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

# Resolve script directory using BASH_SOURCE for robust path resolution
# This works even when the script is sourced or symlinked
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Validate that we're in the repository root by checking for known markers
if [ ! -f "$REPO_ROOT/Makefile" ] && [ ! -d "$REPO_ROOT/.git" ]; then
    echo "Error: Cannot find repository root. Expected to find Makefile or .git directory."
    echo "Please run this script from the repository root directory."
    exit 1
fi

ENV_FILE="$REPO_ROOT/collectors/gitlabreceiver/.env"

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

# Create directory if it doesn't exist, checking for errors
if ! mkdir -p "$(dirname "$ENV_FILE")"; then
    echo "Error: Failed to create directory $(dirname "$ENV_FILE")"
    exit 1
fi

# Remove any existing GL_PAT line if the file exists, then append the new one
# Use atomic operations where possible for race-safety
if [ -f "$ENV_FILE" ]; then
    # Store current permissions to preserve if stricter than 600
    current_perms=$(stat -f "%OLp" "$ENV_FILE" 2>/dev/null || stat -c "%a" "$ENV_FILE" 2>/dev/null || echo "644")
    
    # Use sed to remove any existing GL_PAT line (works on both macOS and Linux)
    # Create temp file for atomic operation
    TEMP_FILE="${ENV_FILE}.tmp"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS sed requires -i '' for in-place editing, but we'll use temp file for atomicity
        sed '/^GL_PAT=/d' "$ENV_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$ENV_FILE"
    else
        # Linux sed uses -i without extension, but we'll use temp file for atomicity
        sed '/^GL_PAT=/d' "$ENV_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$ENV_FILE"
    fi
    
    # Append new GL_PAT line atomically
    echo "GL_PAT=$GL_PAT" >> "$ENV_FILE"
    
    # Set permissions to 600 only if current permissions are less restrictive
    # 600 = rw------- (owner read/write only)
    # Only change if current permissions allow group/other access (e.g., 644, 755, etc.)
    if [ "$current_perms" != "600" ] && [ "$current_perms" != "400" ] && [ "$current_perms" != "600" ]; then
        chmod 600 "$ENV_FILE" 2>/dev/null || true
    fi
else
    # File doesn't exist, create it with restrictive permissions
    # Set umask temporarily to ensure file is created with 600 permissions
    OLD_UMASK=$(umask)
    umask 0177  # Results in 600 permissions (rw-------)
    echo "GL_PAT=$GL_PAT" > "$ENV_FILE"
    umask "$OLD_UMASK"
    # Explicitly set permissions as backup (in case umask didn't work as expected)
    chmod 600 "$ENV_FILE" 2>/dev/null || true
fi

print_success "GitLab PAT saved to $ENV_FILE"

echo ""
print_info "Next steps:"
echo "  1. (Optional) Edit ./collectors/gitlabreceiver/colconfig.yaml to customize:"
echo "     - gitlab_org: Your GitLab organization/group name"
echo "     - endpoint: Your GitLab instance URL (if self-hosted)"
echo "     - team.name: Your team name"
echo "  2. Deploy the GitLab receiver:"
echo "     make deploy-gitlab"
echo "     (You can also use 'make glr' - both commands do the same thing)"
echo "  3. Check the logs:"
echo "     kubectl logs -n collector -l app.kubernetes.io/name=opentelemetry-collector | grep gitlab"

