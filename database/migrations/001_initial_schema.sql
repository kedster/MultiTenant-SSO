-- Initial Migration: Create Core Tables
-- Run: wrangler d1 execute openauth_db --file=./database/migrations/001_initial_schema.sql

-- Organizations
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

-- Users
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT,
  org_id TEXT NOT NULL,
  roles TEXT NOT NULL,
  status TEXT DEFAULT 'invited',
  federated_id TEXT,
  last_login DATETIME,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (org_id) REFERENCES organizations(id) ON DELETE CASCADE
);

CREATE INDEX idx_users_org_id ON users(org_id);
CREATE INDEX idx_users_email ON users(email);

-- Applications
CREATE TABLE IF NOT EXISTS applications (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  domain TEXT UNIQUE NOT NULL,
  description TEXT,
  oauth_client_id TEXT UNIQUE NOT NULL,
  oauth_client_secret TEXT NOT NULL,
  redirect_uris TEXT NOT NULL,
  allowed_scopes TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Tenant Apps Access
CREATE TABLE IF NOT EXISTS tenant_apps (
  id TEXT PRIMARY KEY,
  org_id TEXT NOT NULL,
  app_id TEXT NOT NULL,
  enabled BOOLEAN DEFAULT true,
  settings TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (org_id) REFERENCES organizations(id) ON DELETE CASCADE,
  FOREIGN KEY (app_id) REFERENCES applications(id) ON DELETE CASCADE,
  UNIQUE(org_id, app_id)
);

CREATE INDEX idx_tenant_apps_org ON tenant_apps(org_id);
CREATE INDEX idx_tenant_apps_app ON tenant_apps(app_id);
