BEGIN;

CREATE TABLE IF NOT EXISTS feature_catalog (
  feature_key text PRIMARY KEY,
  feature_group text NOT NULL CHECK (
    feature_group IN ('matching', 'discovery', 'profile', 'trust', 'community', 'moderation')
  ),
  display_name text NOT NULL,
  description text NOT NULL,
  access_model text NOT NULL DEFAULT 'entitlement' CHECK (
    access_model IN ('entitlement', 'usage_quota', 'admin_only')
  ),
  mvp_state text NOT NULL DEFAULT 'not_exposed' CHECK (
    mvp_state IN ('not_exposed', 'internal_only', 'active')
  ),
  free_limit integer CHECK (free_limit IS NULL OR free_limit >= 0),
  config jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS feature_catalog_touch_updated_at ON feature_catalog;
CREATE TRIGGER feature_catalog_touch_updated_at
BEFORE UPDATE ON feature_catalog
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

INSERT INTO feature_catalog (
  feature_key,
  feature_group,
  display_name,
  description,
  access_model,
  mvp_state,
  free_limit,
  config
)
VALUES
  (
    'unlimited_likes',
    'matching',
    'Unlimited likes',
    'Removes future daily or rolling like quotas. The MVP currently has no enforced paid quota.',
    'usage_quota',
    'not_exposed',
    NULL,
    '{"keeps_text_messaging_free": true}'::jsonb
  ),
  (
    'see_who_liked_me',
    'matching',
    'See who liked me',
    'Allows a future dedicated view over incoming likes without changing reciprocal match rules.',
    'entitlement',
    'not_exposed',
    NULL,
    '{}'::jsonb
  ),
  (
    'advanced_filters',
    'discovery',
    'Advanced filters',
    'Enables future discovery filters beyond the MVP age, gender, zone and intention matching.',
    'entitlement',
    'not_exposed',
    NULL,
    '{}'::jsonb
  ),
  (
    'multi_future_routes',
    'profile',
    'Multiple future routes',
    'Allows multiple active future routes after the MVP one-active-route constraint is lifted.',
    'entitlement',
    'not_exposed',
    1,
    '{"mvp_active_route_limit": 1}'::jsonb
  ),
  (
    'multi_zone_visibility',
    'profile',
    'Multi-zone visibility',
    'Allows a profile to be visible in several broad public zones without exposing exact positions.',
    'entitlement',
    'not_exposed',
    1,
    '{"mvp_visibility_zone_limit": 1}'::jsonb
  ),
  (
    'photo_verification',
    'trust',
    'Photo verification',
    'Adds future selfie or identity photo review state without blocking MVP profile photos.',
    'entitlement',
    'not_exposed',
    NULL,
    '{}'::jsonb
  ),
  (
    'events',
    'community',
    'Events',
    'Prepares future marina-free community events or stopover meetups in broad zones.',
    'entitlement',
    'not_exposed',
    NULL,
    '{"default_event_status": "draft"}'::jsonb
  ),
  (
    'moderation_backoffice',
    'moderation',
    'Moderation back-office',
    'Restricts future admin screens and moderation tooling to moderator accounts.',
    'admin_only',
    'not_exposed',
    NULL,
    '{}'::jsonb
  )
ON CONFLICT (feature_key) DO UPDATE
SET feature_group = EXCLUDED.feature_group,
    display_name = EXCLUDED.display_name,
    description = EXCLUDED.description,
    access_model = EXCLUDED.access_model,
    mvp_state = EXCLUDED.mvp_state,
    free_limit = EXCLUDED.free_limit,
    config = EXCLUDED.config;

ALTER TABLE user_feature_flags
  ADD COLUMN IF NOT EXISTS metadata jsonb NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE user_feature_flags
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

DROP TRIGGER IF EXISTS user_feature_flags_touch_updated_at ON user_feature_flags;
CREATE TRIGGER user_feature_flags_touch_updated_at
BEFORE UPDATE ON user_feature_flags
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'user_feature_flags_feature_key_fkey'
      AND conrelid = 'user_feature_flags'::regclass
  ) THEN
    ALTER TABLE user_feature_flags
      ADD CONSTRAINT user_feature_flags_feature_key_fkey
      FOREIGN KEY (feature_key)
      REFERENCES feature_catalog(feature_key)
      ON UPDATE CASCADE
      ON DELETE RESTRICT;
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS user_usage_counters (
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  counter_key text NOT NULL,
  period_start timestamptz NOT NULL,
  period_end timestamptz NOT NULL,
  used_count integer NOT NULL DEFAULT 0 CHECK (used_count >= 0),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, counter_key, period_start),
  CHECK (period_end > period_start)
);

CREATE INDEX IF NOT EXISTS user_usage_counters_lookup_idx
  ON user_usage_counters(user_id, counter_key, period_end DESC);

DROP TRIGGER IF EXISTS user_usage_counters_touch_updated_at ON user_usage_counters;
CREATE TRIGGER user_usage_counters_touch_updated_at
BEFORE UPDATE ON user_usage_counters
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

CREATE TABLE IF NOT EXISTS advanced_discovery_filters (
  user_id uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  board_statuses board_status[] NOT NULL DEFAULT '{}',
  sailing_experiences sailing_experience[] NOT NULL DEFAULT '{}',
  lifestyle_tags text[] NOT NULL DEFAULT '{}',
  languages text[] NOT NULL DEFAULT '{}',
  verified_photos_only boolean NOT NULL DEFAULT false,
  active_since_days integer CHECK (active_since_days IS NULL OR active_since_days BETWEEN 1 AND 365),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS advanced_discovery_filters_touch_updated_at ON advanced_discovery_filters;
CREATE TRIGGER advanced_discovery_filters_touch_updated_at
BEFORE UPDATE ON advanced_discovery_filters
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

CREATE TABLE IF NOT EXISTS profile_visibility_zones (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  zone text NOT NULL CHECK (char_length(zone) BETWEEN 2 AND 120 AND is_public_zone_text(zone)),
  country text CHECK (country IS NULL OR char_length(country) BETWEEN 2 AND 80),
  sort_order integer NOT NULL DEFAULT 0 CHECK (sort_order >= 0),
  is_active boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, zone, country)
);

