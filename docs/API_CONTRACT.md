# Contrat API futur

Cette app utilise aujourd hui `OceanMatchRepository`. L API personnalisee est
desormais implementee dans `backend/` et expose les memes capacites.

Voir aussi :

- `docs/BACKEND.md`
- `docs/FLUTTER_API_INTEGRATION.md`
- `docs/PREMIUM_ARCHITECTURE.md`

## Auth

```text
POST /auth/signup
POST /auth/login
POST /auth/refresh
POST /auth/logout
POST /auth/verify-email
POST /auth/resend-verification
POST /auth/password-reset
POST /auth/password-reset/confirm
DELETE /account
```

Regles :

- access token court ;
- refresh token revocable ;
- mot de passe hashe cote serveur ;
- aucun acces decouverte sans email verifie.

## Profil

```text
GET /me
PUT /profile
PUT /life-aboard
PUT /current-zone
PUT /future-route
PUT /preferences
```

Regles :

- une seule route future active dans le MVP ;
- zone actuelle large uniquement ;
- port exact et coordonnees GPS jamais visibles publiquement.

## Photos

```text
POST /photos/upload-url
POST /photos
PATCH /photos/:id
DELETE /photos/:id
```

Regles :

- stockage objet, pas en base PostgreSQL ;
- URL signee ou acces controle ;
- minimum 2 photos pour publier le profil ;
- une seule photo principale.

## Decouverte

```text
GET /discovery
POST /passes
POST /likes
```

Regles :

- exclure comptes supprimes, suspendus, incomplets ;
- exclure profils deja likes, passes recemment ou bloques ;
- classer simplement par zone, route, intentions, age, genre et style de vie.

## Matchs et messages

```text
GET /matches
GET /conversations
GET /conversations/:id/messages
POST /conversations/:id/messages
```

Regles :

- match uniquement sur like reciproque ;
- conversation creee automatiquement avec le match ;
- message texte gratuit entre matchs, sans droit Premium ;
- aucun message sans match actif ;
- aucun message apres blocage.

## Securite

```text
GET /blocks
POST /blocks
DELETE /blocks/:id
POST /reports
```

Regles :

- un blocage coupe decouverte, like, match et message dans les deux sens ;
- un signalement conserve motif, commentaire facultatif, conversation/message lie si applicable ;
- les signalements restent exploitables meme si un compte est supprime.

## Premium futur

Aucune route Premium n est exposee dans le MVP.

Les futures options sont preparees par :

```text
feature_catalog
user_feature_flags
user_usage_counters
advanced_discovery_filters
profile_visibility_zones
photo_verification_requests
events
event_participants
moderation_cases
moderation_actions
```

Regles :

- une feature doit etre `active` dans `feature_catalog` et presente dans les
  droits utilisateur pour etre exploitable ;
- les features Premium restent `not_exposed` dans le MVP ;
- la messagerie texte entre matchs reste gratuite ;
- les futures routes et zones multiples restent des zones larges, jamais des
  positions exactes.
