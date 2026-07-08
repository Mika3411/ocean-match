import { pool } from '../db/pool.js';
import { env } from '../config/env.js';
import {
  serializeCurrentZone,
  serializeFutureRoute,
  serializeLifeAboard,
  serializePhoto,
  serializeProfile,
} from '../serializers.js';
import { photoStorage } from '../storage/photo-storage.js';
import { ProfileService } from './profile-service.js';

type Row = Record<string, unknown> & {
  photos: Record<string, unknown>[] | null;
};

const profileService = new ProfileService();

export class DiscoveryService {
  async list(userId: string) {
    await profileService.ensureDiscoverable(userId);

    const result = await pool.query<Row>(
      `
        WITH mine AS (
          SELECT
            p.user_id,
            p.gender,
            pref.age_min,
            pref.age_max,
            pref.gender_targets,
            pref.intentions,
            cz.zone AS current_zone,
            fr.destination_zone AS future_destination_zone
          FROM profiles p
          JOIN preferences pref ON pref.user_id = p.user_id
          JOIN current_zones cz ON cz.user_id = p.user_id
          JOIN future_routes fr ON fr.user_id = p.user_id AND fr.is_active
          WHERE p.user_id = $1
        )
        SELECT
          p.*,
          la.status AS life_status,
          la.boat_or_project,
          la.sailing_type,
          la.experience,
          la.lifestyle_tags,
          la.updated_at AS life_updated_at,
          cz.zone AS zone,
          cz.country AS zone_country,
          cz.port_id AS zone_port_id,
          cz.updated_at AS zone_updated_at,
          fr.id AS route_id,
          fr.destination_zone,
          fr.destination_country,
          fr.destination_port_id,
          fr.start_period,
          fr.end_period,
          fr.flexibility,
          fr.comment,
          fr.is_active,
          fr.updated_at AS route_updated_at,
          pref.intentions AS target_intentions,
          (
            SELECT jsonb_agg(to_jsonb(pp) ORDER BY pp.is_primary DESC, pp.sort_order ASC, pp.created_at ASC)
            FROM profile_photos pp
            WHERE pp.user_id = p.user_id
              AND pp.deleted_at IS NULL
              AND pp.moderation_status = 'approved'
          ) AS photos,
          (
            CASE WHEN cz.zone = mine.current_zone THEN 25 ELSE 0 END
            + CASE
                WHEN fr.destination_zone = mine.current_zone
                  OR mine.future_destination_zone = cz.zone
                  OR mine.future_destination_zone = fr.destination_zone
                THEN 25 ELSE 0
              END
            + CASE WHEN pref.intentions && mine.intentions THEN 20 ELSE 0 END
            + CASE WHEN la.lifestyle_tags && (
                SELECT la2.lifestyle_tags FROM life_aboard la2 WHERE la2.user_id = mine.user_id
              ) THEN 10 ELSE 0 END
          ) AS score
        FROM mine
        JOIN profiles p ON p.user_id <> mine.user_id
        JOIN users u ON u.id = p.user_id
        JOIN preferences pref ON pref.user_id = p.user_id
        JOIN life_aboard la ON la.user_id = p.user_id
        JOIN current_zones cz ON cz.user_id = p.user_id
        JOIN future_routes fr ON fr.user_id = p.user_id AND fr.is_active
        WHERE u.status = 'active'
          AND u.email_verified_at IS NOT NULL
          AND p.is_complete = true
          AND p.visibility = 'visible'
          AND date_part('year', age(p.birth_date)) BETWEEN mine.age_min AND mine.age_max
          AND (
            mine.gender_targets = 'everyone'
            OR (mine.gender_targets = 'women' AND p.gender = 'woman')
            OR (mine.gender_targets = 'men' AND p.gender = 'man')
          )
          AND (
            p.search_gender = 'everyone'
            OR (p.search_gender = 'women' AND mine.gender = 'woman')
            OR (p.search_gender = 'men' AND mine.gender = 'man')
          )
          AND (
            cz.zone = mine.current_zone
            OR fr.destination_zone = mine.current_zone
            OR mine.future_destination_zone = cz.zone
            OR mine.future_destination_zone = fr.destination_zone
          )
          AND pref.intentions && mine.intentions
          AND NOT EXISTS (
            SELECT 1 FROM likes l
            WHERE l.user_id = mine.user_id AND l.target_user_id = p.user_id
          )
          AND NOT EXISTS (
            SELECT 1 FROM passes pa
            WHERE pa.user_id = mine.user_id
              AND pa.target_user_id = p.user_id
              AND pa.expires_at > now()
          )
          AND NOT EXISTS (
            SELECT 1 FROM blocks b
            WHERE (b.blocker_id = mine.user_id AND b.blocked_id = p.user_id)
               OR (b.blocker_id = p.user_id AND b.blocked_id = mine.user_id)
          )
          AND NOT EXISTS (
            SELECT 1 FROM matches m
            WHERE m.status = 'active'
              AND m.user_a_id = LEAST(mine.user_id, p.user_id)
              AND m.user_b_id = GREATEST(mine.user_id, p.user_id)
          )
          AND (
            SELECT count(*)
            FROM profile_photos pp
            WHERE pp.user_id = p.user_id
              AND pp.deleted_at IS NULL
              AND pp.moderation_status = 'approved'
          ) >= $2
        ORDER BY score DESC, p.updated_at DESC
        LIMIT 50
      `,
      [userId, env.MIN_PROFILE_PHOTOS],
    );

    return result.rows.map((row) => ({
      profile: serializeProfile(row),
      photos: (row.photos ?? []).map((photo) => serializePhoto(photo, photoStorage)),
      lifeAboard: serializeLifeAboard({
        user_id: row.user_id,
        status: row.life_status,
        boat_or_project: row.boat_or_project,
        sailing_type: row.sailing_type,
        experience: row.experience,
        lifestyle_tags: row.lifestyle_tags,
        updated_at: row.life_updated_at,
      }),
      currentZone: serializeCurrentZone({
        user_id: row.user_id,
        zone: row.zone,
        country: row.zone_country,
        port_id: row.zone_port_id,
        updated_at: row.zone_updated_at,
      }),
      futureRoute: serializeFutureRoute({
        id: row.route_id,
        user_id: row.user_id,
        destination_zone: row.destination_zone,
        destination_country: row.destination_country,
        destination_port_id: row.destination_port_id,
        start_period: row.start_period,
        end_period: row.end_period,
        flexibility: row.flexibility,
        comment: row.comment,
        is_active: row.is_active,
        updated_at: row.route_updated_at,
      }),
      intentions: row.target_intentions ?? [],
      score: Number(row.score ?? 0),
    }));
  }
}
