#!/bin/bash

# Cloudflare Deployment Automation Script
# This script automates the deployment of OpenAuth Enterprise to Cloudflare Workers
# 
# Prerequisites:
# - Node.js 18+ installed
# - npm installed
# - Cloudflare account credentials (API token or login)
#
# Usage:
#   ./scripts/deploy-cloudflare.sh
#
# Or with environment variables:
#   CLOUDFLARE_API_TOKEN=your_token ./scripts/deploy-cloudflare.sh

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Log functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Banner
echo "================================================"
echo "  OpenAuth Enterprise - Cloudflare Deployment"
echo "================================================"
echo ""

# Change to project root
cd "$PROJECT_ROOT"

# Check prerequisites
log_info "Checking prerequisites..."

# Check Node.js
if ! command -v node &> /dev/null; then
    log_error "Node.js is not installed. Please install Node.js 18+ and try again."
    exit 1
fi

NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    log_error "Node.js version 18 or higher is required. Current version: $(node --version)"
    exit 1
fi
log_success "Node.js version: $(node --version)"

# Check npm
if ! command -v npm &> /dev/null; then
    log_error "npm is not installed."
    exit 1
fi
log_success "npm version: $(npm --version)"

# Install wrangler if not already installed
log_info "Checking Wrangler CLI..."
if ! command -v wrangler &> /dev/null; then
    log_warning "Wrangler not found. Installing globally..."
    npm install -g wrangler
    log_success "Wrangler installed successfully"
else
    log_success "Wrangler version: $(wrangler --version)"
fi

# Install project dependencies
log_info "Installing project dependencies..."
npm install
log_success "Dependencies installed"

# Authenticate with Cloudflare
log_info "Checking Cloudflare authentication..."
if ! wrangler whoami &> /dev/null; then
    log_warning "Not authenticated with Cloudflare"
    
    if [ -n "$CLOUDFLARE_API_TOKEN" ]; then
        log_info "Using CLOUDFLARE_API_TOKEN from environment"
        export CLOUDFLARE_API_TOKEN
    else
        log_info "Please authenticate with Cloudflare..."
        log_info "This will open your browser for authentication."
        read -p "Press Enter to continue..."
        wrangler login
    fi
    
    # Verify authentication
    if ! wrangler whoami &> /dev/null; then
        log_error "Authentication failed. Please try again."
        exit 1
    fi
fi

CLOUDFLARE_USER=$(wrangler whoami 2>&1 | grep -E "(email|Account)" | head -1 || echo "Authenticated")
log_success "Authenticated: $CLOUDFLARE_USER"

# Create D1 Database
log_info "Creating D1 Database..."
D1_OUTPUT=$(wrangler d1 create openauth_db 2>&1 || echo "")

if echo "$D1_OUTPUT" | grep -q "already exists"; then
    log_warning "Database 'openauth_db' already exists"
    # Extract existing database ID
    DB_ID=$(wrangler d1 list | grep openauth_db | awk '{print $2}' || echo "")
else
    # Extract database ID from creation output
    DB_ID=$(echo "$D1_OUTPUT" | grep -o 'database_id = "[^"]*"' | cut -d'"' -f2 || echo "")
fi

if [ -z "$DB_ID" ]; then
    log_error "Failed to create or find D1 database. Please create it manually."
    log_info "Run: wrangler d1 create openauth_db"
    exit 1
fi
log_success "D1 Database ID: $DB_ID"

# Create KV Namespace for sessions (production)
log_info "Creating KV Namespace for sessions..."
KV_OUTPUT=$(wrangler kv:namespace create SESSIONS 2>&1 || echo "")

if echo "$KV_OUTPUT" | grep -q "already exists"; then
    log_warning "KV Namespace 'SESSIONS' already exists"
    KV_ID=$(wrangler kv:namespace list | grep SESSIONS | grep -v preview | awk '{print $2}' || echo "")
else
    KV_ID=$(echo "$KV_OUTPUT" | grep -o 'id = "[^"]*"' | cut -d'"' -f2 || echo "")
fi

if [ -z "$KV_ID" ]; then
    log_error "Failed to create or find KV namespace. Please create it manually."
    log_info "Run: wrangler kv:namespace create SESSIONS"
    exit 1
fi
log_success "KV Namespace ID: $KV_ID"

# Create KV Namespace for sessions (preview)
log_info "Creating KV Namespace for sessions (preview)..."
KV_PREVIEW_OUTPUT=$(wrangler kv:namespace create SESSIONS --preview 2>&1 || echo "")

if echo "$KV_PREVIEW_OUTPUT" | grep -q "already exists"; then
    log_warning "Preview KV Namespace already exists"
    KV_PREVIEW_ID=$(wrangler kv:namespace list | grep SESSIONS | grep preview | awk '{print $2}' || echo "")
