# Cloudflare Deployment Guide

This comprehensive guide will help you deploy the OpenAuth Enterprise Multi-Tenant SSO application to Cloudflare Workers, including all necessary resources (D1 Database, KV Namespaces, environment variables, and secrets).

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Cloudflare Account Setup](#cloudflare-account-setup)
3. [Install and Authenticate Wrangler CLI](#install-and-authenticate-wrangler-cli)
4. [Create Required Cloudflare Resources](#create-required-cloudflare-resources)
5. [Configure the Application](#configure-the-application)
6. [Deploy the Worker](#deploy-the-worker)
7. [Verify Deployment](#verify-deployment)
8. [Accessing the New Cloudflare Dashboard](#accessing-the-new-cloudflare-dashboard)
9. [Troubleshooting](#troubleshooting)
10. [Post-Deployment Updates](#post-deployment-updates)

---

## Prerequisites

Before starting, ensure you have:

- **Node.js** version 18 or higher installed
- **npm** or **yarn** package manager
- A **Cloudflare account** (free tier works for testing)
- **Git** installed (to clone the repository)
- **Command line/terminal** access

### Check Your Versions

```bash
node --version    # Should be v18.0.0 or higher
npm --version     # Should be 8.0.0 or higher
git --version     # Should be 2.0.0 or higher
```

---

## Cloudflare Account Setup

### 1. Create a Cloudflare Account

If you don't have one already:

1. Go to [https://dash.cloudflare.com/sign-up](https://dash.cloudflare.com/sign-up)
2. Sign up with your email and create a password
3. Verify your email address
4. Complete the onboarding process

### 2. Generate an API Token

For deployment, you need an API token with the right permissions:

1. Log in to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Go to **My Profile** (top right corner) → **API Tokens**
3. Click **Create Token**
4. Use the **"Edit Cloudflare Workers"** template
5. Configure the token:
   - **Permissions**: 
     - Account → Cloudflare Workers Scripts → Edit
     - Account → D1 → Edit
     - Account → Workers KV Storage → Edit
   - **Account Resources**: Include your account
   - **Zone Resources**: Not required (unless you have custom domains)
6. Click **Continue to summary** → **Create Token**
7. **IMPORTANT**: Copy the token immediately (you won't see it again)
8. Save it securely (e.g., password manager)

---

## Install and Authenticate Wrangler CLI

Wrangler is the official CLI tool for managing Cloudflare Workers.

### 1. Install Wrangler Globally

```bash
npm install -g wrangler
```

Verify installation:

```bash
wrangler --version
# Should display version 3.x.x or higher
```

### 2. Authenticate Wrangler

You have two authentication options:

#### Option A: Interactive Login (Recommended)

```bash
wrangler login
```

This will:
1. Open your browser
2. Ask you to log in to Cloudflare
3. Grant permission to Wrangler
4. Save credentials locally

#### Option B: Use API Token

If you can't use interactive login:

```bash
export CLOUDFLARE_API_TOKEN="your-api-token-here"
```

Or create a `.env` file in your project root:

```bash
CLOUDFLARE_API_TOKEN=your-api-token-here
```

### 3. Verify Authentication

```bash
wrangler whoami
```

You should see your account email and Account ID.

---

## Create Required Cloudflare Resources

The application requires several Cloudflare resources. We'll create them one by one.

### 1. Navigate to Project Directory

```bash
cd /path/to/MultiTenant-SSO
```

### 2. Install Project Dependencies

```bash
npm install
```

### 3. Create D1 Database

D1 is Cloudflare's serverless SQL database.

```bash
wrangler d1 create openauth_db
```

**Output Example:**
```
✅ Successfully created DB 'openauth_db'!

[[d1_databases]]
binding = "DB"
database_name = "openauth_db"
database_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

**IMPORTANT**: Copy the `database_id` value - you'll need it soon!

### 4. Create KV Namespace for Sessions

KV (Key-Value) storage is used for session management.

```bash
wrangler kv:namespace create SESSIONS
```

**Output Example:**
```
🌀 Creating namespace with title "openauth-enterprise-SESSIONS"
✨ Success!
Add the following to your configuration file in your kv_namespaces array:
{ binding = "SESSIONS", id = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" }
```

**IMPORTANT**: Copy the `id` value for the production namespace.

### 5. Create Preview KV Namespace (for Development)

```bash
wrangler kv:namespace create SESSIONS --preview
```

**Output Example:**
```
🌀 Creating namespace with title "openauth-enterprise-SESSIONS_preview"
✨ Success!
Add the following to your configuration file in your kv_namespaces array:
{ binding = "SESSIONS", preview_id = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" }
```

**IMPORTANT**: Copy the `preview_id` value.

---

## Configure the Application

### 1. Update wrangler.toml

Open `wrangler.toml` in your editor and update with the IDs you collected:

```toml
name = "openauth-enterprise"
main = "src/index.ts"
compatibility_date = "2024-01-01"
workers_dev = true

# KV Namespaces for session storage
[[kv_namespaces]]
binding = "SESSIONS"
id = "YOUR_KV_NAMESPACE_ID_HERE"
preview_id = "YOUR_PREVIEW_KV_NAMESPACE_ID_HERE"

# D1 Database for multi-tenant data
[[d1_databases]]
binding = "DB"
database_name = "openauth_db"
database_id = "YOUR_DATABASE_ID_HERE"

# Environment variables (non-sensitive)
[vars]
ENVIRONMENT = "production"
```

**Replace**:
- `YOUR_KV_NAMESPACE_ID_HERE` with your KV namespace ID
- `YOUR_PREVIEW_KV_NAMESPACE_ID_HERE` with your preview KV namespace ID
- `YOUR_DATABASE_ID_HERE` with your D1 database ID

### 2. Set Secrets (Sensitive Environment Variables)

Secrets are encrypted environment variables that shouldn't be in `wrangler.toml`.

#### Generate a Secure JWT Secret

```bash
# On Linux/Mac:
openssl rand -base64 32

# Or use Node.js:
node -e "console.log(require('crypto').randomBytes(32).toString('base64'))"
```

#### Set the JWT Secret

```bash
wrangler secret put JWT_SECRET
```

When prompted, paste your generated secret and press Enter.

**Verification:**

```bash
wrangler secret list
```

You should see `JWT_SECRET` in the list.

### 3. Create .dev.vars for Local Development

Create a `.dev.vars` file in the project root (this is already gitignored):

```bash
JWT_SECRET=your-development-jwt-secret-here
ENVIRONMENT=development
```

This file is used for local development only and is NOT deployed.

---

## Deploy the Worker

### 1. Run Database Migrations

Before deploying, initialize the database with the schema:

```bash
# Run the initial schema migration
wrangler d1 execute openauth_db --file=./database/migrations/001_initial_schema.sql

# Run additional migrations
wrangler d1 execute openauth_db --file=./database/migrations/002_add_sso_billing.sql
```

**Expected Output:**
```
🌀 Executing on openauth_db (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx):
🌀 To execute on your local development database, pass the --local flag to 'wrangler d1 execute'
✅ Executed 001_initial_schema.sql:
```

### 2. Build and Deploy

```bash
npm run deploy
```

Or directly:

```bash
wrangler deploy
```

**Expected Output:**
```
⛅️ wrangler 3.x.x
-------------------------------------------------------
Your worker has access to the following bindings:
- D1 Databases:
  - DB: openauth_db (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
- KV Namespaces:
  - SESSIONS: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
- Vars:
  - ENVIRONMENT: "production"
Total Upload: XX.XX KiB / gzip: XX.XX KiB
Uploaded openauth-enterprise (X.XX sec)
Published openauth-enterprise (X.XX sec)
  https://openauth-enterprise.YOUR_SUBDOMAIN.workers.dev
Current Deployment ID: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

**IMPORTANT**: Save the deployment URL! This is where your application is now live.

---

## Verify Deployment

### 1. Test the Health Endpoint

```bash
curl https://openauth-enterprise.YOUR_SUBDOMAIN.workers.dev/health
```

**Expected Response:**
```json
{"status":"healthy"}
```

### 2. Check Worker Logs

View real-time logs:

```bash
wrangler tail
```

This shows live request logs as they come in.

### 3. Test Basic Routes

```bash
# Test auth routes
curl https://openauth-enterprise.YOUR_SUBDOMAIN.workers.dev/auth

# Test admin routes
curl https://openauth-enterprise.YOUR_SUBDOMAIN.workers.dev/admin
```

---

## Accessing the New Cloudflare Dashboard

Cloudflare has modernized their dashboard interface. Here's how to navigate it:

### 1. Access Workers & Pages

1. Go to [https://dash.cloudflare.com](https://dash.cloudflare.com)
2. Select your account
3. Click **Workers & Pages** in the left sidebar

### 2. View Your Worker

1. You'll see a list of all your Workers
2. Find and click **openauth-enterprise**
3. You'll see:
   - **Deployment status** (Active/Inactive)
   - **Current version**
   - **Request metrics** (requests/sec, errors, duration)
   - **Recent deployments**

### 3. Monitor Performance

Click on the **Metrics** tab:
- **Requests**: Total requests over time
- **Errors**: Error rate and counts
- **Duration**: P50, P75, P99 response times
- **CPU Time**: Execution time statistics

### 4. View Logs

Click on the **Logs** tab:
- **Real-time Logs**: See live request logs
- **Tail Workers**: Same as `wrangler tail` but in the browser
- **Filter by**: Status code, method, path
- **Export logs**: Download for analysis

### 5. Manage Settings

Click on the **Settings** tab:
- **Variables**: View/edit environment variables (non-sensitive)
- **Environment Variables & Secrets**: Manage secrets
- **Triggers**: Configure custom domains and routes
- **Build**: Configure build settings
- **Observability**: Set up logging destinations

### 6. Access D1 Database

1. Go back to the main account dashboard
2. Click **D1** in the left sidebar (under Storage & Databases)
3. Click **openauth_db**
4. You can:
   - **Run SQL queries** directly in the browser
   - **View tables** and their data
   - **Export data** as CSV
   - **View metrics** (queries/sec, storage used)

### 7. Access KV Namespaces

1. Go back to the main account dashboard
2. Click **KV** in the left sidebar (under Storage & Databases)
3. Click your **SESSIONS** namespace
4. You can:
   - **View all keys** in the namespace
   - **Add/edit/delete** key-value pairs manually
   - **Search keys** by prefix
   - **View metrics** (reads/writes, storage used)

### 8. Set Up Alerts (Recommended)

1. Go to **Account Home** → **Notifications**
2. Click **Add** to create a new alert
3. Configure alerts for:
   - **High error rate** (>5% errors)
   - **High CPU usage** (>80% CPU time)
   - **Quota warnings** (approaching plan limits)

---

## Troubleshooting

### Common Issues and Solutions

#### 1. "Error: Not authenticated"

**Solution:**
```bash
wrangler login
# Or
export CLOUDFLARE_API_TOKEN="your-token"
```

#### 2. "Error: Resource not found" (D1 Database)

**Solution:**
- Verify the database exists: `wrangler d1 list`
- Check `wrangler.toml` has the correct `database_id`
- Re-run migrations if database is empty

#### 3. "Error: KV namespace not found"

**Solution:**
- Verify the namespace exists: `wrangler kv:namespace list`
- Check `wrangler.toml` has the correct `id` and `preview_id`

#### 4. "Error: Secret JWT_SECRET not found"

**Solution:**
```bash
wrangler secret put JWT_SECRET
# Enter your secret when prompted
```

#### 5. "Deployment succeeds but Worker returns 500 errors"

**Solution:**
- Check logs: `wrangler tail`
- Verify all bindings are correct in `wrangler.toml`
- Ensure database migrations ran successfully
- Check that secrets are set

#### 6. "Build fails with TypeScript errors"

**Solution:**
```bash
# Install dependencies
npm install

# Check for TypeScript errors
npx tsc --noEmit

# Fix errors in the code
```

#### 7. "Cannot access D1 database during execution"

**Solution:**
- Ensure the database binding name in code matches `wrangler.toml` (should be "DB")
- Check database ID is correct
- Verify migrations ran: `wrangler d1 execute openauth_db --command="SELECT name FROM sqlite_master WHERE type='table'"`

### Debugging Commands

```bash
# List all Workers
wrangler deployments list

# View recent deployments
wrangler deployments list --name openauth-enterprise

# View secrets
wrangler secret list

# View KV namespaces
wrangler kv:namespace list

# View D1 databases
wrangler d1 list

# Check D1 database tables
wrangler d1 execute openauth_db --command="SELECT name FROM sqlite_master WHERE type='table'"

# View worker configuration
wrangler deploy --dry-run
```

### Get Help

- **Cloudflare Docs**: [https://developers.cloudflare.com/workers/](https://developers.cloudflare.com/workers/)
- **Cloudflare Discord**: [https://discord.gg/cloudflaredev](https://discord.gg/cloudflaredev)
- **Wrangler GitHub**: [https://github.com/cloudflare/workers-sdk](https://github.com/cloudflare/workers-sdk)
- **Community Forum**: [https://community.cloudflare.com/](https://community.cloudflare.com/)

---

## Post-Deployment Updates

### Deploying Code Changes

After making changes to the code:

```bash
# 1. Test locally first
npm run dev

# 2. Deploy to production
npm run deploy

# 3. Verify deployment
curl https://openauth-enterprise.YOUR_SUBDOMAIN.workers.dev/health
```

### Database Schema Changes

For new migrations:

```bash
# Create a new migration file
# Example: database/migrations/003_add_new_feature.sql

# Apply the migration
wrangler d1 execute openauth_db --file=./database/migrations/003_add_new_feature.sql
```

### Updating Environment Variables

**Non-sensitive variables** (in `wrangler.toml`):
1. Edit `wrangler.toml`
2. Re-deploy: `npm run deploy`

**Secrets**:
```bash
wrangler secret put SECRET_NAME
```

### Rollback to Previous Version

If a deployment causes issues:

```bash
# List recent deployments
wrangler deployments list --name openauth-enterprise

# Rollback to a specific deployment
wrangler rollback <deployment-id>
```

### Update Wrangler

Keep Wrangler up to date:

```bash
npm update -g wrangler
```

---

## Custom Domain Setup (Optional)

To use your own domain instead of `*.workers.dev`:

### 1. Add Domain to Cloudflare

1. Go to [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Click **Add site**
3. Enter your domain (e.g., `auth.yourdomain.com`)
4. Follow the setup wizard to change nameservers

### 2. Add Route to Worker

1. Go to **Workers & Pages** → **openauth-enterprise**
2. Click **Settings** → **Triggers**
3. Click **Add Custom Domain**
4. Enter your subdomain (e.g., `auth.yourdomain.com`)
5. Click **Add Custom Domain**

Cloudflare will automatically:
- Issue an SSL certificate
- Route traffic to your Worker
- Handle HTTPS

### 3. Update CORS Settings

If using a custom domain, update CORS in `src/index.ts`:

```typescript
const corsHeaders = {
  'Access-Control-Allow-Origin': 'https://auth.yourdomain.com',
  // ... other headers
};
```

---

## Production Checklist

Before going live with production traffic:

- [ ] All secrets are set (`JWT_SECRET`, etc.)
- [ ] Database migrations are complete
- [ ] KV namespaces are created and configured
- [ ] Health endpoint returns 200 OK
- [ ] Basic auth/admin routes respond correctly
- [ ] Logs show no errors (`wrangler tail`)
- [ ] Alerts are configured for errors and high usage
- [ ] Custom domain is set up (if using)
- [ ] SSL certificate is active
- [ ] CORS settings are correct for your frontend
- [ ] Rate limiting is configured (if needed)
- [ ] Backup/recovery plan is documented
- [ ] Team has access to Cloudflare dashboard
- [ ] Documentation is updated with deployment URL

---

## Security Best Practices

1. **Never commit secrets** to Git
   - Use `wrangler secret put` for sensitive values
   - Keep `.dev.vars` in `.gitignore`

2. **Rotate JWT secrets regularly**
   - Update every 90 days
   - Use `wrangler secret put JWT_SECRET`

3. **Use API tokens with minimal permissions**
   - Create separate tokens for CI/CD vs manual deployment
   - Rotate tokens every 6 months

4. **Enable Cloudflare Access** for admin routes
   - Add authentication layer to `/admin/*` routes
   - Use Cloudflare Access policies

5. **Monitor security logs**
   - Set up alerts for unusual patterns
   - Review logs weekly

6. **Keep dependencies updated**
   - Run `npm audit` regularly
   - Update Wrangler monthly

---

## Cost Estimation

Cloudflare Workers pricing (as of 2024):

### Free Tier
- 100,000 requests/day
- 10 ms CPU time per request
- Sufficient for development and small deployments

### Paid Plan ($5/month)
- 10 million requests/month included
- Additional requests: $0.50 per million
- 50 ms CPU time per request

### D1 Database
- Free tier: 5 GB storage, 5 million rows read/day
- Paid: $5/month per 5 GB

### KV Storage
- Free tier: 100,000 reads/day, 1,000 writes/day, 1 GB storage
- Paid: $0.50 per million reads, $5.00 per million writes

**Estimated monthly cost for moderate usage**: $10-20/month

---

## Next Steps

1. **Deploy the Frontend**
   - Deploy React admin portal to Cloudflare Pages
   - See `frontend/README.md` for instructions

2. **Configure SSO Providers**
   - Set up Azure AD, Google Workspace integrations
   - Add SAML metadata to database

3. **Set Up Monitoring**
   - Integrate with external monitoring (DataDog, Sentry)
   - Configure alerting

4. **Load Testing**
   - Test with realistic traffic patterns
   - Optimize database queries
   - Configure caching

5. **Documentation**
   - Document API endpoints for integration
   - Create user guides for admin portal
   - Write runbooks for common operations

---

## Support

For issues specific to this application:
- Open an issue on GitHub
- Check existing documentation in `/docs`
- Review Cloudflare Workers documentation

For Cloudflare-specific issues:
- Cloudflare Support: [https://support.cloudflare.com/](https://support.cloudflare.com/)
- Community Forums: [https://community.cloudflare.com/](https://community.cloudflare.com/)
- Developer Discord: [https://discord.gg/cloudflaredev](https://discord.gg/cloudflaredev)

---

**Last Updated**: October 2024

This guide is maintained as part of the OpenAuth Enterprise project. For updates or corrections, please submit a pull request.
