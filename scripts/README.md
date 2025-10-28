# Automated Cloudflare Deployment

This directory contains automated deployment tools for deploying OpenAuth Enterprise to Cloudflare Workers.

## Quick Deployment Options

### Option 1: One-Click Automated Script (Recommended)

The easiest way to deploy is using our automated deployment script:

```bash
# From the project root directory
./scripts/deploy-cloudflare.sh
```

This script will:
- ✅ Check and install all prerequisites (Wrangler CLI)
- ✅ Authenticate with Cloudflare (interactive or via API token)
- ✅ Create D1 database automatically
- ✅ Create KV namespaces automatically
- ✅ Update wrangler.toml with resource IDs
- ✅ Generate and set JWT_SECRET
- ✅ Run database migrations
- ✅ Deploy the worker
- ✅ Test the deployment
- ✅ Save deployment info for reference

**With API Token:**
```bash
CLOUDFLARE_API_TOKEN=your_token_here ./scripts/deploy-cloudflare.sh
```

**Interactive Login:**
```bash
# Script will prompt you to login via browser
./scripts/deploy-cloudflare.sh
```

### Option 2: GitHub Actions (CI/CD)

For automated deployments on every push to main:

1. **Add Cloudflare API Token to GitHub Secrets:**
   - Go to your repository → Settings → Secrets and variables → Actions
   - Click "New repository secret"
   - Name: `CLOUDFLARE_API_TOKEN`
   - Value: Your Cloudflare API token (see below for how to create)

2. **Add JWT Secret to GitHub Secrets:**
   - Name: `JWT_SECRET`
   - Value: A secure random string (generate with `openssl rand -base64 32`)

3. **Enable the workflow:**
   - The workflow file is at `.github/workflows/deploy-cloudflare.yml`
   - It will automatically run on pushes to `main` or `production` branches
   - You can also trigger it manually from the Actions tab

4. **Manual trigger:**
   - Go to Actions tab in GitHub
   - Select "Deploy to Cloudflare Workers"
   - Click "Run workflow"

### Option 3: Manual Deployment

Follow the detailed step-by-step guide in [CLOUDFLARE_DEPLOY.md](../docs/CLOUDFLARE_DEPLOY.md).

## Prerequisites

Before deploying, ensure you have:

1. **Node.js 18+** installed
   ```bash
   node --version  # Should be v18.0.0 or higher
   ```

2. **npm** package manager
   ```bash
   npm --version
   ```

3. **Cloudflare Account** (free tier works)
   - Sign up at https://dash.cloudflare.com/sign-up

4. **Cloudflare API Token** (for automated deployment)
   - See "Creating a Cloudflare API Token" below

## Creating a Cloudflare API Token

1. Log in to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Go to **My Profile** → **API Tokens**
3. Click **Create Token**
4. Use the **"Edit Cloudflare Workers"** template
5. Configure permissions:
   - Account → Cloudflare Workers Scripts → Edit
   - Account → D1 → Edit  
   - Account → Workers KV Storage → Edit