else
    KV_PREVIEW_ID=$(echo "$KV_PREVIEW_OUTPUT" | grep -o 'preview_id = "[^"]*"' | cut -d'"' -f2 || echo "")
fi

if [ -z "$KV_PREVIEW_ID" ]; then
    log_warning "Failed to get preview KV namespace ID. Will use production ID."
    KV_PREVIEW_ID="$KV_ID"
fi
log_success "KV Preview Namespace ID: $KV_PREVIEW_ID"

# Update wrangler.toml with the IDs
log_info "Updating wrangler.toml with resource IDs..."

# Backup original wrangler.toml
cp wrangler.toml wrangler.toml.backup

# Update database_id
sed -i.tmp "s/database_id = \".*\"/database_id = \"$DB_ID\"/" wrangler.toml

# Update KV namespace IDs
sed -i.tmp "s/id = \"your-kv-namespace-id\"/id = \"$KV_ID\"/" wrangler.toml
sed -i.tmp "s/preview_id = \"your-preview-kv-namespace-id\"/preview_id = \"$KV_PREVIEW_ID\"/" wrangler.toml

# Clean up temp files
rm -f wrangler.toml.tmp

log_success "wrangler.toml updated successfully"

# Check and set JWT_SECRET
log_info "Checking JWT_SECRET..."
if ! wrangler secret list 2>&1 | grep -q "JWT_SECRET"; then
    log_warning "JWT_SECRET not set"
    
    # Generate a secure JWT secret
    JWT_SECRET=$(openssl rand -base64 32 2>/dev/null || node -e "console.log(require('crypto').randomBytes(32).toString('base64'))")
    
    log_info "Generated JWT_SECRET: $JWT_SECRET"
    log_info "Setting JWT_SECRET as Cloudflare secret..."
    
    echo "$JWT_SECRET" | wrangler secret put JWT_SECRET
    log_success "JWT_SECRET set successfully"
else
    log_success "JWT_SECRET already configured"
fi

# Run database migrations
log_info "Running database migrations..."

# Check if migrations exist
if [ -d "database/migrations" ]; then
    for migration in database/migrations/*.sql; do
        if [ -f "$migration" ]; then
            log_info "Running migration: $(basename $migration)"
            wrangler d1 execute openauth_db --file="$migration" 2>&1 || log_warning "Migration may have already been applied"
        fi
    done
    log_success "Database migrations completed"
else
    log_warning "No migrations directory found"
fi

# Deploy the worker
log_info "Deploying worker to Cloudflare..."
DEPLOY_OUTPUT=$(wrangler deploy 2>&1)

if [ $? -eq 0 ]; then
    log_success "Deployment successful!"
    
    # Extract and display the deployment URL
    WORKER_URL=$(echo "$DEPLOY_OUTPUT" | grep -o 'https://[^[:space:]]*workers.dev' || echo "")
    
    if [ -n "$WORKER_URL" ]; then
        echo ""
        echo "================================================"
        echo -e "${GREEN}Deployment URL:${NC} $WORKER_URL"
        echo "================================================"
        echo ""
        
        # Test the deployment
        log_info "Testing deployment health check..."
        sleep 3  # Wait for deployment to propagate
        
        HEALTH_CHECK=$(curl -s "${WORKER_URL}/health" || echo "")
        if echo "$HEALTH_CHECK" | grep -q "healthy"; then
            log_success "Health check passed! Worker is running."
        else
            log_warning "Health check did not return expected response. Response: $HEALTH_CHECK"
        fi
    fi
else
    log_error "Deployment failed. Check the output above for errors."
    exit 1
fi

# Save deployment info
cat > deployment-info.txt << EOF
OpenAuth Enterprise - Cloudflare Deployment Info
================================================
Deployment Date: $(date)
D1 Database ID: $DB_ID
KV Namespace ID: $KV_ID
KV Preview ID: $KV_PREVIEW_ID
Worker URL: $WORKER_URL

To view logs:
  wrangler tail

To update deployment:
  wrangler deploy

To manage secrets:
  wrangler secret list
  wrangler secret put SECRET_NAME
  wrangler secret delete SECRET_NAME

For more information, see:
  docs/CLOUDFLARE_DEPLOY.md
EOF

log_success "Deployment info saved to deployment-info.txt"

echo ""
echo "================================================"
log_success "Deployment Complete!"
echo "================================================"
echo ""
echo "Next steps:"
echo "1. Test your endpoints: $WORKER_URL"
echo "2. View logs: wrangler tail"
echo "3. Set up custom domain (optional)"
echo "4. Configure monitoring and alerts"
echo ""
echo "For detailed information, see deployment-info.txt"
echo ""