CREATE INDEX IF NOT EXISTS profile_visibility_zones_user_active_idx
  ON profile_visibility_zones(user_id, sort_order)
  WHERE is_active;

DROP TRIGGER IF EXISTS profile_visibility_zones_touch_updated_at ON profile_visibility_zones;
CREATE TRIGGER profile_visibility_zones_touch_updated_at
BEFORE UPDATE ON profile_visibility_zones
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

CREATE TABLE IF NOT EXISTS photo_verification_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  profile_photo_id uuid REFERENCES profile_photos(id) ON DELETE SET NULL,
  selfie_storage_bucket text,
  selfie_storage_key text,
  status text NOT NULL DEFAULT 'pending' CHECK (
    status IN ('pending', 'approved', 'rejected', 'expired', 'canceled')
  ),
  rejection_reason text CHECK (rejection_reason IS NULL OR char_length(rejection_reason) <= 500),
  reviewed_by uuid REFERENCES users(id) ON DELETE SET NULL,
  reviewed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS photo_verification_requests_user_status_idx
  ON photo_verification_requests(user_id, status, created_at DESC);

DROP TRIGGER IF EXISTS photo_verification_requests_touch_updated_at ON photo_verification_requests;
CREATE TRIGGER photo_verification_requests_touch_updated_at
BEFORE UPDATE ON photo_verification_requests
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

CREATE TABLE IF NOT EXISTS events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organizer_user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title text NOT NULL CHECK (char_length(title) BETWEEN 1 AND 120),
  description text NOT NULL DEFAULT '' CHECK (
    char_length(description) <= 2000 AND is_public_zone_text(description)
  ),
  zone text NOT NULL CHECK (char_length(zone) BETWEEN 2 AND 120 AND is_public_zone_text(zone)),
  country text CHECK (country IS NULL OR char_length(country) BETWEEN 2 AND 80),
  starts_at timestamptz NOT NULL,
  ends_at timestamptz,
  status text NOT NULL DEFAULT 'draft' CHECK (
    status IN ('draft', 'pending_review', 'published', 'canceled', 'rejected')
  ),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (ends_at IS NULL OR ends_at > starts_at)
);

CREATE INDEX IF NOT EXISTS events_zone_starts_idx
  ON events(zone, starts_at)
  WHERE status = 'published';

DROP TRIGGER IF EXISTS events_touch_updated_at ON events;
CREATE TRIGGER events_touch_updated_at
BEFORE UPDATE ON events
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

CREATE TABLE IF NOT EXISTS event_participants (
  event_id uuid NOT NULL REFERENCES events(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'interested' CHECK (
    status IN ('interested', 'going', 'canceled', 'removed')
  ),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (event_id, user_id)
);

DROP TRIGGER IF EXISTS event_participants_touch_updated_at ON event_participants;
CREATE TRIGGER event_participants_touch_updated_at
BEFORE UPDATE ON event_participants
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

CREATE TABLE IF NOT EXISTS moderator_accounts (
  user_id uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  role text NOT NULL CHECK (role IN ('moderator', 'admin')),
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS moderator_accounts_touch_updated_at ON moderator_accounts;
CREATE TRIGGER moderator_accounts_touch_updated_at
BEFORE UPDATE ON moderator_accounts
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

CREATE TABLE IF NOT EXISTS moderation_cases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_type text NOT NULL CHECK (
    case_type IN ('report', 'photo', 'photo_verification', 'event', 'account')
  ),
  subject_user_id uuid REFERENCES users(id) ON DELETE SET NULL,
  report_id uuid REFERENCES reports(id) ON DELETE SET NULL,
  photo_id uuid REFERENCES profile_photos(id) ON DELETE SET NULL,
  photo_verification_request_id uuid REFERENCES photo_verification_requests(id) ON DELETE SET NULL,
  event_id uuid REFERENCES events(id) ON DELETE SET NULL,
  status text NOT NULL DEFAULT 'open' CHECK (
    status IN ('open', 'in_review', 'resolved', 'rejected', 'closed')
  ),
  priority integer NOT NULL DEFAULT 0 CHECK (priority BETWEEN 0 AND 3),
  assigned_to uuid REFERENCES moderator_accounts(user_id) ON DELETE SET NULL,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  opened_at timestamptz NOT NULL DEFAULT now(),
  closed_at timestamptz,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS moderation_cases_status_priority_idx
  ON moderation_cases(status, priority DESC, opened_at ASC);

DROP TRIGGER IF EXISTS moderation_cases_touch_updated_at ON moderation_cases;
CREATE TRIGGER moderation_cases_touch_updated_at
BEFORE UPDATE ON moderation_cases
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

CREATE TABLE IF NOT EXISTS moderation_actions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  case_id uuid NOT NULL REFERENCES moderation_cases(id) ON DELETE CASCADE,
  actor_user_id uuid REFERENCES moderator_accounts(user_id) ON DELETE SET NULL,
  action_type text NOT NULL CHECK (
    action_type IN (
      'assign',
      'approve',
      'reject',
      'warn',
      'suspend',
      'unsuspend',
      'close',
      'note'
    )
  ),
  notes text CHECK (notes IS NULL OR char_length(notes) <= 2000),
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS moderation_actions_case_created_idx
  ON moderation_actions(case_id, created_at DESC);

COMMIT;
