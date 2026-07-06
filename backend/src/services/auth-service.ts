import type { PoolClient } from 'pg';

import { env } from '../config/env.js';
import type { DbClient } from '../db/pool.js';
import { withTransaction } from '../db/pool.js';
import { ConflictError, ForbiddenError, NotFoundError, UnauthorizedError } from '../errors.js';
import { hashPassword, verifyPassword } from '../security/passwords.js';
import {
  createOpaqueToken,
  hashRefreshToken,
  signAccessToken,
  tokenExpiryDate,
} from '../security/tokens.js';
import { serializeUser } from '../serializers.js';

type UserRow = Record<string, unknown>;

export type RequestMeta = {
  ip?: string;
  userAgent?: string;
};

function accessPayload(user: UserRow) {
  return {
    sub: String(user.id),
    email: String(user.email),
    emailVerified: Boolean(user.email_verified_at),
    status: String(user.status),
    planTier: String(user.plan_tier),
  };
}

async function createRefreshToken(
  client: DbClient,
  userId: string,
  meta: RequestMeta,
  rotatedFromId?: string,
) {
  const refreshToken = createOpaqueToken();
  const tokenHash = hashRefreshToken(refreshToken);
  const expiresAt = tokenExpiryDate(env.REFRESH_TOKEN_TTL_DAYS);

  await client.query(
    `
      INSERT INTO refresh_tokens (
        user_id,
        token_hash,
        rotated_from_id,
        user_agent,
        ip_address,
        expires_at
      )
      VALUES ($1, $2, $3, $4, $5::inet, $6)
    `,
    [userId, tokenHash, rotatedFromId ?? null, meta.userAgent ?? null, meta.ip ?? null, expiresAt],
  );

  return refreshToken;
}

async function createEmailVerificationToken(client: DbClient, userId: string) {
  const token = createOpaqueToken();
  await client.query(
    `
      INSERT INTO email_verification_tokens (user_id, token_hash, expires_at)
      VALUES ($1, $2, now() + interval '24 hours')
    `,
    [userId, hashRefreshToken(token)],
  );
  return token;
}

async function createPasswordResetToken(client: DbClient, userId: string) {
  const token = createOpaqueToken();
  await client.query(
    `
      INSERT INTO password_reset_tokens (user_id, token_hash, expires_at)
      VALUES ($1, $2, now() + interval '1 hour')
    `,
    [userId, hashRefreshToken(token)],
  );
  return token;
}

async function createSession(client: DbClient, user: UserRow, meta: RequestMeta, rotatedFromId?: string) {
  const accessToken = signAccessToken(accessPayload(user));
  const refreshToken = await createRefreshToken(client, String(user.id), meta, rotatedFromId);
  return {
    accessToken,
    refreshToken,
    tokenType: 'Bearer',
    expiresInSeconds: env.ACCESS_TOKEN_TTL_MINUTES * 60,
  };
}

export class AuthService {
  async signup(input: { email: string; password: string }, meta: RequestMeta) {
    return withTransaction(async (client) => {
      const existing = await client.query(
        `SELECT id FROM users WHERE email = $1 AND status <> 'deleted' LIMIT 1`,
        [input.email],
      );
      if (existing.rowCount) {
        throw new ConflictError('Un compte existe deja avec cet email.');
      }

      const passwordHash = await hashPassword(input.password);
      const userResult = await client.query<UserRow>(
        `
          INSERT INTO users (email, password_hash)
          VALUES ($1, $2)
          RETURNING *
        `,
        [input.email, passwordHash],
      );
      const user = userResult.rows[0];
      const verificationToken = await createEmailVerificationToken(client, String(user.id));
      const tokens = await createSession(client, user, meta);

      return {
        user: serializeUser(user),
        tokens,
        ...(env.isProduction ? {} : { debugEmailVerificationToken: verificationToken }),
      };
    });
  }

  async login(input: { email: string; password: string }, meta: RequestMeta) {
    return withTransaction(async (client) => {
      const userResult = await client.query<UserRow>(
        `SELECT * FROM users WHERE email = $1 AND status <> 'deleted' LIMIT 1`,
        [input.email],
      );
      const user = userResult.rows[0];
      if (!user || !(await verifyPassword(input.password, String(user.password_hash)))) {
        throw new UnauthorizedError('Email ou mot de passe incorrect.');
      }
      if (user.status === 'suspended') {
        throw new ForbiddenError('Ce compte est suspendu.');
      }

      const updated = await client.query<UserRow>(
        `UPDATE users SET last_login_at = now() WHERE id = $1 RETURNING *`,
        [user.id],
      );
      const tokens = await createSession(client, updated.rows[0], meta);

      return {
        user: serializeUser(updated.rows[0]),
        tokens,
      };
    });
  }

  async refresh(refreshToken: string, meta: RequestMeta) {
    return withTransaction(async (client) => {
      const tokenHash = hashRefreshToken(refreshToken);
      const result = await client.query<UserRow & { refresh_token_id: string }>(
        `
          SELECT
            u.*,
            rt.id AS refresh_token_id
          FROM refresh_tokens rt
          JOIN users u ON u.id = rt.user_id
          WHERE rt.token_hash = $1
            AND rt.revoked_at IS NULL
            AND rt.expires_at > now()
            AND u.status <> 'deleted'
          LIMIT 1
        `,
        [tokenHash],
      );
      const user = result.rows[0];
      if (!user) {
        throw new UnauthorizedError('Refresh token invalide.');
      }
      if (user.status === 'suspended') {
        throw new ForbiddenError('Ce compte est suspendu.');
      }

      await client.query(`UPDATE refresh_tokens SET revoked_at = now() WHERE id = $1`, [
        user.refresh_token_id,
      ]);
      const tokens = await createSession(client, user, meta, user.refresh_token_id);

      return {
        user: serializeUser(user),
        tokens,
      };
    });
  }

