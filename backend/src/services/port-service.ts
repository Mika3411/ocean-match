import { pool } from '../db/pool.js';
import { serializePortActivity } from '../serializers.js';
import { ProfileService } from './profile-service.js';

type PortActivityRow = Record<string, unknown>;

const profileService = new ProfileService();

export class PortService {
  async list(userId: string) {
    await profileService.ensureDiscoverable(userId);

    const result = await pool.query<PortActivityRow>(
      `
        WITH public_profiles AS (
          SELECT p.user_id
          FROM profiles p
          JOIN users u ON u.id = p.user_id
          WHERE u.status = 'active'
            AND u.email_verified_at IS NOT NULL
            AND p.is_complete = true
            AND p.visibility = 'visible'
        ),
        mine AS (
          SELECT
            cz.port_id AS current_port_id,
            fr.destination_port_id
          FROM public_profiles pp
          LEFT JOIN current_zones cz ON cz.user_id = pp.user_id
          LEFT JOIN future_routes fr ON fr.user_id = pp.user_id AND fr.is_active
          WHERE pp.user_id = $1
        ),
        current_counts AS (
          SELECT cz.port_id, count(*)::int AS current_count
          FROM current_zones cz
          JOIN public_profiles pp ON pp.user_id = cz.user_id
          WHERE cz.port_id IS NOT NULL
          GROUP BY cz.port_id
        ),
        destination_counts AS (
          SELECT fr.destination_port_id AS port_id, count(*)::int AS destination_count
          FROM future_routes fr
          JOIN public_profiles pp ON pp.user_id = fr.user_id
          WHERE fr.is_active
            AND fr.destination_port_id IS NOT NULL
          GROUP BY fr.destination_port_id
        )
        SELECT
          ports.*,
          COALESCE(current_counts.current_count, 0) AS current_count,
          COALESCE(destination_counts.destination_count, 0) AS destination_count,
          mine.current_port_id = ports.id AS is_current_user_here,
          mine.destination_port_id = ports.id AS is_current_user_going
        FROM ports
        CROSS JOIN mine
        LEFT JOIN current_counts ON current_counts.port_id = ports.id
        LEFT JOIN destination_counts ON destination_counts.port_id = ports.id
        ORDER BY
          (COALESCE(current_counts.current_count, 0)
            + COALESCE(destination_counts.destination_count, 0)) DESC,
          ports.name ASC
      `,
      [userId],
    );

    return result.rows.map(serializePortActivity);
  }
}
