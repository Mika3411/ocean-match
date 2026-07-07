# Deployer Ocean Match sur Render

Le fichier `render.yaml` cree maintenant toute la pile MVP :

- `ocean-match-mvp` : le site Flutter Web.
- `ocean-match-api` : l API Node/TypeScript.
- `ocean-match-db` : la base PostgreSQL.

## Etapes Render

1. Pousse ce projet sur GitHub, GitLab ou Bitbucket.
2. Ouvre Render.
3. Clique sur **New +**.
4. Choisis **Blueprint**.
5. Selectionne le repository Ocean Match.
6. Render lit `render.yaml`.
7. Clique sur **Apply**.

Render va ensuite creer le site, l API et la base.

## Variables

Tu n as normalement rien a remplir a la main pour le MVP.

Le Blueprint configure automatiquement :

- `DATABASE_URL` depuis `ocean-match-db`.
- `API_PUBLIC_BASE_URL` depuis l URL publique de `ocean-match-api`.
- `CORS_ORIGINS` depuis l URL publique de `ocean-match-mvp`.
- `OCEAN_MATCH_API_ORIGIN` cote frontend, transforme en `OCEAN_MATCH_API_URL=.../v1` pendant le build Flutter.
- `JWT_ACCESS_SECRET` et `JWT_REFRESH_SECRET` avec des secrets generes par Render.
- `NODE_ENV=production`.
- `MIN_PROFILE_PHOTOS=0` tant que l app Flutter n a pas encore l upload photo complet.
- `PHOTO_STORAGE_DRIVER=mock`.

## Point important sur la base

La base est configuree en `basic-256mb`, pas en `free`.

Pourquoi : une base PostgreSQL gratuite Render expire au bout de 30 jours. Pour de vrais comptes et de vrais messages, il faut une base qui reste en place.

## Plus tard : vraies photos

Le MVP peut fonctionner sans upload photo complet. Quand tu voudras stocker de vraies photos, il faudra passer `PHOTO_STORAGE_DRIVER` a `s3` et ajouter :

```env
S3_REGION=auto
S3_ENDPOINT=<endpoint S3 ou Cloudflare R2>
S3_ACCESS_KEY_ID=<access key>
S3_SECRET_ACCESS_KEY=<secret key>
PHOTO_PUBLIC_BASE_URL=<url publique du bucket ou CDN>
```

Il faudra aussi remettre `MIN_PROFILE_PHOTOS=2` quand l upload photo sera disponible cote Flutter.
