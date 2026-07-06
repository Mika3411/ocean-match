import { pool, withTransaction } from '../db/pool.js';
import { ForbiddenError, NotFoundError } from '../errors.js';
import {
  serializeConversation,
  serializeMatch,
  serializeMessage,
  serializePhoto,
  serializeProfile,
} from '../serializers.js';
import { photoStorage } from '../storage/photo-storage.js';
import { AuthService } from './auth-service.js';

type Row = Record<string, unknown>;

const authService = new AuthService();

export class MessagingService {
  async listMatches(userId: string) {
    await authService.requireActiveVerifiedUser(pool, userId);
    const result = await pool.query<Row>(
      `
        SELECT *
        FROM matches
        WHERE status <> 'deleted'
          AND (user_a_id = $1 OR user_b_id = $1)
        ORDER BY created_at DESC
      `,
      [userId],
    );
    return result.rows.map(serializeMatch);
  }

  async listConversations(userId: string) {
    await authService.requireActiveVerifiedUser(pool, userId);
    const result = await pool.query<Row>(
      `
        SELECT
          c.*,
          m.status AS match_status,
          m.created_at AS match_created_at,
          p.user_id AS other_user_id,
          p.first_name,
          p.birth_date,
          p.gender,
          p.search_gender,
          p.languages,
          p.bio,
          p.is_complete,
          p.visibility,
          p.created_at AS profile_created_at,
          p.updated_at AS profile_updated_at,
          last_message.message AS last_message,
          primary_photo.photo AS other_photo,
          EXISTS (
            SELECT 1
            FROM blocks b
            WHERE (b.blocker_id = $1 AND b.blocked_id = p.user_id)
               OR (b.blocker_id = p.user_id AND b.blocked_id = $1)
          ) OR m.status = 'blocked' AS is_blocked
        FROM conversations c
        JOIN matches m ON m.id = c.match_id
        JOIN profiles p ON p.user_id = CASE WHEN c.user_a_id = $1 THEN c.user_b_id ELSE c.user_a_id END
        LEFT JOIN LATERAL (
          SELECT to_jsonb(msg) AS message
          FROM messages msg
          WHERE msg.conversation_id = c.id AND msg.deleted_at IS NULL
          ORDER BY msg.created_at DESC
          LIMIT 1
        ) last_message ON true
        LEFT JOIN LATERAL (
          SELECT to_jsonb(pp) AS photo
          FROM profile_photos pp
          WHERE pp.user_id = p.user_id
            AND pp.deleted_at IS NULL
            AND pp.moderation_status = 'approved'
          ORDER BY pp.is_primary DESC, pp.sort_order ASC
          LIMIT 1
        ) primary_photo ON true
        WHERE m.status <> 'deleted'
          AND (c.user_a_id = $1 OR c.user_b_id = $1)
        ORDER BY COALESCE(c.last_message_at, c.created_at) DESC
      `,
      [userId],
    );

    return result.rows.map((row) => ({
      conversation: serializeConversation(row),
      match: serializeMatch({
        id: row.match_id,
        user_a_id: row.user_a_id,
        user_b_id: row.user_b_id,
        status: row.match_status,
        created_at: row.match_created_at,
      }),
      otherProfile: serializeProfile({
        user_id: row.other_user_id,
        first_name: row.first_name,
        birth_date: row.birth_date,
        gender: row.gender,
        search_gender: row.search_gender,
        languages: row.languages,
        bio: row.bio,
        is_complete: row.is_complete,
        visibility: row.visibility,
        created_at: row.profile_created_at,
        updated_at: row.profile_updated_at,
      }),
      otherPhoto: row.other_photo
        ? serializePhoto(row.other_photo as Record<string, unknown>, photoStorage)
        : null,
      lastMessage: row.last_message
        ? serializeMessage(row.last_message as Record<string, unknown>)
        : null,
      isBlocked: row.is_blocked,
    }));
  }

  async listMessages(userId: string, conversationId: string) {
    await this.requireConversationAccess(userId, conversationId);
    const result = await pool.query<Row>(
      `
        SELECT *
        FROM messages
        WHERE conversation_id = $1 AND deleted_at IS NULL
        ORDER BY created_at ASC
      `,
      [conversationId],
    );
    return result.rows.map(serializeMessage);
  }

  async sendMessage(userId: string, conversationId: string, content: string) {
    return withTransaction(async (client) => {
      await authService.requireActiveVerifiedUser(client, userId);
      const conversation = await client.query<Row>(
        `
          SELECT c.*, m.status AS match_status
          FROM conversations c
          JOIN matches m ON m.id = c.match_id
          WHERE c.id = $1
            AND (c.user_a_id = $2 OR c.user_b_id = $2)
          FOR UPDATE
        `,
        [conversationId, userId],
      );
      const row = conversation.rows[0];
      if (!row) {
        throw new NotFoundError('Conversation introuvable.');
      }
      if (row.match_status !== 'active') {
        throw new ForbiddenError('Conversation inactive.');
      }
      const otherUserId = row.user_a_id === userId ? row.user_b_id : row.user_a_id;
      const block = await client.query(
        `
          SELECT 1
          FROM blocks
          WHERE (blocker_id = $1 AND blocked_id = $2)
             OR (blocker_id = $2 AND blocked_id = $1)
          LIMIT 1
        `,
        [userId, otherUserId],
      );
      if (block.rowCount) {
        throw new ForbiddenError('Interaction bloquee.');
      }

      const message = await client.query<Row>(
        `
          INSERT INTO messages (conversation_id, sender_id, content)
          VALUES ($1, $2, $3)
          RETURNING *
        `,
        [conversationId, userId, content],
      );
      await client.query(
        `UPDATE conversations SET last_message_at = now() WHERE id = $1`,
        [conversationId],
      );
      return serializeMessage(message.rows[0]);
    });
  }

  private async requireConversationAccess(userId: string, conversationId: string) {
    await authService.requireActiveVerifiedUser(pool, userId);
    const conversation = await pool.query(
      `
        SELECT 1
        FROM conversations
        WHERE id = $1
          AND (user_a_id = $2 OR user_b_id = $2)
        LIMIT 1
      `,
      [conversationId, userId],
    );
    if (!conversation.rowCount) {
      throw new NotFoundError('Conversation introuvable.');
    }
  }
}
