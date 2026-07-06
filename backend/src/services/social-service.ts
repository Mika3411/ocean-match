import type { DbClient } from '../db/pool.js';
import { pool, withTransaction } from '../db/pool.js';
import { BadRequestError, ForbiddenError, NotFoundError } from '../errors.js';
import {
  serializeBlock,
  serializeConversation,
  serializeMatch,
  serializeReport,
} from '../serializers.js';
import { AuthService } from './auth-service.js';

type Row = Record<string, unknown>;

const authService = new AuthService();

async function ensureNoBlock(client: DbClient, userId: string, targetUserId: string) {
  const result = await client.query(
    `
      SELECT 1
      FROM blocks
      WHERE (blocker_id = $1 AND blocked_id = $2)
         OR (blocker_id = $2 AND blocked_id = $1)
      LIMIT 1
    `,
    [userId, targetUserId],
  );
  if (result.rowCount) {
    throw new ForbiddenError('Interaction bloquee.');
  }
}

async function ensureTargetInteractionAllowed(client: DbClient, userId: string, targetUserId: string) {
  if (userId === targetUserId) {
    throw new BadRequestError('Action impossible sur soi-meme.');
  }
  await authService.requireActiveVerifiedUser(client, userId);
  await authService.requireActiveVerifiedUser(client, targetUserId);
  await ensureNoBlock(client, userId, targetUserId);
}

export class SocialService {
  async like(userId: string, targetUserId: string) {
    return withTransaction(async (client) => {
      await ensureTargetInteractionAllowed(client, userId, targetUserId);

      await client.query(
        `
          INSERT INTO likes (user_id, target_user_id)
          VALUES ($1, $2)
          ON CONFLICT (user_id, target_user_id) DO NOTHING
        `,
        [userId, targetUserId],
      );

      const reciprocal = await client.query(
        `SELECT 1 FROM likes WHERE user_id = $2 AND target_user_id = $1 LIMIT 1`,
        [userId, targetUserId],
      );
      if (!reciprocal.rowCount) {
        return { createdMatch: false, match: null, conversation: null };
      }

      const existing = await client.query<Row>(
        `
          SELECT m.*, c.id AS conversation_id, c.created_at AS conversation_created_at, c.last_message_at
          FROM matches m
          LEFT JOIN conversations c ON c.match_id = m.id
          WHERE m.user_a_id = LEAST($1::uuid, $2::uuid)
            AND m.user_b_id = GREATEST($1::uuid, $2::uuid)
          LIMIT 1
        `,
        [userId, targetUserId],
      );
      const hadMatch = Boolean(existing.rowCount);

      const matchResult = await client.query<Row>(
        `
          INSERT INTO matches (user_a_id, user_b_id, status)
          VALUES (LEAST($1::uuid, $2::uuid), GREATEST($1::uuid, $2::uuid), 'active')
          ON CONFLICT (user_a_id, user_b_id) DO UPDATE
          SET status = CASE
              WHEN matches.status = 'blocked' THEN matches.status
              ELSE 'active'::match_status
            END
          RETURNING *
        `,
        [userId, targetUserId],
      );
      const match = matchResult.rows[0];
      if (match.status !== 'active') {
        throw new ForbiddenError('Match bloque.');
      }

      const conversationResult = await client.query<Row>(
        `
          INSERT INTO conversations (match_id, user_a_id, user_b_id)
          VALUES ($1, $2, $3)
          ON CONFLICT (match_id) DO UPDATE
          SET match_id = EXCLUDED.match_id
          RETURNING *
        `,
        [match.id, match.user_a_id, match.user_b_id],
      );

      return {
        createdMatch: !hadMatch,
        match: serializeMatch(match),
        conversation: serializeConversation(conversationResult.rows[0]),
      };
    });
  }

  async pass(userId: string, targetUserId: string) {
    await withTransaction(async (client) => {
      await ensureTargetInteractionAllowed(client, userId, targetUserId);
      await client.query(
        `
          INSERT INTO passes (user_id, target_user_id)
          VALUES ($1, $2)
          ON CONFLICT (user_id, target_user_id) DO UPDATE
          SET created_at = now(),
              expires_at = now() + interval '30 days'
        `,
        [userId, targetUserId],
      );
    });
  }

  async listBlocks(userId: string) {
    await authService.requireActiveVerifiedUser(pool, userId);
    const result = await pool.query<Row>(
      `
        SELECT *
        FROM blocks
        WHERE blocker_id = $1
        ORDER BY created_at DESC
      `,
      [userId],
    );
    return result.rows.map(serializeBlock);
  }

