-- Database Schema for OpenAuth Enterprise Multi-Tenant SSO
-- D1 SQLite Database

-- Organizations Table
CREATE TABLE IF NOT EXISTS organizations (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  domain TEXT UNIQUE NOT NULL,
  subscription_tier TEXT DEFAULT 'free',
  status TEXT DEFAULT 'trial',
  max_users INTEGER DEFAULT 10,
  max_apps INTEGER DEFAULT 5,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Users Table
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT,
  org_id TEXT NOT NULL,
  roles TEXT NOT NULL, -- JSON array of roles
  status TEXT DEFAULT 'invited',
  federated_id TEXT,
  last_login DATETIME,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (org_id) REFERENCES organizations(id) ON DELETE CASCADE
);

CREATE INDEX idx_users_org_id ON users(org_id);
CREATE INDEX idx_users_email ON users(email);

-- Applications Table
CREATE TABLE IF NOT EXISTS applications (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  domain TEXT UNIQUE NOT NULL,
  description TEXT,
  oauth_client_id TEXT UNIQUE NOT NULL,
  oauth_client_secret TEXT NOT NULL,
  redirect_uris TEXT NOT NULL, -- JSON array
  allowed_scopes TEXT NOT NULL, -- JSON array
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Tenant-Apps Access Table
CREATE TABLE IF NOT EXISTS tenant_apps (
  id TEXT PRIMARY KEY,
  org_id TEXT NOT NULL,
  app_id TEXT NOT NULL,
  enabled BOOLEAN DEFAULT true,
  settings TEXT, -- JSON for app-specific settings
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (org_id) REFERENCES organizations(id) ON DELETE CASCADE,
  FOREIGN KEY (app_id) REFERENCES applications(id) ON DELETE CASCADE,
  UNIQUE(org_id, app_id)
);

CREATE INDEX idx_tenant_apps_org ON tenant_apps(org_id);
CREATE INDEX idx_tenant_apps_app ON tenant_apps(app_id);

-- SSO Configurations Table
CREATE TABLE IF NOT EXISTS sso_configs (
  id TEXT PRIMARY KEY,
  org_id TEXT NOT NULL,
  provider TEXT NOT NULL, -- 'saml', 'oidc', 'azure-ad', 'google', 'okta'
  metadata TEXT, -- SAML metadata or OIDC configuration JSON
  client_id TEXT,
  client_secret TEXT,
  discovery_url TEXT,
  entity_id TEXT,
  acs_url TEXT,
  enabled BOOLEAN DEFAULT true,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (org_id) REFERENCES organizations(id) ON DELETE CASCADE
);

CREATE INDEX idx_sso_configs_org ON sso_configs(org_id);

-- Subscriptions Table
CREATE TABLE IF NOT EXISTS subscriptions (
  id TEXT PRIMARY KEY,
  org_id TEXT NOT NULL,
  tier TEXT NOT NULL,
  status TEXT DEFAULT 'active',
  stripe_subscription_id TEXT,
  current_period_start DATETIME,
  current_period_end DATETIME,
  price_per_month REAL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (org_id) REFERENCES organizations(id) ON DELETE CASCADE
);

CREATE INDEX idx_subscriptions_org ON subscriptions(org_id);

-- Audit Logs Table
CREATE TABLE IF NOT EXISTS audit_logs (
  id TEXT PRIMARY KEY,
  org_id TEXT,
  user_id TEXT,
  action TEXT NOT NULL,
  resource_type TEXT,
  resource_id TEXT,
  ip_address TEXT,
  user_agent TEXT,
  details TEXT, -- JSON
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (org_id) REFERENCES organizations(id) ON DELETE SET NULL,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE INDEX idx_audit_logs_org ON audit_logs(org_id);
CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_created ON audit_logs(created_at);

-- Invitations Table
CREATE TABLE IF NOT EXISTS invitations (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL,
  org_id TEXT NOT NULL,
  roles TEXT NOT NULL, -- JSON array
  invited_by TEXT NOT NULL,
  token TEXT UNIQUE NOT NULL,
  status TEXT DEFAULT 'pending',
  expires_at DATETIME NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (org_id) REFERENCES organizations(id) ON DELETE CASCADE,
  FOREIGN KEY (invited_by) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_invitations_org ON invitations(org_id);
CREATE INDEX idx_invitations_email ON invitations(email);
CREATE INDEX idx_invitations_token ON invitations(token);
