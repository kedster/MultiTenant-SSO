openauth-enterprise/
├── package.json
├── tsconfig.json
├── wrangler.toml           # Cloudflare Workers config
├── src/
│   ├── index.ts            # Worker entrypoint
│   ├── auth/
│   │   ├── login.ts        # login endpoint
│   │   ├── register.ts     # user/org registration
│   │   ├── token.ts        # JWT issuance / refresh
│   │   └── sso.ts          # SAML/OIDC federation endpoints
│   ├── admin/
│   │   ├── org.ts          # Org CRUD / app access
│   │   ├── users.ts        # User CRUD / invite
│   │   └── billing.ts      # Stripe / Paddle integration
│   └── utils/
│       ├── db.ts           # D1 queries
│       ├── jwt.ts          # JWT sign/verify helpers
│       └── kv.ts           # KV session helpers
└── frontend/
    ├── package.json
    ├── tsconfig.json
    └── src/
        ├── App.tsx         # React admin portal
        ├── pages/
        │   ├── Login.tsx
        │   ├── Dashboard.tsx
        │   └── Users.tsx
        └── api/
            └── apiClient.ts # calls Worker endpoints
