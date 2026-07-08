import type { DbClient } from '../db/pool.js';
import { pool, withTransaction } from '../db/pool.js';
import { env } from '../config/env.js';
import { BadRequestError, ForbiddenError, NotFoundError, ValidationError } from '../errors.js';
import {
  serializeCurrentZone,
  serializeFutureRoute,
  serializeLifeAboard,
  serializePhoto,
  serializePreferences,
  serializeProfile,
  serializeUser,
} from '../serializers.js';
import type { PhotoStorage } from '../storage/photo-storage.js';
import { photoStorage } from '../storage/photo-storage.js';
import { AuthService } from './auth-service.js';
import { EntitlementService } from './entitlement-service.js';

type Row = Record<string, unknown>;

const authService = new AuthService();
const entitlementService = new EntitlementService();

function assertAdultBirthDate(birthDate: string) {
  const date = new Date(`${birthDate}T00:00:00.000Z`);
  const now = new Date();
  let age = now.getUTCFullYear() - date.getUTCFullYear();
  const monthDiff = now.getUTCMonth() - date.getUTCMonth();
  if (monthDiff < 0 || (monthDiff === 0 && now.getUTCDate() < date.getUTCDate())) {
    age -= 1;
  }
  if (age < 18 || age > 99) {
    throw new ValidationError('Age valide obligatoire, entre 18 et 99 ans.');
  }
}

async function refreshProfileCompleteness(client: DbClient, userId: string) {
  await client.query(
    `
      UPDATE profiles p
      SET is_complete =
        EXISTS (SELECT 1 FROM life_aboard la WHERE la.user_id = p.user_id)
        AND EXISTS (SELECT 1 FROM current_zones cz WHERE cz.user_id = p.user_id)
        AND EXISTS (SELECT 1 FROM future_routes fr WHERE fr.user_id = p.user_id AND fr.is_active)
        AND EXISTS (SELECT 1 FROM preferences pref WHERE pref.user_id = p.user_id)
        AND (
          SELECT count(*)
          FROM profile_photos pp
          WHERE pp.user_id = p.user_id AND pp.deleted_at IS NULL
        ) >= $2
      WHERE p.user_id = $1
    `,
    [userId, env.MIN_PROFILE_PHOTOS],
  );
}

async function getSingle(client: DbClient, sql: string, values: unknown[]) {
  const result = await client.query<Row>(sql, values);
  return result.rows[0] ?? null;
}

async function getPortOrThrow(client: DbClient, portId: string) {
  const port = await getSingle(client, `SELECT * FROM ports WHERE id = $1`, [portId]);
  if (!port) {
    throw new BadRequestError('Port introuvable.');
  }
  return port;
}

export class ProfileService {
  constructor(private readonly storage: PhotoStorage = photoStorage) {}

  async getMe(userId: string) {
    const user = await authService.getUsableUser(pool, userId);
    const [profile, photos, lifeAboard, currentZone, futureRoute, preferences, features] =
      await Promise.all([
        getSingle(pool, `SELECT * FROM profiles WHERE user_id = $1`, [userId]),
        pool.query<Row>(
          `
            SELECT *
            FROM profile_photos
            WHERE user_id = $1 AND deleted_at IS NULL
            ORDER BY sort_order ASC, created_at ASC
          `,
          [userId],
        ),
        getSingle(pool, `SELECT * FROM life_aboard WHERE user_id = $1`, [userId]),
        getSingle(pool, `SELECT * FROM current_zones WHERE user_id = $1`, [userId]),
        getSingle(pool, `SELECT * FROM future_routes WHERE user_id = $1 AND is_active LIMIT 1`, [
          userId,
        ]),
        getSingle(pool, `SELECT * FROM preferences WHERE user_id = $1`, [userId]),
        entitlementService.listActiveFeatures(userId),
      ]);

    return {
      user: serializeUser(user),
      profile: serializeProfile(profile),
      photos: photos.rows.map((photo) => serializePhoto(photo, this.storage)),
      lifeAboard: serializeLifeAboard(lifeAboard),
      currentZone: serializeCurrentZone(currentZone),
      futureRoute: serializeFutureRoute(futureRoute),
      preferences: serializePreferences(preferences),
      features,
    };
  }

