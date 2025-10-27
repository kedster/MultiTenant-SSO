# Quick Deployment Reference

This is a condensed, step-by-step reference for deploying to Cloudflare. For detailed explanations, see [CLOUDFLARE_DEPLOY.md](./CLOUDFLARE_DEPLOY.md).

## Prerequisites Checklist

- [ ] Node.js 18+ installed
- [ ] Cloudflare account created
- [ ] Git repository cloned

## Quick Setup (5 Minutes)

### 1. Install Wrangler

```bash
npm install -g wrangler
```

### 2. Authenticate

```bash
wrangler login
```

### 3. Run Automated Setup Script

```bash
cd MultiTenant-SSO
./deploy-setup.sh
```

The script will:
- Install dependencies
- Create D1 database
- Create KV namespaces
- Generate and set secrets
- Run migrations
- Deploy to Cloudflare

Follow the prompts and save any IDs shown!

## Manual Setup (If Script Fails)

### 1. Install Dependencies

```bash
npm install
```

### 2. Create Resources

```bash
# Create D1 database
wrangler d1 create openauth_db

# Create KV namespace
wrangler kv:namespace create SESSIONS

# Create preview KV namespace
wrangler kv:namespace create SESSIONS --preview
```

### 3. Update wrangler.toml

Replace the placeholder IDs with the IDs from step 2:

```toml
[[kv_namespaces]]
binding = "SESSIONS"
id = "your-kv-namespace-id"
preview_id = "your-preview-kv-namespace-id"

[[d1_databases]]
binding = "DB"
database_name = "openauth_db"
database_id = "your-database-id"
```

### 4. Set Secrets

```bash
# Generate secret
openssl rand -base64 32

# Set secret (paste the generated value when prompted)
wrangler secret put JWT_SECRET
```

### 5. Create .dev.vars

```bash
echo "JWT_SECRET=$(openssl rand -base64 32)" > .dev.vars
echo "ENVIRONMENT=development" >> .dev.vars
```

### 6. Run Migrations

```bash
wrangler d1 execute openauth_db --file=./database/migrations/001_initial_schema.sql
wrangler d1 execute openauth_db --file=./database/migrations/002_add_sso_billing.sql
```

### 7. Deploy

```bash
npm run deploy
```

## Verification

```bash
# Test health endpoint
curl https://openauth-enterprise.YOUR_SUBDOMAIN.workers.dev/health

# View logs
wrangler tail

# Check dashboard
# Visit: https://dash.cloudflare.com → Workers & Pages → openauth-enterprise
```

## Common Commands

```bash
# Deploy
npm run deploy

# Local development
npm run dev

# View logs
wrangler tail

# List resources
wrangler d1 list
wrangler kv:namespace list
wrangler secret list

# Run migration
wrangler d1 execute openauth_db --file=./database/migrations/XXX.sql

# Rollback deployment
wrangler rollback <deployment-id>

# Update secret
wrangler secret put SECRET_NAME
```

## Accessing Cloudflare Dashboard

### New Dashboard (2024+)

1. **Navigate**: https://dash.cloudflare.com
2. **Workers & Pages**: Left sidebar → Click on your worker
3. **Metrics**: View performance and usage
4. **Logs**: Real-time request logs
5. **Settings**: Environment variables, triggers, domains
6. **D1**: Left sidebar → D1 → openauth_db
7. **KV**: Left sidebar → KV → SESSIONS

### Key Dashboard Features

- **Real-time metrics**: Requests, errors, duration
- **Query console**: Run SQL directly on D1
- **KV browser**: View/edit KV pairs
- **Log streaming**: Live request logs
- **Custom domains**: Add your own domains
- **Alerts**: Set up notifications

## Troubleshooting Quick Fixes

### "Not authenticated"
```bash
wrangler login
```

### "Resource not found"
```bash
wrangler d1 list          # Check database exists
wrangler kv:namespace list # Check KV exists
# Update IDs in wrangler.toml
```

### "Secret not found"
```bash
wrangler secret put JWT_SECRET
```

### "Deployment fails"
```bash
npm install              # Reinstall dependencies
npx tsc --noEmit        # Check for TypeScript errors
wrangler deploy --dry-run # Test configuration
```

### "Worker returns 500"
```bash
wrangler tail           # Check logs for errors
# Verify bindings in wrangler.toml match code
```

### "Database query fails"
```bash
# Verify migrations ran
wrangler d1 execute openauth_db --command="SELECT name FROM sqlite_master WHERE type='table'"
# Re-run migrations if needed
```

## Cost Estimate

**Free Tier:**
- 100,000 requests/day
- Good for development and testing

**Paid ($5-20/month):**
- 10M requests/month
- 5GB D1 storage
- 1GB KV storage
- Production-ready

## Support Resources

- **Full Guide**: [docs/CLOUDFLARE_DEPLOY.md](./CLOUDFLARE_DEPLOY.md)
- **Cloudflare Docs**: https://developers.cloudflare.com/workers/
- **Discord**: https://discord.gg/cloudflaredev
- **Community**: https://community.cloudflare.com/

## Post-Deployment

- [ ] Test health endpoint
- [ ] Verify logs show no errors
- [ ] Set up monitoring alerts
- [ ] Configure custom domain (optional)
- [ ] Deploy frontend
- [ ] Update documentation with live URLs
- [ ] Share access with team

---

**Need Help?** See the detailed guide: [CLOUDFLARE_DEPLOY.md](./CLOUDFLARE_DEPLOY.md)
