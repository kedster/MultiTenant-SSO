/**
 * KV Store Utilities
 * Helper functions for Cloudflare KV operations
 */

/**
 * Store session in KV
 */
export async function setSession(
  kv: KVNamespace,
  sessionId: string,
  data: any,
  expirationTtl?: number
): Promise<void> {
  try {
    const sessionData = JSON.stringify(data);
    await kv.put(`session:${sessionId}`, sessionData, {
      expirationTtl: expirationTtl || 86400, // Default 24 hours
    });
  } catch (error) {
    console.error('KV set session error:', error);
    throw new Error('Failed to store session');
  }
}

/**
 * Get session from KV
 */
export async function getSession<T>(kv: KVNamespace, sessionId: string): Promise<T | null> {
  try {
    const sessionData = await kv.get(`session:${sessionId}`);
    if (!sessionData) {
      return null;
    }
    return JSON.parse(sessionData) as T;
  } catch (error) {
    console.error('KV get session error:', error);
    return null;
  }
}

/**
 * Delete session from KV
 */
export async function deleteSession(kv: KVNamespace, sessionId: string): Promise<void> {
  try {
    await kv.delete(`session:${sessionId}`);
  } catch (error) {
    console.error('KV delete session error:', error);
    throw new Error('Failed to delete session');
  }
}

/**
 * Store revoked token in KV
 */
export async function revokeToken(
  kv: KVNamespace,
  token: string,
  expirationTtl: number
): Promise<void> {
  try {
    await kv.put(`revoked:${token}`, 'true', { expirationTtl });
  } catch (error) {
    console.error('KV revoke token error:', error);
    throw new Error('Failed to revoke token');
  }
}

/**
 * Check if token is revoked
 */
export async function isTokenRevoked(kv: KVNamespace, token: string): Promise<boolean> {
  try {
    const revoked = await kv.get(`revoked:${token}`);
    return revoked !== null;
  } catch (error) {
    console.error('KV check revoked token error:', error);
    return false;
  }
}

/**
 * Store SSO state/nonce for verification
 */
export async function setSSOState(
  kv: KVNamespace,
  state: string,
  data: any,
  expirationTtl: number = 600 // 10 minutes
): Promise<void> {
  try {
    const stateData = JSON.stringify(data);
    await kv.put(`sso-state:${state}`, stateData, { expirationTtl });
  } catch (error) {
    console.error('KV set SSO state error:', error);
    throw new Error('Failed to store SSO state');
  }
}

/**
 * Get and delete SSO state (one-time use)
 */
export async function consumeSSOState<T>(kv: KVNamespace, state: string): Promise<T | null> {
  try {
    const stateData = await kv.get(`sso-state:${state}`);
    if (!stateData) {
      return null;
    }
    await kv.delete(`sso-state:${state}`);
    return JSON.parse(stateData) as T;
  } catch (error) {
    console.error('KV consume SSO state error:', error);
    return null;
  }
}

/**
 * Store cached data with TTL
 */
export async function setCache(
  kv: KVNamespace,
  key: string,
  data: any,
  expirationTtl: number
): Promise<void> {
  try {
    const cacheData = JSON.stringify(data);
    await kv.put(`cache:${key}`, cacheData, { expirationTtl });
  } catch (error) {
    console.error('KV set cache error:', error);
    throw new Error('Failed to store cache');
  }
}

/**
 * Get cached data
 */
export async function getCache<T>(kv: KVNamespace, key: string): Promise<T | null> {
  try {
    const cacheData = await kv.get(`cache:${key}`);
    if (!cacheData) {
      return null;
    }
    return JSON.parse(cacheData) as T;
  } catch (error) {
    console.error('KV get cache error:', error);
    return null;
  }
}
