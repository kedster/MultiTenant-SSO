# API Documentation

## Base URL

- Development: `http://localhost:8787`
- Production: `https://your-worker.workers.dev`

## Authentication

Most endpoints require a JWT token in the Authorization header:

```
Authorization: Bearer <access_token>
```

## Endpoints

### Authentication

#### POST /auth/login
Login with email and password.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "accessToken": "eyJhbGciOiJIUzI1NiIs...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "user-123",
    "email": "user@example.com",
    "orgId": "org-456",
    "roles": ["admin"]
  }
}
```

#### POST /auth/refresh
Refresh access token using refresh token.

**Headers:**
```
Authorization: Bearer <refresh_token>
```

**Response:**
```json
{
  "success": true,
  "accessToken": "eyJhbGciOiJIUzI1NiIs..."
}
```

#### POST /auth/logout
Logout and revoke tokens.

**Headers:**
```
Authorization: Bearer <access_token>
```

**Response:**
```json
{
  "success": true
}
```

#### POST /auth/register/org
Register a new organization.

**Request:**
```json
{
  "orgName": "Acme Corp",
  "domain": "acme.com",
  "adminEmail": "admin@acme.com",
  "adminPassword": "secure-password"
}
```

**Response:**
```json
{
  "success": true,
  "orgId": "org-789",
  "userId": "user-101"
}
```

### Organization Management

#### GET /admin/orgs
List all organizations (super admin only).

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `limit` (optional): Results per page (default: 50)

**Response:**
```json
{
  "organizations": [
    {
      "id": "org-123",
      "name": "Acme Corp",
      "domain": "acme.com",
      "subscriptionTier": "professional",
      "status": "active",
      "createdAt": "2024-01-01T00:00:00Z"
    }
  ],
  "total": 100,
  "page": 1,
  "totalPages": 2
}
```

#### GET /admin/orgs/:id
Get organization details.

**Response:**
```json
{
  "id": "org-123",
  "name": "Acme Corp",
  "domain": "acme.com",
  "subscriptionTier": "professional",
  "status": "active",
  "maxUsers": 100,
  "maxApps": 20,
  "createdAt": "2024-01-01T00:00:00Z"
}
```

#### PUT /admin/orgs/:id
Update organization.

**Request:**
```json
{
  "name": "Acme Corporation",
  "status": "active"
}
```

**Response:**
```json
{
  "success": true
}
```

#### DELETE /admin/orgs/:id
Delete/suspend organization.

**Response:**
```json
{
  "success": true
}
```

### User Management

#### GET /admin/users
List users in organization.

**Query Parameters:**
- `orgId` (optional): Filter by organization
- `page` (optional): Page number (default: 1)
- `limit` (optional): Results per page (default: 50)

**Response:**
```json
{
  "users": [
    {
      "id": "user-123",
      "email": "user@acme.com",
      "orgId": "org-456",
      "roles": ["user"],
      "status": "active",
      "lastLogin": "2024-01-15T10:30:00Z"
    }
  ],
  "total": 25,
  "page": 1,
  "totalPages": 1
}
```

#### POST /admin/users/invite
Invite a new user.

**Request:**
```json
{
  "email": "newuser@acme.com",
  "orgId": "org-456",
  "roles": ["user"]
}
```

**Response:**
```json
{
  "success": true,
  "invitationId": "inv-789"
}
```

#### PUT /admin/users/:id
Update user.

**Request:**
```json
{
  "roles": ["admin", "user"],
  "status": "active"
}
```

**Response:**
```json
{
  "success": true
}
```

#### DELETE /admin/users/:id
Delete/suspend user.

**Response:**
```json
{
  "success": true
}
```

### App Access Management

#### GET /admin/orgs/:id/apps
Get apps accessible by organization.

**Response:**
```json
{
  "apps": [
    {
      "appId": "app-123",
      "appName": "Internal Portal",
      "enabled": true
    }
  ]
}
```

#### POST /admin/orgs/:id/apps
Enable/disable app access for organization.

**Request:**
```json
{
  "appId": "app-123",
  "enabled": true
}
```

**Response:**
```json
{
  "success": true
}
```

### SSO Federation

#### POST /auth/sso/initiate
Initiate SSO login flow.

**Request:**
```json
{
  "orgId": "org-456",
  "provider": "azure-ad"
}
```

**Response:**
```json
{
  "redirectUrl": "https://login.microsoftonline.com/..."
}
```

#### POST /auth/sso/callback
Handle SSO callback from IdP.

*This endpoint receives SAML responses or OIDC tokens from the identity provider.*

## Error Responses

All endpoints may return error responses in this format:

```json
{
  "success": false,
  "error": "Error message here"
}
```

Common HTTP status codes:
- `400` - Bad Request
- `401` - Unauthorized
- `403` - Forbidden
- `404` - Not Found
- `500` - Internal Server Error
- `501` - Not Implemented
