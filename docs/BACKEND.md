# Backend Ocean Match

Ce document decrit la base technique backend implementee dans `backend/`.

## Schema PostgreSQL

Migration initiale : `backend/migrations/001_init.sql`.

Modules couverts :

- auth : `users`, `refresh_tokens`, `email_verification_tokens`, `password_reset_tokens`
- utilisateurs : `users`, `user_feature_flags`
- profils : `profiles`, `profile_intentions`
- photos : `profile_photos`
- vie a bord : `life_aboard`
- zones actuelles : `current_zones`
- routes futures : `future_routes`
- preferences : `preferences`
- likes : `likes`
- passes : `passes`
- matchs : `matches`
- conversations : `conversations`
- messages : `messages`
- blocages : `blocks`
- signalements : `reports`
- Premium plus tard : `feature_catalog`, `subscriptions`,
  `user_feature_flags`, `user_usage_counters`, `advanced_discovery_filters`,
  `profile_visibility_zones`, `photo_verification_requests`, `events`,
  `event_participants`, `moderator_accounts`, `moderation_cases`,
  `moderation_actions`

Contraintes principales :

- `users.email` est unique et insensible a la casse via `citext`.
- `refresh_tokens.token_hash` est unique ; le token brut n est jamais stocke.
- une seule photo principale active par utilisateur ;
- une seule route future active par utilisateur dans le MVP ;
- un match est unique par paire d utilisateurs ;
- un blocage est unique par paire `blocker_id` / `blocked_id` ;
- les champs publics de localisation et de bio passent par `is_public_zone_text`.

## Endpoints REST

Base URL locale : `http://localhost:8080/v1`.

Auth :

```text
POST   /auth/signup
POST   /auth/login
POST   /auth/refresh
POST   /auth/logout
POST   /auth/verify-email
POST   /auth/resend-verification
POST   /auth/password-reset
POST   /auth/password-reset/confirm
DELETE /account
```

Utilisateur, profil et onboarding :

```text
GET /me
PUT /profile
PUT /life-aboard
PUT /current-zone
PUT /future-route
PUT /preferences
```

Photos :

```text
POST   /photos/upload-url
POST   /photos
PATCH  /photos/:id
DELETE /photos/:id
```

Decouverte et interactions :

```text
GET  /discovery
POST /likes
POST /passes
```

Matchs et messages :

```text
GET  /matches
GET  /conversations
GET  /conversations/:id/messages
POST /conversations/:id/messages
```

Securite utilisateur :

```text
GET    /blocks
POST   /blocks
DELETE /blocks/:id
POST   /reports
```

## Regles de securite

- API privee : PostgreSQL n est pas expose directement aux clients mobiles.
- Access token court : `ACCESS_TOKEN_TTL_MINUTES`, par defaut 15 minutes.
- Refresh token revocable : stockage hash HMAC, rotation sur `/auth/refresh`.
- Validation serveur obligatoire : tous les bodies publics passent par Zod.
- Email verifie obligatoire pour profil, decouverte, interactions et messages.
- Profil complet obligatoire pour `/discovery`.
- Aucune position exacte publique : rejet des coordonnees, GPS, marina, quai,
  ponton, mouillage et ports precis dans les champs publics.
- Photos externes : seules les metadonnees sont en base ; upload direct objet.
- Minimum 2 photos pour publier `profiles.is_complete`.
- Discovery exclut les comptes supprimes, suspendus, incomplets, bloques,
  deja likes, passes actifs et matchs actifs.
- Match cree uniquement si le like reciproque existe.
- Conversation creee automatiquement avec le match.
- Message autorise uniquement dans une conversation issue d un match actif.
- Blocage bidirectionnel : coupe discovery, likes, matchs et messages.
- Signalement persistant : snapshot JSON du compte signale conserve.

## Premium plus tard

Voir `docs/PREMIUM_ARCHITECTURE.md`.

Le schema contient :

- `users.plan_tier`
- `users.premium_expires_at`
- `subscriptions`
- `feature_catalog`
- `user_feature_flags`
- `user_usage_counters`

Ces champs permettent d ajouter sans migration disruptive :

- likes illimites ;
- voir qui a like ;
- filtres avances ;
- routes futures multiples ;
- visibilite multi-zones ;
- verification photo/selfie ;
- evenements ;
- back-office de moderation.

Dans le MVP, ces options restent non exposees : les entrees du catalogue sont
`not_exposed` et `EntitlementService` ne retourne que les features marquees
`active`.