  async block(userId: string, blockedUserId: string) {
    return withTransaction(async (client) => {
      if (userId === blockedUserId) {
        throw new BadRequestError('Action impossible sur soi-meme.');
      }
      await authService.requireActiveVerifiedUser(client, userId);
      await authService.getUsableUser(client, blockedUserId);

      const result = await client.query<Row>(
        `
          INSERT INTO blocks (blocker_id, blocked_id)
          VALUES ($1, $2)
          ON CONFLICT (blocker_id, blocked_id) DO UPDATE
          SET blocker_id = EXCLUDED.blocker_id
          RETURNING *
        `,
        [userId, blockedUserId],
      );
      await client.query(
        `
          UPDATE matches
          SET status = 'blocked'
          WHERE user_a_id = LEAST($1::uuid, $2::uuid)
            AND user_b_id = GREATEST($1::uuid, $2::uuid)
        `,
        [userId, blockedUserId],
      );
      return serializeBlock(result.rows[0]);
    });
  }

  async unblock(userId: string, blockId: string) {
    await withTransaction(async (client) => {
      await authService.requireActiveVerifiedUser(client, userId);
      const blockResult = await client.query<Row>(
        `
          DELETE FROM blocks
          WHERE id = $1 AND blocker_id = $2
          RETURNING *
        `,
        [blockId, userId],
      );
      const block = blockResult.rows[0];
      if (!block) {
        throw new NotFoundError('Blocage introuvable.');
      }

      const remaining = await client.query(
        `
          SELECT 1
          FROM blocks
          WHERE (blocker_id = $1 AND blocked_id = $2)
             OR (blocker_id = $2 AND blocked_id = $1)
          LIMIT 1
        `,
        [block.blocker_id, block.blocked_id],
      );
      if (!remaining.rowCount) {
        await client.query(
          `
            UPDATE matches
            SET status = 'active'
            WHERE status = 'blocked'
              AND user_a_id = LEAST($1::uuid, $2::uuid)
              AND user_b_id = GREATEST($1::uuid, $2::uuid)
          `,
          [block.blocker_id, block.blocked_id],
        );
      }
    });
  }

  async report(
    userId: string,
    input: {
      reportedUserId: string;
      reason: string;
      conversationId?: string;
      messageId?: string;
      comment?: string;
    },
  ) {
    return withTransaction(async (client) => {
      if (userId === input.reportedUserId) {
        throw new BadRequestError('Action impossible sur soi-meme.');
      }
      await authService.requireActiveVerifiedUser(client, userId);
      const reported = await authService.getUsableUser(client, input.reportedUserId);

      if (input.conversationId) {
        const conversation = await client.query<Row>(
          `
            SELECT *
            FROM conversations
            WHERE id = $1
              AND (
                (user_a_id = $2 AND user_b_id = $3)
                OR (user_a_id = $3 AND user_b_id = $2)
              )
            LIMIT 1
          `,
          [input.conversationId, userId, input.reportedUserId],
        );
        if (!conversation.rowCount) {
          throw new ForbiddenError('Signalement conversation refuse.');
        }
        if (input.messageId) {
          const message = await client.query(
            `
              SELECT 1
              FROM messages
              WHERE id = $1 AND conversation_id = $2
              LIMIT 1
            `,
            [input.messageId, input.conversationId],
          );
          if (!message.rowCount) {
            throw new NotFoundError('Message introuvable.');
          }
        }
      } else if (input.messageId) {
        throw new BadRequestError('Signalement incoherent.');
      }

      const profile = await client.query<Row>(
        `SELECT first_name, birth_date, gender FROM profiles WHERE user_id = $1`,
        [input.reportedUserId],
      );
      const result = await client.query<Row>(
        `
          INSERT INTO reports (
            reporter_id,
            reported_id,
            reported_user_snapshot,
            conversation_id,
            message_id,
            reason,
            comment
          )
          VALUES ($1, $2, $3::jsonb, $4, $5, $6, $7)
          RETURNING *
        `,
        [
          userId,
          input.reportedUserId,
          JSON.stringify({
            id: reported.id,
            status: reported.status,
            profile: profile.rows[0] ?? null,
          }),
          input.conversationId ?? null,
          input.messageId ?? null,
          input.reason,
          input.comment ?? null,
        ],
      );
      return serializeReport(result.rows[0]);
    });
  }
}
