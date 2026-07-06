BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS citext;

DO $$
BEGIN
  CREATE TYPE account_status AS ENUM ('pending_email_verification', 'active', 'suspended', 'deleted');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE gender AS ENUM ('woman', 'man', 'non_binary', 'other');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE search_gender AS ENUM ('women', 'men', 'everyone');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE board_status AS ENUM ('liveaboard', 'long_distance_sailor', 'owner', 'crew', 'future_liveaboard');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE sailing_experience AS ENUM ('beginner', 'intermediate', 'confirmed', 'expert');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE route_flexibility AS ENUM ('fixed', 'flexible', 'very_flexible');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE intention AS ENUM (
    'serious_relationship',
    'casual_dating',
    'friendship',
    'crew',
    'sailing_project',
    'liveaboard_project'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE photo_moderation_status AS ENUM ('pending', 'approved', 'rejected');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE match_status AS ENUM ('active', 'blocked', 'deleted');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE report_reason AS ENUM (
    'fake_profile',
    'harassment',
    'inappropriate_content',
    'suspicious_behavior',
    'other'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE report_status AS ENUM ('new_report', 'in_review', 'resolved', 'rejected');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE OR REPLACE FUNCTION touch_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION is_public_zone_text(value text)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT value IS NULL
    OR (
      value !~* '[-+]?[0-9]{1,2}([.,][0-9]+)?[[:space:]]*[,;/][[:space:]]*[-+]?[0-9]{1,3}([.,][0-9]+)?'
      AND value !~* '\m(gps|latitude|longitude|lat|lon|coordinates|coordonnees|marina|quai|ponton|anneau|mouillage)\M'
      AND value !~* '\mport[[:space:]]+(de|du|des|d'')\M'
    );
$$;

CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email citext NOT NULL UNIQUE,
  password_hash text NOT NULL,
  email_verified_at timestamptz,
  status account_status NOT NULL DEFAULT 'pending_email_verification',
  plan_tier text NOT NULL DEFAULT 'free' CHECK (plan_tier IN ('free', 'premium')),
  premium_expires_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  last_login_at timestamptz,
  deleted_at timestamptz,
  CHECK ((status = 'deleted') = (deleted_at IS NOT NULL))
);

DROP TRIGGER IF EXISTS users_touch_updated_at ON users;
CREATE TRIGGER users_touch_updated_at
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

CREATE TABLE IF NOT EXISTS refresh_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash text NOT NULL UNIQUE,
  rotated_from_id uuid REFERENCES refresh_tokens(id) ON DELETE SET NULL,
  user_agent text,
  ip_address inet,
  expires_at timestamptz NOT NULL,
  revoked_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS refresh_tokens_user_active_idx
  ON refresh_tokens(user_id, expires_at)
  WHERE revoked_at IS NULL;

CREATE TABLE IF NOT EXISTS email_verification_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash text NOT NULL UNIQUE,
  expires_at timestamptz NOT NULL,
  used_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS password_reset_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash text NOT NULL UNIQUE,
  expires_at timestamptz NOT NULL,
  used_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS profiles (
  user_id uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  first_name text NOT NULL CHECK (char_length(first_name) BETWEEN 1 AND 80),
  birth_date date NOT NULL,
  gender gender NOT NULL,
  search_gender search_gender NOT NULL DEFAULT 'everyone',
  languages text[] NOT NULL DEFAULT '{}',
  bio text NOT NULL CHECK (char_length(bio) BETWEEN 1 AND 1000 AND is_public_zone_text(bio)),
  is_complete boolean NOT NULL DEFAULT false,
  visibility text NOT NULL DEFAULT 'visible' CHECK (visibility IN ('visible', 'paused')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS profiles_touch_updated_at ON profiles;
CREATE TRIGGER profiles_touch_updated_at
BEFORE UPDATE ON profiles
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

CREATE TABLE IF NOT EXISTS profile_intentions (
  user_id uuid NOT NULL REFERENCES profiles(user_id) ON DELETE CASCADE,
  intention intention NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, intention)
);

CREATE TABLE IF NOT EXISTS profile_photos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  storage_provider text NOT NULL DEFAULT 'external',
  storage_bucket text NOT NULL,
  storage_key text NOT NULL,
  public_url text,
  content_type text NOT NULL CHECK (content_type IN ('image/jpeg', 'image/png', 'image/webp')),
  size_bytes integer CHECK (size_bytes IS NULL OR size_bytes BETWEEN 1 AND 10485760),
  is_primary boolean NOT NULL DEFAULT false,
  sort_order integer NOT NULL DEFAULT 0 CHECK (sort_order >= 0),
  moderation_status photo_moderation_status NOT NULL DEFAULT 'pending',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  UNIQUE (storage_bucket, storage_key)
);

CREATE UNIQUE INDEX IF NOT EXISTS profile_photos_one_primary_per_user_idx
  ON profile_photos(user_id)
  WHERE is_primary AND deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS profile_photos_user_order_idx
  ON profile_photos(user_id, sort_order)
  WHERE deleted_at IS NULL;

DROP TRIGGER IF EXISTS profile_photos_touch_updated_at ON profile_photos;
CREATE TRIGGER profile_photos_touch_updated_at
BEFORE UPDATE ON profile_photos
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

CREATE TABLE IF NOT EXISTS life_aboard (
  user_id uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  status board_status NOT NULL,
  boat_or_project text NOT NULL CHECK (char_length(boat_or_project) BETWEEN 1 AND 160 AND is_public_zone_text(boat_or_project)),
  sailing_type text NOT NULL CHECK (char_length(sailing_type) BETWEEN 1 AND 120),
  experience sailing_experience NOT NULL,
  lifestyle_tags text[] NOT NULL DEFAULT '{}',
  updated_at timestamptz NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS life_aboard_touch_updated_at ON life_aboard;
CREATE TRIGGER life_aboard_touch_updated_at
BEFORE UPDATE ON life_aboard
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

CREATE TABLE IF NOT EXISTS current_zones (
  user_id uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  zone text NOT NULL CHECK (char_length(zone) BETWEEN 2 AND 120 AND is_public_zone_text(zone)),
  country text CHECK (country IS NULL OR char_length(country) BETWEEN 2 AND 80),
  updated_at timestamptz NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS current_zones_touch_updated_at ON current_zones;
CREATE TRIGGER current_zones_touch_updated_at
BEFORE UPDATE ON current_zones
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

CREATE TABLE IF NOT EXISTS future_routes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  destination_zone text NOT NULL CHECK (char_length(destination_zone) BETWEEN 2 AND 120 AND is_public_zone_text(destination_zone)),
  destination_country text CHECK (destination_country IS NULL OR char_length(destination_country) BETWEEN 2 AND 80),
  start_period text NOT NULL CHECK (char_length(start_period) BETWEEN 1 AND 80),
  end_period text NOT NULL CHECK (char_length(end_period) BETWEEN 1 AND 80),
  flexibility route_flexibility NOT NULL,
  comment text NOT NULL DEFAULT '' CHECK (char_length(comment) <= 500 AND is_public_zone_text(comment)),
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS future_routes_one_active_per_user_idx
  ON future_routes(user_id)
  WHERE is_active;

DROP TRIGGER IF EXISTS future_routes_touch_updated_at ON future_routes;
CREATE TRIGGER future_routes_touch_updated_at
BEFORE UPDATE ON future_routes
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

CREATE TABLE IF NOT EXISTS preferences (
  user_id uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  age_min integer NOT NULL CHECK (age_min BETWEEN 18 AND 99),
  age_max integer NOT NULL CHECK (age_max BETWEEN 18 AND 99),
  gender_targets search_gender NOT NULL DEFAULT 'everyone',
  zones text[] NOT NULL DEFAULT '{}',
  intentions intention[] NOT NULL DEFAULT '{}',
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (age_min <= age_max),
  CHECK (cardinality(intentions) > 0)
);

DROP TRIGGER IF EXISTS preferences_touch_updated_at ON preferences;
CREATE TRIGGER preferences_touch_updated_at
BEFORE UPDATE ON preferences
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

CREATE TABLE IF NOT EXISTS likes (
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  target_user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, target_user_id),
  CHECK (user_id <> target_user_id)
);

CREATE INDEX IF NOT EXISTS likes_target_idx ON likes(target_user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS passes (
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  target_user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz NOT NULL DEFAULT (now() + interval '30 days'),
  PRIMARY KEY (user_id, target_user_id),
  CHECK (user_id <> target_user_id)
);

CREATE INDEX IF NOT EXISTS passes_user_active_idx ON passes(user_id, expires_at);

CREATE TABLE IF NOT EXISTS matches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_a_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  user_b_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status match_status NOT NULL DEFAULT 'active',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (user_a_id < user_b_id),
  UNIQUE (user_a_id, user_b_id)
);

DROP TRIGGER IF EXISTS matches_touch_updated_at ON matches;
CREATE TRIGGER matches_touch_updated_at
BEFORE UPDATE ON matches
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

CREATE TABLE IF NOT EXISTS conversations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id uuid NOT NULL UNIQUE REFERENCES matches(id) ON DELETE CASCADE,
  user_a_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  user_b_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  last_message_at timestamptz,
  CHECK (user_a_id < user_b_id)
);

CREATE INDEX IF NOT EXISTS conversations_user_a_idx ON conversations(user_a_id, last_message_at DESC NULLS LAST);
CREATE INDEX IF NOT EXISTS conversations_user_b_idx ON conversations(user_b_id, last_message_at DESC NULLS LAST);

CREATE TABLE IF NOT EXISTS messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id uuid NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content text NOT NULL CHECK (char_length(content) BETWEEN 1 AND 1000),
  created_at timestamptz NOT NULL DEFAULT now(),
  read_at timestamptz,
  deleted_at timestamptz
);

