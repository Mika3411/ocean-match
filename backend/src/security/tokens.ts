import crypto from 'node:crypto';

import jwt from 'jsonwebtoken';

import { env } from '../config/env.js';
import { UnauthorizedError } from '../errors.js';

export type AccessTokenPayload = {
  sub: string;
  email: string;
  emailVerified: boolean;
  status: string;
  planTier: string;
};

export function signAccessToken(payload: AccessTokenPayload): string {
  return jwt.sign(payload, env.JWT_ACCESS_SECRET, {
    expiresIn: `${env.ACCESS_TOKEN_TTL_MINUTES}m`,
    issuer: 'ocean-match-api',
    audience: 'ocean-match-app',
  });
}

export function verifyAccessToken(token: string): AccessTokenPayload {
  try {
    return jwt.verify(token, env.JWT_ACCESS_SECRET, {
      issuer: 'ocean-match-api',
      audience: 'ocean-match-app',
    }) as AccessTokenPayload;
  } catch {
    throw new UnauthorizedError('Session expiree ou invalide.');
  }
}

export function createOpaqueToken(): string {
  return crypto.randomBytes(48).toString('base64url');
}

export function hashRefreshToken(token: string): string {
  return crypto
    .createHmac('sha256', env.JWT_REFRESH_SECRET)
    .update(token)
    .digest('hex');
}

export function tokenExpiryDate(days: number): Date {
  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate() + days);
  return expiresAt;
}