  async logout(refreshToken?: string) {
    if (!refreshToken) return;
    await withTransaction(async (client) => {
      await client.query(
        `
          UPDATE refresh_tokens
          SET revoked_at = now()
          WHERE token_hash = $1 AND revoked_at IS NULL
        `,
        [hashRefreshToken(refreshToken)],
      );
    });
  }

  async verifyEmail(token: string) {
    return withTransaction(async (client) => {
      const result = await client.query<UserRow & { token_id: string }>(
        `
          SELECT u.*, evt.id AS token_id
          FROM email_verification_tokens evt
          JOIN users u ON u.id = evt.user_id
          WHERE evt.token_hash = $1
            AND evt.used_at IS NULL
            AND evt.expires_at > now()
            AND u.status <> 'deleted'
          LIMIT 1
        `,
        [hashRefreshToken(token)],
      );
      const row = result.rows[0];
      if (!row) {
        throw new UnauthorizedError('Token de verification invalide ou expire.');
      }

      await client.query(`UPDATE email_verification_tokens SET used_at = now() WHERE id = $1`, [
        row.token_id,
      ]);
      const updated = await client.query<UserRow>(
        `
          UPDATE users
          SET email_verified_at = COALESCE(email_verified_at, now()),
              status = CASE WHEN status = 'pending_email_verification' THEN 'active'::account_status ELSE status END
          WHERE id = $1
          RETURNING *
        `,
        [row.id],
      );

      return { user: serializeUser(updated.rows[0]) };
    });
  }

  async resendVerification(userId: string) {
    return withTransaction(async (client) => {
      const user = await this.getUsableUser(client, userId);
      if (user.email_verified_at) {
        return { alreadyVerified: true };
      }
      const verificationToken = await createEmailVerificationToken(client, userId);
      return {
        alreadyVerified: false,
        ...(env.isProduction ? {} : { debugEmailVerificationToken: verificationToken }),
      };
    });
  }

  async requestPasswordReset(email: string) {
    const result = await withTransaction(async (client) => {
      const userResult = await client.query<UserRow>(
        `SELECT * FROM users WHERE email = $1 AND status <> 'deleted' LIMIT 1`,
        [email],
      );
      const user = userResult.rows[0];
      if (!user || user.status === 'suspended') return {};
      const passwordResetToken = await createPasswordResetToken(client, String(user.id));
      return env.isProduction ? {} : { debugPasswordResetToken: passwordResetToken };
    });

    return { accepted: true, ...result };
  }

  async confirmPasswordReset(token: string, password: string) {
    await withTransaction(async (client) => {
      const result = await client.query<UserRow & { token_id: string }>(
        `
          SELECT u.*, prt.id AS token_id
          FROM password_reset_tokens prt
          JOIN users u ON u.id = prt.user_id
          WHERE prt.token_hash = $1
            AND prt.used_at IS NULL
            AND prt.expires_at > now()
            AND u.status <> 'deleted'
          LIMIT 1
        `,
        [hashRefreshToken(token)],
      );
      const row = result.rows[0];
      if (!row) {
        throw new UnauthorizedError('Token de reinitialisation invalide ou expire.');
      }

      await client.query(`UPDATE password_reset_tokens SET used_at = now() WHERE id = $1`, [
        row.token_id,
      ]);
      await client.query(`UPDATE users SET password_hash = $1 WHERE id = $2`, [
        await hashPassword(password),
        row.id,
      ]);
      await client.query(`UPDATE refresh_tokens SET revoked_at = now() WHERE user_id = $1`, [row.id]);
    });
  }

  async deleteAccount(userId: string) {
    await withTransaction(async (client) => {
      const user = await this.getUsableUser(client, userId);
      await client.query(
        `
          UPDATE users
          SET status = 'deleted',
              deleted_at = now(),
              email_verified_at = NULL,
              email = 'deleted+' || id::text || '@deleted.oceanmatch.local',
              password_hash = 'deleted'
          WHERE id = $1
        `,
        [user.id],
      );
      await client.query(`UPDATE refresh_tokens SET revoked_at = now() WHERE user_id = $1`, [user.id]);
      await client.query(
        `
          UPDATE profile_photos
          SET deleted_at = COALESCE(deleted_at, now())
          WHERE user_id = $1
        `,
        [user.id],
      );
      await client.query(
        `
          UPDATE matches
          SET status = 'deleted'
          WHERE user_a_id = $1 OR user_b_id = $1
        `,
        [user.id],
      );
    });
  }

  async getUsableUser(client: DbClient, userId: string) {
    const result = await client.query<UserRow>(
      `SELECT * FROM users WHERE id = $1 AND status <> 'deleted' LIMIT 1`,
      [userId],
    );
    const user = result.rows[0];
    if (!user) {
      throw new NotFoundError('Compte introuvable.');
    }
    if (user.status === 'suspended') {
      throw new ForbiddenError('Ce compte est suspendu.');
    }
    return user;
  }

  async requireActiveVerifiedUser(client: DbClient, userId: string) {
    const user = await this.getUsableUser(client, userId);
    if (!user.email_verified_at || user.status !== 'active') {
      throw new ForbiddenError('Verifiez votre email pour activer votre compte.');
    }
    return user;
  }
}

export function requestMetaFrom(clientIp: string | undefined, userAgent: string | undefined): RequestMeta {
  return {
    ip: clientIp,
    userAgent,
  };
}

export async function getUserById(client: PoolClient, userId: string) {
  const result = await client.query<UserRow>(`SELECT * FROM users WHERE id = $1 LIMIT 1`, [userId]);
  return result.rows[0];
}