CREATE INDEX IF NOT EXISTS messages_conversation_created_idx
  ON messages(conversation_id, created_at ASC)
  WHERE deleted_at IS NULL;

CREATE TABLE IF NOT EXISTS blocks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  blocker_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  blocked_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (blocker_id, blocked_id),
  CHECK (blocker_id <> blocked_id)
);

CREATE INDEX IF NOT EXISTS blocks_blocked_idx ON blocks(blocked_id);

CREATE TABLE IF NOT EXISTS reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id uuid REFERENCES users(id) ON DELETE SET NULL,
  reported_id uuid REFERENCES users(id) ON DELETE SET NULL,
  reported_user_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
  conversation_id uuid REFERENCES conversations(id) ON DELETE SET NULL,
  message_id uuid REFERENCES messages(id) ON DELETE SET NULL,
  reason report_reason NOT NULL,
  comment text CHECK (comment IS NULL OR char_length(comment) <= 2000),
  status report_status NOT NULL DEFAULT 'new_report',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (reporter_id IS NULL OR reported_id IS NULL OR reporter_id <> reported_id)
);

CREATE INDEX IF NOT EXISTS reports_status_created_idx ON reports(status, created_at DESC);

DROP TRIGGER IF EXISTS reports_touch_updated_at ON reports;
CREATE TRIGGER reports_touch_updated_at
BEFORE UPDATE ON reports
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

CREATE TABLE IF NOT EXISTS subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider text NOT NULL,
  provider_customer_id text,
  provider_subscription_id text,
  status text NOT NULL CHECK (status IN ('trialing', 'active', 'past_due', 'canceled', 'expired')),
  started_at timestamptz NOT NULL DEFAULT now(),
  current_period_end timestamptz,
  canceled_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS subscriptions_user_status_idx ON subscriptions(user_id, status);

DROP TRIGGER IF EXISTS subscriptions_touch_updated_at ON subscriptions;
CREATE TRIGGER subscriptions_touch_updated_at
BEFORE UPDATE ON subscriptions
FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

CREATE TABLE IF NOT EXISTS user_feature_flags (
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  feature_key text NOT NULL,
  enabled boolean NOT NULL DEFAULT false,
  source text NOT NULL DEFAULT 'manual' CHECK (source IN ('manual', 'subscription', 'promotion')),
  expires_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, feature_key)
);

COMMIT;
