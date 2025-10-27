# Development Guide

## Setting Up Your Development Environment

### Prerequisites

1. **Node.js 18+** - [Download](https://nodejs.org/)
2. **Git** - [Download](https://git-scm.com/)
3. **Cloudflare Account** - [Sign up](https://dash.cloudflare.com/sign-up)
4. **Wrangler CLI** - Install via npm: `npm install -g wrangler`

### Initial Setup

1. Clone the repository and install dependencies:
   ```bash
   git clone https://github.com/kedster/MultiTenant-SSO.git
   cd MultiTenant-SSO
   npm install
   cd frontend && npm install && cd ..
   ```

2. Authenticate with Cloudflare:
   ```bash
   wrangler login
   ```

3. Create D1 database:
   ```bash
   wrangler d1 create openauth_db
   ```
   Copy the database ID to `wrangler.toml`

4. Create KV namespace:
   ```bash
   wrangler kv:namespace create SESSIONS
   ```
   Copy the namespace ID to `wrangler.toml`

5. Run database migrations:
   ```bash
   wrangler d1 execute openauth_db --file=./database/migrations/001_initial_schema.sql
   wrangler d1 execute openauth_db --file=./database/migrations/002_add_sso_billing.sql
   ```

6. Create `.dev.vars` file:
   ```
   JWT_SECRET=your-development-secret-key
   ENVIRONMENT=development
   ```

## Running Locally

### Backend (Cloudflare Worker)

Start the development server:
```bash
npm run dev
```

The worker will be available at `http://localhost:8787`

### Frontend (React App)

In a separate terminal:
```bash
cd frontend
npm run dev
```

The frontend will be available at `http://localhost:3000`

## Code Structure

### Backend (`src/`)

- **index.ts** - Main worker entry point, routing
- **auth/** - Authentication logic
  - `login.ts` - Login handling
  - `register.ts` - Registration
  - `token.ts` - JWT management
  - `sso.ts` - SSO federation
- **admin/** - Admin functionality
  - `org.ts` - Organization management
  - `users.ts` - User management
  - `billing.ts` - Billing integration
- **utils/** - Helper functions
  - `db.ts` - Database utilities
  - `jwt.ts` - JWT utilities
  - `kv.ts` - KV store utilities

### Frontend (`frontend/src/`)

- **App.tsx** - Main React component
- **pages/** - Page components
  - `Login.tsx` - Login page
  - `Dashboard.tsx` - Dashboard page
  - `Users.tsx` - User management page
- **api/** - API client
  - `apiClient.ts` - Backend communication
- **components/** - Reusable components (to be added)

## Development Workflow

1. **Create a feature branch**
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Make changes** to the code

3. **Test locally** using the dev servers

4. **Commit changes**
   ```bash
   git add .
   git commit -m "Description of changes"
   ```

5. **Push to repository**
   ```bash
   git push origin feature/my-feature
   ```

6. **Create a pull request** on GitHub

## Testing

### Backend Testing

```bash
npm test
```

### Frontend Testing

```bash
cd frontend
npm test
```

## Linting and Formatting

### Backend

```bash
npm run lint
npm run format
```

### Frontend

```bash
cd frontend
npm run lint
npm run format
```

## Database Management

### Run a migration

```bash
wrangler d1 execute openauth_db --file=./database/migrations/YOUR_MIGRATION.sql
```

### Query the database

```bash
wrangler d1 execute openauth_db --command="SELECT * FROM organizations"
```

### Reset database (development only)

```bash
wrangler d1 execute openauth_db --file=./database/schema.sql
```

## Debugging

### Worker Logs

View real-time logs:
```bash
wrangler tail
```

### KV Store Inspection

List keys:
```bash
wrangler kv:key list --namespace-id=YOUR_NAMESPACE_ID
```

Get value:
```bash
wrangler kv:key get "KEY_NAME" --namespace-id=YOUR_NAMESPACE_ID
```

## Common Issues

### Port already in use

If port 8787 or 3000 is already in use:
- Backend: Kill the process or change the port in `wrangler.toml`
- Frontend: Kill the process or change the port in `vite.config.ts`

### D1 database not found

Make sure you've:
1. Created the database with `wrangler d1 create`
2. Updated the database ID in `wrangler.toml`
3. Run the migrations

### KV namespace errors

Ensure your KV namespace is created and the ID is correct in `wrangler.toml`

## Next Steps

- Implement authentication logic in `src/auth/`
- Add more pages to the frontend
- Set up SSO providers
- Configure billing integration
- Add tests
