# Ocean Match Backend

API REST personnalisee pour Ocean Match, avec PostgreSQL, validation serveur,
auth par access token court et refresh token revocable, stockage photo externe
prepare et architecture compatible Premium.

## Lancement local

```bash
cd backend
cp .env.example .env
docker compose up -d postgres
npm install
npm run migrate
npm run dev
```

L API ecoute par defaut sur `http://localhost:8080`.

## Scripts

- `npm run dev` : demarre l API en watch mode.
- `npm run build` : compile TypeScript vers `dist/`.
- `npm start` : lance la version compilee.
- `npm run migrate` : applique les migrations SQL dans l ordre via Node/pg.

## Organisation

```text
backend/
  migrations/
    001_init.sql
  src/
    config/
    db/
    middleware/
    routes/
    security/
    services/
    storage/
    validation/
```

Les routes sont fines. Les regles sensibles vivent dans les services :

- `AuthService` : signup, login, refresh, verification email, reset password, suppression.
- `ProfileService` : profil, vie a bord, zones, route future, preferences, photos.
- `DiscoveryService` : filtrage decouverte sans position exacte.
- `SocialService` : likes, passes, blocages, signalements.
- `MessagingService` : matchs, conversations, messages.

## Stockage photos

Le backend ne stocke pas les images dans PostgreSQL. La table `profile_photos`
ne conserve que les metadonnees : bucket, cle objet, URL publique optionnelle,
statut de moderation et ordre.

En local, `PHOTO_STORAGE_DRIVER=mock` retourne une URL locale
`PUT /mock-photo-upload/:key` pour integrer le flux Flutter sans S3. En
production, `PHOTO_STORAGE_DRIVER=s3` genere une URL signee compatible S3, R2
ou MinIO.

## Securite

- Toutes les routes `/v1/*`, sauf `/v1/auth/*`, exigent `Authorization: Bearer`.
- Les refresh tokens sont opaques, hashes en base et revocables.
- Les mots de passe sont hashes avec bcrypt.
- Les payloads sont valides par Zod avant toute ecriture.
- Les contraintes PostgreSQL rejettent les coordonnees et indices de position
  precise sur les champs publics.
- Un blocage coupe decouverte, like, match et message dans les deux sens.
- Les signalements conservent un snapshot du compte signale.

## Premium futur

La migration `migrations/002_premium_readiness.sql` prepare les options Premium
sans les exposer dans le MVP :

- catalogue `feature_catalog` ;
- droits `user_feature_flags` ;
- compteurs `user_usage_counters` ;
- filtres avances, zones de visibilite, verification photo, evenements ;
- dossiers et actions de moderation.

Les features restent `not_exposed` tant qu elles ne sont pas lancees. La
messagerie texte entre matchs reste gratuite.
