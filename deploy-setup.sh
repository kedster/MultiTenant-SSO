#!/bin/bash
# Cloudflare Deployment Setup Script
# This script helps set up and deploy the OpenAuth Enterprise application to Cloudflare

set -e  # Exit on any error

echo "=================================================="
echo "OpenAuth Enterprise - Cloudflare Deployment Setup"
echo "=================================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_info() {
    echo -e "ℹ $1"
}

# Check prerequisites
echo "Step 1: Checking prerequisites..."
echo ""

# Check Node.js
if ! command -v node &> /dev/null; then
    print_error "Node.js is not installed. Please install Node.js 18+ first."
    exit 1
fi
NODE_VERSION=$(node --version)
print_success "Node.js installed: $NODE_VERSION"

# Check npm
if ! command -v npm &> /dev/null; then
    print_error "npm is not installed. Please install npm first."
    exit 1
fi
NPM_VERSION=$(npm --version)
print_success "npm installed: $NPM_VERSION"

# Check if wrangler is installed
if ! command -v wrangler &> /dev/null; then
    print_warning "Wrangler is not installed globally."
    read -p "Would you like to install Wrangler globally? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        npm install -g wrangler
        print_success "Wrangler installed successfully"
    else
        print_error "Wrangler is required for deployment. Exiting."
        exit 1
    fi
else
    WRANGLER_VERSION=$(wrangler --version)
    print_success "Wrangler installed: $WRANGLER_VERSION"
fi

echo ""
echo "Step 2: Installing project dependencies..."
echo ""

npm install
print_success "Dependencies installed"

echo ""
echo "Step 3: Authenticating with Cloudflare..."
echo ""

# Check if already authenticated
if wrangler whoami &> /dev/null; then
    print_success "Already authenticated with Cloudflare"
    wrangler whoami
else
    print_info "Please authenticate with Cloudflare..."
    wrangler login
    if [ $? -eq 0 ]; then
        print_success "Successfully authenticated"
    else
        print_error "Authentication failed"
        exit 1
    fi
fi

echo ""
echo "Step 4: Creating Cloudflare Resources..."
echo ""

# Ask if user wants to create resources or already has them
read -p "Do you need to create Cloudflare resources (D1 database, KV namespaces)? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Create D1 Database
    echo ""
    print_info "Creating D1 database..."
    DB_OUTPUT=$(wrangler d1 create openauth_db 2>&1)
    
    if echo "$DB_OUTPUT" | grep -q "database_id"; then
        print_success "D1 database created"
        DATABASE_ID=$(echo "$DB_OUTPUT" | grep "database_id" | sed -n 's/.*database_id = "\([^"]*\)".*/\1/p')
        echo ""
        print_warning "IMPORTANT: Copy this Database ID"
        echo "Database ID: $DATABASE_ID"
        echo ""
    else
        # Database might already exist
        if echo "$DB_OUTPUT" | grep -q "already exists"; then
            print_warning "Database 'openauth_db' already exists"
            print_info "You can find the database_id by running: wrangler d1 list"
        else
            print_error "Failed to create database"
            echo "$DB_OUTPUT"
        fi
    fi

    # Create KV Namespace for sessions
    echo ""
    print_info "Creating KV namespace for sessions..."
    KV_OUTPUT=$(wrangler kv:namespace create SESSIONS 2>&1)
    
    if echo "$KV_OUTPUT" | grep -q "id ="; then
        print_success "KV namespace created"
        KV_ID=$(echo "$KV_OUTPUT" | grep "id =" | sed -n 's/.*id = "\([^"]*\)".*/\1/p')
        echo ""
        print_warning "IMPORTANT: Copy this KV Namespace ID"
        echo "KV Namespace ID: $KV_ID"
        echo ""
    fi

    # Create Preview KV Namespace
    echo ""
    print_info "Creating preview KV namespace..."
    PREVIEW_KV_OUTPUT=$(wrangler kv:namespace create SESSIONS --preview 2>&1)
    
    if echo "$PREVIEW_KV_OUTPUT" | grep -q "preview_id ="; then
        print_success "Preview KV namespace created"
        PREVIEW_KV_ID=$(echo "$PREVIEW_KV_OUTPUT" | grep "preview_id =" | sed -n 's/.*preview_id = "\([^"]*\)".*/\1/p')
        echo ""
        print_warning "IMPORTANT: Copy this Preview KV Namespace ID"
        echo "Preview KV ID: $PREVIEW_KV_ID"
        echo ""
    fi

    echo ""
    print_warning "=================================================="
    print_warning "ACTION REQUIRED: Update wrangler.toml"
    print_warning "=================================================="
    echo ""
    echo "Please update the following in wrangler.toml:"
    echo ""
    if [ ! -z "$DATABASE_ID" ]; then
        echo "database_id = \"$DATABASE_ID\""
    fi
    if [ ! -z "$KV_ID" ]; then
        echo "id = \"$KV_ID\""
    fi
    if [ ! -z "$PREVIEW_KV_ID" ]; then
        echo "preview_id = \"$PREVIEW_KV_ID\""
    fi
    echo ""
    read -p "Press Enter after you've updated wrangler.toml..."
