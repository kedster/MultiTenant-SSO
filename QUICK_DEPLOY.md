# 🚀 Quick Deploy to Cloudflare

Deploy OpenAuth Enterprise to Cloudflare Workers in minutes with our automated deployment script!

## One-Command Deployment

```bash
# Clone the repository
git clone https://github.com/kedster/MultiTenant-SSO.git
cd MultiTenant-SSO

# Run the automated deployment script
./scripts/deploy-cloudflare.sh
```

That's it! The script will handle everything automatically.

## What You Need

1. **Cloudflare Account** (free tier works fine)
   - Sign up: https://dash.cloudflare.com/sign-up

2. **Node.js 18+** installed
   ```bash
   node --version  # Check your version
   ```

3. One of these authentication methods:
   - **Option A (Easier)**: Browser for interactive login
   - **Option B**: Cloudflare API Token (see below)

## Step-by-Step

### 1. Get the Code
```bash
git clone https://github.com/kedster/MultiTenant-SSO.git
cd MultiTenant-SSO
```

### 2. Run Deployment Script
```bash
./scripts/deploy-cloudflare.sh
```

The script will:
- ✅ Install Wrangler CLI if needed
- ✅ Authenticate with Cloudflare (browser popup)
- ✅ Create D1 database
- ✅ Create KV storage
- ✅ Set up secrets
- ✅ Run migrations
- ✅ Deploy the worker
- ✅ Test deployment

### 3. Get Your URL
After deployment, you'll see:
```
================================================
Deployment URL: https://openauth-enterprise.YOUR_SUBDOMAIN.workers.dev
================================================
```

### 4. Test It
```bash
curl https://openauth-enterprise.YOUR_SUBDOMAIN.workers.dev/health
# Response: {"status":"healthy"}
```

## Advanced: Deploy with API Token

If you prefer non-interactive deployment:

### 1. Create API Token
1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. My Profile → API Tokens → Create Token
3. Use "Edit Cloudflare Workers" template
4. Add these permissions:
   - Workers Scripts: Edit
   - D1: Edit
   - Workers KV Storage: Edit
5. Copy the token

### 2. Deploy with Token
```bash
CLOUDFLARE_API_TOKEN=your_token_here ./scripts/deploy-cloudflare.sh
```

## GitHub Actions (CI/CD)

Set up automated deployments on every push:

### 1. Add Secrets to GitHub
Go to repository Settings → Secrets and variables → Actions:

- `CLOUDFLARE_API_TOKEN`: Your Cloudflare API token
- `JWT_SECRET`: Generate with `openssl rand -base64 32`

### 2. Push to Main Branch
```bash
git push origin main
```

Deployment happens automatically! View progress in the Actions tab.

### 3. Manual Trigger
1. Go to GitHub → Actions tab
2. Select "Deploy to Cloudflare Workers"
3. Click "Run workflow"

## Verification

After deployment, verify everything works:

```bash
# Health check
curl https://your-worker.workers.dev/health

# Auth routes
curl https://your-worker.workers.dev/auth

# Admin routes
curl https://your-worker.workers.dev/admin
```

## View Logs

```bash
# Real-time logs
wrangler tail

# Or in Cloudflare Dashboard
# Workers & Pages → your-worker → Logs
```

## Update Deployment

Made changes? Deploy updates:

```bash
# Test locally first
npm run dev

# Deploy update
./scripts/deploy-cloudflare.sh
# or just
wrangler deploy
```

## Troubleshooting

### Script Fails to Authenticate
```bash
# Try manual login
wrangler login

# Then run script again
./scripts/deploy-cloudflare.sh
```

### "Wrangler not found"
```bash
# Install globally
npm install -g wrangler

# Verify
wrangler --version
```

### Worker Returns 500 Errors
```bash
# Check logs
wrangler tail

# Verify secrets
wrangler secret list

# Re-run migrations
wrangler d1 execute openauth_db --file=./database/migrations/001_initial_schema.sql
```

### Need to Start Over?
```bash
# Delete resources in Cloudflare Dashboard:
# - D1 Database: openauth_db
# - KV Namespace: SESSIONS

# Then run deployment again
./scripts/deploy-cloudflare.sh
```

## What Gets Created?

The deployment creates these Cloudflare resources:

1. **Worker**: `openauth-enterprise`
   - Your application code running on Cloudflare's edge network

2. **D1 Database**: `openauth_db`
   - PostgreSQL-compatible SQL database
   - Stores organizations, users, apps, etc.

3. **KV Namespace**: `SESSIONS`
   - Key-value storage for session management
   - High-performance, globally distributed

4. **Secrets**: `JWT_SECRET`
   - Encrypted environment variables
   - Never exposed in logs or configuration

## Cost

Cloudflare Workers Free Tier includes:
- 100,000 requests/day
- More than enough for development and small production use

Paid tier ($5/month):
- 10 million requests/month
- Perfect for production applications

**Development/Testing**: FREE  
**Small Production**: ~$5/month  
**Medium Production**: ~$10-20/month

## Next Steps

After deployment:

1. ✅ **Test Endpoints**: Verify all routes work
2. ✅ **Custom Domain**: Add your own domain (optional)
3. ✅ **Deploy Frontend**: Deploy React admin portal to Cloudflare Pages
4. ✅ **Configure SSO**: Set up Azure AD, Google Workspace, etc.
5. ✅ **Monitoring**: Set up alerts and logging
6. ✅ **Documentation**: Update team docs with your deployment URL

## Full Documentation

For detailed information:

- **Automated Deployment**: [scripts/README.md](scripts/README.md)
- **Manual Deployment**: [docs/CLOUDFLARE_DEPLOY.md](docs/CLOUDFLARE_DEPLOY.md)
- **API Documentation**: [docs/API.md](docs/API.md)
- **Development Guide**: [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)

## Get Help

- **Script Issues**: Check [scripts/README.md](scripts/README.md) for troubleshooting
- **Cloudflare Issues**: [Cloudflare Discord](https://discord.gg/cloudflaredev)
- **Bug Reports**: [GitHub Issues](https://github.com/kedster/MultiTenant-SSO/issues)

---

**Ready to deploy? Run this command:**

```bash
./scripts/deploy-cloudflare.sh
```

🎉 Your SSO system will be live in minutes!
