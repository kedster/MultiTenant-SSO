# OpenAuth Enterprise - Multi-Tenant SSO

A comprehensive multi-tenant Single Sign-On (SSO) solution built on Cloudflare Workers, providing OAuth2/OpenID Connect authentication for multiple organizations and applications.

## 🎯 Features

- **Multi-Tenant Architecture**: Support multiple organizations with isolated data
- **OAuth2/OIDC Provider**: Full OAuth2 and OpenID Connect implementation
- **SSO Federation**: Integrate with Azure AD, Google Workspace, Okta via SAML/OIDC
- **Admin Portal**: React-based dashboard for managing users, orgs, and apps
- **Scalable**: Built on Cloudflare Workers for serverless scalability
- **Subscription Management**: Built-in billing and licensing system
- **Audit Logging**: Complete audit trail of authentication events
- **Multi-Domain Support**: SSO across 11+ internal domains

## 🏗️ Architecture

- **Backend**: TypeScript on Cloudflare Workers
- **Database**: D1 (SQLite-compatible) for relational data
- **Session Store**: KV Namespace for fast session management
- **Frontend**: React with TypeScript and Tailwind CSS
- **Auth**: JWT-based authentication with refresh tokens

## 📁 Project Structure

```
openauth-enterprise/
├── src/                    # Backend source code (Cloudflare Worker)
│   ├── index.ts           # Worker entrypoint and routing
│   ├── auth/              # Authentication modules
│   │   ├── login.ts       # Login endpoint
│   │   ├── register.ts    # User/org registration
│   │   ├── token.ts       # JWT issuance/refresh
│   │   └── sso.ts         # SAML/OIDC federation
│   ├── admin/             # Admin management modules
│   │   ├── org.ts         # Organization CRUD
│   │   ├── users.ts       # User CRUD/invite
│   │   └── billing.ts     # Stripe/Paddle integration
│   └── utils/             # Utility functions
│       ├── db.ts          # D1 database helpers
│       ├── jwt.ts         # JWT sign/verify helpers
│       └── kv.ts          # KV session helpers
├── frontend/              # Frontend React admin portal
│   └── src/
│       ├── pages/         # React pages (Login, Dashboard, Users)
│       ├── api/           # API client for backend
│       └── components/    # Reusable UI components
├── database/              # Database schemas and migrations
│   ├── schema.sql         # Complete database schema
│   └── migrations/        # Incremental migration files
├── docs/                  # Documentation
│   ├── GETTING_STARTED.md # Quick start guide
│   ├── API.md             # API documentation
│   └── DEVELOPMENT.md     # Development guide
├── package.json           # Backend dependencies
├── tsconfig.json          # TypeScript configuration
└── wrangler.toml          # Cloudflare Workers config
```

## 🚀 Quick Start

### Prerequisites

- Node.js 18+
- npm or yarn
- Cloudflare account
- Wrangler CLI: `npm install -g wrangler`

### Installation

```bash
# Clone the repository
git clone https://github.com/kedster/MultiTenant-SSO.git
cd MultiTenant-SSO

# Install backend dependencies
npm install

# Install frontend dependencies
cd frontend && npm install && cd ..

# Authenticate with Cloudflare
wrangler login

# Create D1 database
wrangler d1 create openauth_db
# Update wrangler.toml with the database ID

# Create KV namespace
wrangler kv:namespace create SESSIONS
# Update wrangler.toml with the namespace ID

# Run database migrations
wrangler d1 execute openauth_db --file=./database/migrations/001_initial_schema.sql
wrangler d1 execute openauth_db --file=./database/migrations/002_add_sso_billing.sql

# Create .dev.vars file for local development
echo "JWT_SECRET=your-secret-key-here" > .dev.vars
echo "ENVIRONMENT=development" >> .dev.vars
```

### Development

```bash
# Start backend (Terminal 1)
npm run dev
# Backend available at http://localhost:8787

# Start frontend (Terminal 2)
cd frontend && npm run dev
# Frontend available at http://localhost:3000
```

### Deployment

```bash
# Deploy backend to Cloudflare Workers
npm run deploy

# Build and deploy frontend
cd frontend
npm run build
# Deploy dist/ folder to your hosting provider
```

## 📚 Documentation

- **[Getting Started Guide](./docs/GETTING_STARTED.md)** - Detailed setup instructions
- **[API Documentation](./docs/API.md)** - Complete API reference
- **[Development Guide](./docs/DEVELOPMENT.md)** - Development workflow and best practices

## 🔑 Key Components

### Authentication Flow

1. User accesses application
2. Redirect to OpenAuth `/authorize` endpoint
3. User authenticates (local or SSO federation)
4. JWT token issued with org/app/role claims
5. App validates token via JWKS or introspection
6. Single sign-on across all domains

### Database Schema

- **organizations**: Organization/tenant information
- **users**: User accounts with roles and federated IDs
- **applications**: Registered OAuth2 applications
- **tenant_apps**: Organization app access permissions
- **sso_configs**: SSO provider configurations
- **subscriptions**: Billing and subscription data
- **audit_logs**: Complete audit trail
- **invitations**: User invitation management

### API Endpoints

- `/auth/login` - User authentication
- `/auth/register/org` - Organization registration
- `/auth/sso/initiate` - SSO login initiation
- `/auth/token/refresh` - Token refresh
- `/admin/orgs` - Organization management
- `/admin/users` - User management
- `/admin/orgs/:id/apps` - App access control

## 🛠️ Technology Stack

- **Runtime**: Cloudflare Workers (V8 isolates)
- **Language**: TypeScript
- **Frontend**: React 18, Tailwind CSS, Vite
- **Database**: Cloudflare D1 (SQLite)
- **Storage**: Cloudflare KV
- **Auth Libraries**: 
  - `jsonwebtoken` - JWT handling
  - `openid-client` - OIDC integration
  - `passport-saml` - SAML integration

## 🔐 Security Features

- JWT-based authentication with short-lived access tokens
- Refresh token rotation
- Token revocation via KV store
- CORS headers for API security
- Password hashing (to be implemented)
- Audit logging for all authentication events
- Multi-factor authentication support (planned)

## 📈 Roadmap

- [ ] Complete authentication implementation
- [ ] SSO provider integrations (Azure AD, Google, Okta)
- [ ] Billing integration (Stripe/Paddle)
- [ ] SCIM auto-provisioning
- [ ] Custom branding per organization
- [ ] Advanced analytics and reporting
- [ ] Mobile app support
- [ ] Webhook notifications
- [ ] Rate limiting and DDoS protection

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines before submitting pull requests.

## 📄 License

MIT License - see LICENSE file for details

## 🔗 Resources

- [Cloudflare Workers Documentation](https://developers.cloudflare.com/workers/)
- [D1 Database Documentation](https://developers.cloudflare.com/d1/)
- [OAuth 2.0 Specification](https://oauth.net/2/)
- [OpenID Connect Specification](https://openid.net/connect/)

## 💬 Support

For issues, questions, or feature requests, please open an issue on GitHub.

---

Built with ❤️ for enterprise multi-tenant SSO