  async putProfile(
    userId: string,
    input: {
      firstName: string;
      birthDate: string;
      gender: string;
      searchGender: string;
      languages: string[];
      bio: string;
    },
  ) {
    assertAdultBirthDate(input.birthDate);
    return withTransaction(async (client) => {
      await authService.requireActiveVerifiedUser(client, userId);
      const result = await client.query<Row>(
        `
          INSERT INTO profiles (
            user_id,
            first_name,
            birth_date,
            gender,
            search_gender,
            languages,
            bio
          )
          VALUES ($1, $2, $3::date, $4, $5, $6::text[], $7)
          ON CONFLICT (user_id) DO UPDATE
          SET first_name = EXCLUDED.first_name,
              birth_date = EXCLUDED.birth_date,
              gender = EXCLUDED.gender,
              search_gender = EXCLUDED.search_gender,
              languages = EXCLUDED.languages,
              bio = EXCLUDED.bio
          RETURNING *
        `,
        [
          userId,
          input.firstName,
          input.birthDate,
          input.gender,
          input.searchGender,
          input.languages,
          input.bio,
        ],
      );
      await refreshProfileCompleteness(client, userId);
      const updated = await getSingle(client, `SELECT * FROM profiles WHERE user_id = $1`, [userId]);
      return serializeProfile(updated ?? result.rows[0]);
    });
  }

  async putLifeAboard(
    userId: string,
    input: {
      status: string;
      boatOrProject: string;
      sailingType: string;
      experience: string;
      lifestyleTags: string[];
    },
  ) {
    return withTransaction(async (client) => {
      await authService.requireActiveVerifiedUser(client, userId);
      const result = await client.query<Row>(
        `
          INSERT INTO life_aboard (
            user_id,
            status,
            boat_or_project,
            sailing_type,
            experience,
            lifestyle_tags
          )
          VALUES ($1, $2, $3, $4, $5, $6::text[])
          ON CONFLICT (user_id) DO UPDATE
          SET status = EXCLUDED.status,
              boat_or_project = EXCLUDED.boat_or_project,
              sailing_type = EXCLUDED.sailing_type,
              experience = EXCLUDED.experience,
              lifestyle_tags = EXCLUDED.lifestyle_tags
          RETURNING *
        `,
        [
          userId,
          input.status,
          input.boatOrProject,
          input.sailingType,
          input.experience,
          input.lifestyleTags,
        ],
      );
      await refreshProfileCompleteness(client, userId);
      return serializeLifeAboard(result.rows[0]);
    });
  }

  async putCurrentZone(userId: string, input: { zone: string; country?: string; portId?: string }) {
    return withTransaction(async (client) => {
      await authService.requireActiveVerifiedUser(client, userId);
      const port = input.portId ? await getPortOrThrow(client, input.portId) : null;
      const zone = port ? String(port.region) : input.zone;
      const country = port ? String(port.country) : (input.country ?? null);
      const result = await client.query<Row>(
        `
          INSERT INTO current_zones (user_id, zone, country, port_id)
          VALUES ($1, $2, $3, $4)
          ON CONFLICT (user_id) DO UPDATE
          SET zone = EXCLUDED.zone,
              country = EXCLUDED.country,
              port_id = EXCLUDED.port_id
          RETURNING *
        `,
        [userId, zone, country, port?.id ?? null],
      );
      await refreshProfileCompleteness(client, userId);
      return serializeCurrentZone(result.rows[0]);
    });
  }

  async putFutureRoute(
    userId: string,
    input: {
      destinationZone: string;
      destinationCountry?: string;
      destinationPortId?: string;
      startPeriod: string;
      endPeriod: string;
      flexibility: string;
      comment: string;
    },
  ) {
    return withTransaction(async (client) => {
      await authService.requireActiveVerifiedUser(client, userId);
      const port = input.destinationPortId
        ? await getPortOrThrow(client, input.destinationPortId)
        : null;
      const destinationZone = port ? String(port.region) : input.destinationZone;
      const destinationCountry = port
        ? String(port.country)
        : (input.destinationCountry ?? null);
      await client.query(`UPDATE future_routes SET is_active = false WHERE user_id = $1 AND is_active`, [
        userId,
      ]);
      const result = await client.query<Row>(
        `
          INSERT INTO future_routes (
            user_id,
            destination_zone,
            destination_country,
            destination_port_id,
            start_period,
            end_period,
            flexibility,
            comment,
            is_active
          )
          VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true)
          RETURNING *
        `,
        [
          userId,
          destinationZone,
          destinationCountry,
          port?.id ?? null,
          input.startPeriod,
          input.endPeriod,
          input.flexibility,
          input.comment,
        ],
      );
      await refreshProfileCompleteness(client, userId);
      return serializeFutureRoute(result.rows[0]);
    });
  }