6. Set Account Resources to include your account
7. Click **Continue to summary** → **Create Token**
8. **Copy the token** (you won't see it again!)

## Environment Variables

The deployment needs these environment variables:

### Required for Deployment
- `CLOUDFLARE_API_TOKEN` - Your Cloudflare API token

### Auto-Generated (optional)
- `JWT_SECRET` - Will be auto-generated if not provided

### Set in Cloudflare (managed by scripts)
- Database ID
- KV Namespace IDs
- Other Cloudflare-specific configs

## Deployment Artifacts

After deployment, you'll find:

- `deployment-info.txt` - Contains all deployment details
- `wrangler.toml.backup` - Backup of original config

## Deployment Workflow

Here's what happens during automated deployment:

```
1. Prerequisites Check
   ├─ Node.js version
   ├─ npm installed
   └─ Wrangler CLI (auto-installs if missing)

2. Cloudflare Authentication
   ├─ Check existing auth
   ├─ Use API token if provided
   └─ Interactive login if needed

3. Resource Creation
   ├─ Create D1 database (openauth_db)
   ├─ Create KV namespace (SESSIONS)
   └─ Create preview KV namespace

4. Configuration
   ├─ Update wrangler.toml with IDs
   ├─ Generate JWT_SECRET
   └─ Set Cloudflare secrets

5. Database Setup
   └─ Run all migrations from database/migrations/

6. Deployment
   ├─ Deploy worker to Cloudflare
   ├─ Get deployment URL
   └─ Test health endpoint

7. Post-Deployment
   ├─ Save deployment info
   └─ Display next steps
```

## Verifying Deployment

After deployment completes, verify it's working:

```bash
# Test health endpoint
curl https://your-worker.workers.dev/health

# Expected response:
# {"status":"healthy"}
```

```bash
# View real-time logs
wrangler tail

# Make a request to see logs
curl https://your-worker.workers.dev/auth
```

## Updating After Deployment

### Code Changes
```bash
# Test locally first
npm run dev

# Deploy update
./scripts/deploy-cloudflare.sh
# or
wrangler deploy
```

### Database Changes
```bash
# Create new migration file
# e.g., database/migrations/003_new_feature.sql

# Apply migration
wrangler d1 execute openauth_db --file=./database/migrations/003_new_feature.sql
```

### Secret Updates
```bash
# Update a secret
wrangler secret put JWT_SECRET

# List all secrets
wrangler secret list

# Delete a secret
wrangler secret delete SECRET_NAME
```

## Troubleshooting

### Authentication Issues
```bash
# Check current auth status
wrangler whoami

# Re-authenticate
wrangler login

# Or with API token
export CLOUDFLARE_API_TOKEN=your_token
wrangler whoami
```

### Deployment Fails
```bash
# Check for errors in detail
wrangler deploy --verbose

# Verify resources exist
wrangler d1 list
wrangler kv:namespace list

# Check bindings in wrangler.toml match resources
cat wrangler.toml
```

### Database Issues
```bash
# List databases
wrangler d1 list

# Check database tables
wrangler d1 execute openauth_db --command="SELECT name FROM sqlite_master WHERE type='table'"

# Re-run migrations
wrangler d1 execute openauth_db --file=./database/migrations/001_initial_schema.sql
```

### Worker Not Responding
```bash
# View logs
wrangler tail

# Check deployment status
wrangler deployments list

# Test locally
npm run dev
```

### "Resource Not Found" Errors
1. Verify resource IDs in wrangler.toml are correct
2. Check resources exist in Cloudflare dashboard
3. Ensure API token has correct permissions
4. Re-run the deployment script to create missing resources

## GitHub Actions Troubleshooting

### Workflow Fails
1. Check GitHub Actions logs for specific errors
2. Verify secrets are set correctly in repository settings
3. Ensure CLOUDFLARE_API_TOKEN has all required permissions
4. Check if resources were partially created (may need manual cleanup)

### Secrets Not Working
1. Go to repository Settings → Secrets and variables → Actions
2. Verify `CLOUDFLARE_API_TOKEN` is set
3. Verify `JWT_SECRET` is set (or let it be auto-generated)
4. Re-create secrets if they appear corrupted

## Cost Considerations

Cloudflare Workers pricing:

- **Free Tier**: 100,000 requests/day (suitable for development/testing)
- **Paid Plan**: $5/month for 10M requests, then $0.50 per additional 1M

Additional resources:
- **D1 Database**: Free tier includes 5GB storage
- **KV Storage**: Free tier includes 100,000 reads/day, 1,000 writes/day

**Estimated cost for small production**: $5-15/month

## Security Best Practices

1. **Never commit secrets** to Git
   - Use `wrangler secret put` for sensitive values
   - Keep `.env` and `.dev.vars` in `.gitignore`

2. **Rotate secrets regularly**
   - Update JWT_SECRET every 90 days
   - Rotate Cloudflare API tokens every 6 months

3. **Use minimal permissions**
   - API tokens should have only required permissions
   - Create separate tokens for CI/CD vs manual deployment

4. **Monitor logs**
   - Set up Cloudflare alerts for errors
   - Review logs weekly for suspicious activity

## Support

### Documentation
- [CLOUDFLARE_DEPLOY.md](../docs/CLOUDFLARE_DEPLOY.md) - Detailed deployment guide
- [Cloudflare Workers Docs](https://developers.cloudflare.com/workers/)
- [Wrangler CLI Docs](https://developers.cloudflare.com/workers/wrangler/)

### Community
- [Cloudflare Discord](https://discord.gg/cloudflaredev)
- [Cloudflare Community](https://community.cloudflare.com/)

### Issues
- GitHub Issues: Report bugs or request features
- Cloudflare Support: For platform-specific issues

## Next Steps After Deployment

1. ✅ Test all endpoints
2. ✅ Configure custom domain (optional)
3. ✅ Set up monitoring and alerts
4. ✅ Deploy frontend to Cloudflare Pages
5. ✅ Configure SSO providers
6. ✅ Set up backup/recovery procedures
7. ✅ Document deployment for team

## Advanced Configuration

### Custom Domains
```bash
# Add via Cloudflare dashboard
# Workers & Pages → your-worker → Settings → Triggers → Add Custom Domain
```

### Environment-Specific Deployments
```bash
# Deploy to staging
wrangler deploy --env staging

# Deploy to production  
wrangler deploy --env production
```

### Monitoring Integration
- Set up Cloudflare Logpush
- Integrate with Sentry, DataDog, or other monitoring tools
- Configure email alerts for errors

---

**Last Updated**: October 2024

For the most up-to-date information, see the [main documentation](../docs/CLOUDFLARE_DEPLOY.md).
