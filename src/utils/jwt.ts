/**
 * JWT Utilities
 * Helper functions for JWT token operations
 */

import jwt from 'jsonwebtoken';

export interface JWTPayload {
  userId: string;
  email: string;
  orgId: string;
  roles: string[];
  allowedApps: string[];
  type: 'access' | 'refresh';
  exp?: number;
  iat?: number;
  iss?: string;
  aud?: string | string[];
}

/**
 * Sign a JWT token
 */
export function signToken(payload: JWTPayload, secret: string, expiresIn: string | number): string {
  // Cast to any to avoid type issues with jsonwebtoken version compatibility
  return jwt.sign(payload as any, secret, {
    expiresIn,
    issuer: 'openauth-enterprise',
    audience: 'openauth-apps',
  } as any);
}

/**
 * Verify and decode a JWT token
 */
export function verifyToken(token: string, secret: string): JWTPayload {
  try {
    const decoded = jwt.verify(token, secret, {
      issuer: 'openauth-enterprise',
      audience: 'openauth-apps',
    }) as JWTPayload;
    return decoded;
  } catch (error) {
    if (error instanceof jwt.TokenExpiredError) {
      throw new Error('Token expired');
    } else if (error instanceof jwt.JsonWebTokenError) {
      throw new Error('Invalid token');
    }
    throw new Error('Token verification failed');
  }
}

/**
 * Decode token without verification (for inspection)
 */
export function decodeToken(token: string): JWTPayload | null {
  try {
    const decoded = jwt.decode(token) as JWTPayload;
    return decoded;
  } catch (error) {
    return null;
  }
}

/**
 * Generate access token (short-lived)
 */
export function generateAccessToken(
  userId: string,
  email: string,
  orgId: string,
  roles: string[],
  allowedApps: string[],
  secret: string
): string {
  const payload: JWTPayload = {
    userId,
    email,
    orgId,
    roles,
    allowedApps,
    type: 'access',
  };
  return signToken(payload, secret, '15m');
}

/**
 * Generate refresh token (long-lived)
 */
export function generateRefreshToken(
  userId: string,
  email: string,
  orgId: string,
  roles: string[],
  allowedApps: string[],
  secret: string
): string {
  const payload: JWTPayload = {
    userId,
    email,
    orgId,
    roles,
    allowedApps,
    type: 'refresh',
  };
  return signToken(payload, secret, '7d');
}

/**
 * Extract token from Authorization header
 */
export function extractBearerToken(authHeader: string | null): string | null {
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return null;
  }
  return authHeader.substring(7);
}

/**
 * Check if token is expired
 */
export function isTokenExpired(token: string): boolean {
  const decoded = decodeToken(token);
  if (!decoded || !decoded.exp) {
    return true;
  }
  return decoded.exp * 1000 < Date.now();
}