  async putPreferences(
    userId: string,
    input: {
      ageMin: number;
      ageMax: number;
      genderTargets: string;
      zones: string[];
      intentions: string[];
    },
  ) {
    return withTransaction(async (client) => {
      await authService.requireActiveVerifiedUser(client, userId);
      const result = await client.query<Row>(
        `
          INSERT INTO preferences (
            user_id,
            age_min,
            age_max,
            gender_targets,
            zones,
            intentions
          )
          VALUES ($1, $2, $3, $4, $5::text[], $6::intention[])
          ON CONFLICT (user_id) DO UPDATE
          SET age_min = EXCLUDED.age_min,
              age_max = EXCLUDED.age_max,
              gender_targets = EXCLUDED.gender_targets,
              zones = EXCLUDED.zones,
              intentions = EXCLUDED.intentions
          RETURNING *
        `,
        [
          userId,
          input.ageMin,
          input.ageMax,
          input.genderTargets,
          input.zones,
          input.intentions,
        ],
      );
      await refreshProfileCompleteness(client, userId);
      return serializePreferences(result.rows[0]);
    });
  }

  async createPhotoUploadUrl(userId: string, input: { contentType: 'image/jpeg' | 'image/png' | 'image/webp' }) {
    await authService.requireActiveVerifiedUser(pool, userId);
    return this.storage.createUploadUrl({
      userId,
      contentType: input.contentType,
    });
  }

  async createPhoto(
    userId: string,
    input: {
      storageBucket?: string;
      storageKey: string;
      publicUrl?: string;
      contentType: string;
      sizeBytes?: number;
      isPrimary: boolean;
      order: number;
    },
  ) {
    if (!input.storageKey.startsWith(`users/${userId}/`)) {
      throw new ForbiddenError('Cle de stockage photo refusee.');
    }

    return withTransaction(async (client) => {
      await authService.requireActiveVerifiedUser(client, userId);
      const countResult = await client.query<{ count: string }>(
        `SELECT count(*) FROM profile_photos WHERE user_id = $1 AND deleted_at IS NULL`,
        [userId],
      );
      const shouldBePrimary = input.isPrimary || Number(countResult.rows[0].count) === 0;
      if (shouldBePrimary) {
        await client.query(
          `UPDATE profile_photos SET is_primary = false WHERE user_id = $1 AND deleted_at IS NULL`,
          [userId],
        );
      }
      const result = await client.query<Row>(
        `
          INSERT INTO profile_photos (
            user_id,
            storage_provider,
            storage_bucket,
            storage_key,
            public_url,
            content_type,
            size_bytes,
            is_primary,
            sort_order
          )
          VALUES ($1, 'external', $2, $3, $4, $5, $6, $7, $8)
          RETURNING *
        `,
        [
          userId,
          input.storageBucket ?? env.PHOTO_BUCKET,
          input.storageKey,
          input.publicUrl ?? null,
          input.contentType,
          input.sizeBytes ?? null,
          shouldBePrimary,
          input.order,
        ],
      );
      await refreshProfileCompleteness(client, userId);
      return serializePhoto(result.rows[0], this.storage);
    });
  }

  async updatePhoto(userId: string, photoId: string, input: { isPrimary?: boolean; order?: number }) {
    return withTransaction(async (client) => {
      await authService.requireActiveVerifiedUser(client, userId);
      const existing = await getSingle(
        client,
        `SELECT * FROM profile_photos WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL`,
        [photoId, userId],
      );
      if (!existing) {
        throw new NotFoundError('Photo introuvable.');
      }
      if (input.isPrimary === true) {
        await client.query(
          `UPDATE profile_photos SET is_primary = false WHERE user_id = $1 AND deleted_at IS NULL`,
          [userId],
        );
      }
      const result = await client.query<Row>(
        `
          UPDATE profile_photos
          SET is_primary = COALESCE($3, is_primary),
              sort_order = COALESCE($4, sort_order)
          WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL
          RETURNING *
        `,
        [photoId, userId, input.isPrimary ?? null, input.order ?? null],
      );
      await refreshProfileCompleteness(client, userId);
      return serializePhoto(result.rows[0], this.storage);
    });
  }

  async deletePhoto(userId: string, photoId: string) {
    await withTransaction(async (client) => {
      await authService.requireActiveVerifiedUser(client, userId);
      const result = await client.query(
        `
          UPDATE profile_photos
          SET deleted_at = now(), is_primary = false
          WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL
        `,
        [photoId, userId],
      );
      if (!result.rowCount) {
        throw new NotFoundError('Photo introuvable.');
      }
      await refreshProfileCompleteness(client, userId);
    });
  }

  async ensureDiscoverable(userId: string) {
    const user = await authService.requireActiveVerifiedUser(pool, userId);
    const profile = await getSingle(pool, `SELECT * FROM profiles WHERE user_id = $1`, [userId]);
    if (!profile?.is_complete) {
      throw new BadRequestError('Completez votre profil avant d acceder a Decouvrir.');
    }
    return user;
  }
}