fi

echo ""
echo "Step 5: Setting up secrets..."
echo ""

# Check if JWT_SECRET exists
SECRET_EXISTS=$(wrangler secret list 2>&1 | grep -c "JWT_SECRET" || true)

if [ "$SECRET_EXISTS" -eq 0 ]; then
    print_info "JWT_SECRET not found. Let's create one..."
    
    # Generate a random JWT secret
    JWT_SECRET=$(openssl rand -base64 32 2>/dev/null || node -e "console.log(require('crypto').randomBytes(32).toString('base64'))")
    
    echo ""
    print_info "Generated JWT Secret: $JWT_SECRET"
    echo ""
    print_warning "Please save this secret securely!"
    echo ""
    
    read -p "Would you like to set this as your JWT_SECRET? (y/n) " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "$JWT_SECRET" | wrangler secret put JWT_SECRET
        print_success "JWT_SECRET set successfully"
    else
        print_info "You can set it manually later with: wrangler secret put JWT_SECRET"
    fi
else
    print_success "JWT_SECRET already exists"
fi

# Create .dev.vars for local development
if [ ! -f .dev.vars ]; then
    echo ""
    print_info "Creating .dev.vars for local development..."
    
    DEV_JWT_SECRET=$(openssl rand -base64 32 2>/dev/null || node -e "console.log(require('crypto').randomBytes(32).toString('base64'))")
    
    cat > .dev.vars << EOF
JWT_SECRET=$DEV_JWT_SECRET
ENVIRONMENT=development
EOF
    
    print_success ".dev.vars created"
else
    print_success ".dev.vars already exists"
fi

echo ""
echo "Step 6: Running database migrations..."
echo ""

read -p "Would you like to run database migrations? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -f "./database/migrations/001_initial_schema.sql" ]; then
        print_info "Running initial schema migration..."
        wrangler d1 execute openauth_db --file=./database/migrations/001_initial_schema.sql
        print_success "Initial schema applied"
    fi
    
    if [ -f "./database/migrations/002_add_sso_billing.sql" ]; then
        print_info "Running SSO and billing migration..."
        wrangler d1 execute openauth_db --file=./database/migrations/002_add_sso_billing.sql
        print_success "SSO and billing schema applied"
    fi
    
    print_success "All migrations completed"
else
    print_info "Skipping migrations. You can run them later with:"
    echo "  wrangler d1 execute openauth_db --file=./database/migrations/001_initial_schema.sql"
fi

echo ""
echo "Step 7: Deploying to Cloudflare..."
echo ""

read -p "Would you like to deploy now? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Deploying worker..."
    npm run deploy
    
    if [ $? -eq 0 ]; then
        print_success "Deployment successful!"
        echo ""
        print_info "Your worker should now be live at:"
        echo "https://openauth-enterprise.<your-subdomain>.workers.dev"
        echo ""
        print_info "Test the health endpoint:"
        echo "curl https://openauth-enterprise.<your-subdomain>.workers.dev/health"
    else
        print_error "Deployment failed. Please check the errors above."
        exit 1
    fi
else
    print_info "Skipping deployment. You can deploy later with: npm run deploy"
fi

echo ""
echo "=================================================="
print_success "Setup Complete!"
echo "=================================================="
echo ""
echo "Next steps:"
echo "1. Test your deployment: curl <your-worker-url>/health"
echo "2. View logs: wrangler tail"
echo "3. Check the Cloudflare dashboard: https://dash.cloudflare.com"
echo "4. Read the full deployment guide: docs/CLOUDFLARE_DEPLOY.md"
echo ""
print_success "Happy deploying!"
