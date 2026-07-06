import type { DbClient } from '../db/pool.js';
import { pool } from '../db/pool.js';

export const PremiumFeatures = {
  unlimitedLikes: 'unlimited_likes',
  seeWhoLikedMe: 'see_who_liked_me',
  advancedFilters: 'advanced_filters',
  multiFutureRoutes: 'multi_future_routes',
  multiZoneVisibility: 'multi_zone_visibility',
  photoVerification: 'photo_verification',
  events: 'events',
  moderationBackoffice: 'moderation_backoffice',
} as const;

export type PremiumFeatureKey = (typeof PremiumFeatures)[keyof typeof PremiumFeatures];

export type ActiveFeature = {
  featureKey: PremiumFeatureKey;
  featureGroup: string;
  source: string;
  expiresAt: string | null;
  metadata: Record<string, unknown>;
};

type FeatureRow = {
  feature_key: PremiumFeatureKey;
  feature_group: string;
  source: string;
  expires_at: string | null;
  metadata: Record<string, unknown>;
};

export class EntitlementService {
  async isEnabled(
    userId: string,
    featureKey: PremiumFeatureKey,
    client: DbClient = pool,
  ): Promise<boolean> {
    const result = await client.query(
      `
        SELECT 1
        FROM user_feature_flags uff
        JOIN feature_catalog fc ON fc.feature_key = uff.feature_key
        WHERE uff.user_id = $1
          AND uff.feature_key = $2
          AND uff.enabled = true
          AND (uff.expires_at IS NULL OR uff.expires_at > now())
          AND fc.mvp_state = 'active'
        LIMIT 1
      `,
      [userId, featureKey],
    );
    return Boolean(result.rowCount);
  }

  async listActiveFeatures(userId: string, client: DbClient = pool): Promise<ActiveFeature[]> {
    const result = await client.query<FeatureRow>(
      `
        SELECT
          uff.feature_key,
          fc.feature_group,
          uff.source,
          uff.expires_at,
          uff.metadata
        FROM user_feature_flags uff
        JOIN feature_catalog fc ON fc.feature_key = uff.feature_key
        WHERE uff.user_id = $1
          AND uff.enabled = true
          AND (uff.expires_at IS NULL OR uff.expires_at > now())
          AND fc.mvp_state = 'active'
        ORDER BY fc.feature_group, uff.feature_key
      `,
      [userId],
    );

    return result.rows.map((row) => ({
      featureKey: row.feature_key,
      featureGroup: row.feature_group,
      source: row.source,
      expiresAt: row.expires_at,
      metadata: row.metadata ?? {},
    }));
  }
}
