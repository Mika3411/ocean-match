import type { PhotoStorage } from './storage/photo-storage.js';

export function serializeUser(row: Record<string, unknown>) {
  return {
    id: row.id,
    email: row.email,
    emailVerified: Boolean(row.email_verified_at),
    status: row.status,
    planTier: row.plan_tier,
    premiumExpiresAt: row.premium_expires_at,
    createdAt: row.created_at,
    lastLoginAt: row.last_login_at,
  };
}

export function serializeProfile(row: Record<string, unknown> | undefined | null) {
  if (!row) return null;
  return {
    userId: row.user_id,
    firstName: row.first_name,
    birthDate: row.birth_date,
    gender: row.gender,
    searchGender: row.search_gender,
    languages: row.languages ?? [],
    bio: row.bio,
    isComplete: row.is_complete,
    visibility: row.visibility,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

export function serializePhoto(row: Record<string, unknown>, storage: PhotoStorage) {
  return {
    id: row.id,
    userId: row.user_id,
    url: row.public_url || storage.publicUrlFor(String(row.storage_key)),
    storageBucket: row.storage_bucket,
    storageKey: row.storage_key,
    isPrimary: row.is_primary,
    order: row.sort_order,
    status: row.moderation_status,
    contentType: row.content_type,
    sizeBytes: row.size_bytes,
    createdAt: row.created_at,
  };
}

export function serializeLifeAboard(row: Record<string, unknown> | undefined | null) {
  if (!row) return null;
  return {
    userId: row.user_id,
    status: row.status,
    boatOrProject: row.boat_or_project,
    sailingType: row.sailing_type,
    experience: row.experience,
    lifestyleTags: row.lifestyle_tags ?? [],
    updatedAt: row.updated_at,
  };
}

export function serializeCurrentZone(row: Record<string, unknown> | undefined | null) {
  if (!row) return null;
  return {
    userId: row.user_id,
    zone: row.zone,
    country: row.country,
    updatedAt: row.updated_at,
  };
}

export function serializeFutureRoute(row: Record<string, unknown> | undefined | null) {
  if (!row) return null;
  return {
    id: row.id,
    userId: row.user_id,
    destinationZone: row.destination_zone,
    destinationCountry: row.destination_country,
    startPeriod: row.start_period,
    endPeriod: row.end_period,
    flexibility: row.flexibility,
    comment: row.comment,
    isActive: row.is_active,
    updatedAt: row.updated_at,
  };
}

export function serializePreferences(row: Record<string, unknown> | undefined | null) {
  if (!row) return null;
  return {
    userId: row.user_id,
    ageMin: row.age_min,
    ageMax: row.age_max,
    genderTargets: row.gender_targets,
    zones: row.zones ?? [],
    intentions: row.intentions ?? [],
    updatedAt: row.updated_at,
  };
}

export function serializeMatch(row: Record<string, unknown> | undefined | null) {
  if (!row) return null;
  return {
    id: row.id,
    user1Id: row.user_a_id,
    user2Id: row.user_b_id,
    status: row.status,
    createdAt: row.created_at,
  };
}

export function serializeConversation(row: Record<string, unknown> | undefined | null) {
  if (!row) return null;
  return {
    id: row.id,
    matchId: row.match_id,
    user1Id: row.user_a_id,
    user2Id: row.user_b_id,
    createdAt: row.created_at,
    lastMessageAt: row.last_message_at,
  };
}

export function serializeMessage(row: Record<string, unknown> | undefined | null) {
  if (!row) return null;
  return {
    id: row.id,
    conversationId: row.conversation_id,
    senderId: row.sender_id,
    content: row.content,
    createdAt: row.created_at,
    readAt: row.read_at,
    deletedAt: row.deleted_at,
  };
}

export function serializeBlock(row: Record<string, unknown> | undefined | null) {
  if (!row) return null;
  return {
    id: row.id,
    blockerId: row.blocker_id,
    blockedId: row.blocked_id,
    createdAt: row.created_at,
  };
}

export function serializeReport(row: Record<string, unknown> | undefined | null) {
  if (!row) return null;
  return {
    id: row.id,
    reporterId: row.reporter_id,
    reportedId: row.reported_id,
    conversationId: row.conversation_id,
    messageId: row.message_id,
    reason: row.reason,
    comment: row.comment,
    status: row.status,
    createdAt: row.created_at,
  };
}
