# BlueWater Match MVP

Application Flutter iOS/Android pour tester le concept BlueWater Match : une app de rencontre pour personnes vivant, naviguant ou projetant de vivre en bateau.

## Statut

Le workspace contient le code source Flutter du MVP avec une architecture propre.
Par defaut, l app utilise maintenant l API REST pour sauvegarder les
inscriptions, connexions, verifications email et publications de profil dans
PostgreSQL. Le repository mock reste disponible pour les tests et les parcours
demo.

Pour lancer localement apres installation Flutter :

```bash
flutter pub get
flutter run --dart-define=OCEAN_MATCH_API_URL=http://localhost:8080/v1
```

Sur emulateur Android, utilisez plutot :

```bash
flutter run --dart-define=OCEAN_MATCH_API_URL=http://10.0.2.2:8080/v1
```

Pour revenir au mock en developpement :

```bash
flutter run --dart-define=OCEAN_MATCH_USE_MOCK_REPOSITORY=true
```

Le backend doit etre lance et migre pour que les nouvelles inscriptions soient
persistantes. Voir `docs/BACKEND.md`.

## Compte test

Le repository mock cree un compte complet et actif au demarrage :

```text
Email: test@oceanmatch.app
Mot de passe: password-demo
```

Le mock accepte aussi `password123` pour ce compte test.

Ce compte arrive directement sur Decouvrir. Avec l API reelle, creez ou migrez
les comptes en base avant de vous connecter.

## Parcours MVP inclus

- Inscription email / mot de passe.
- Verification email simulee.
- Connexion, deconnexion, mot de passe oublie simule.
- Onboarding profil complet.
- Photos depuis la galerie mobile via `image_picker` ou photos demo.
- Vie a bord, zone actuelle sans position exacte, route future, intentions.
- Decouverte de profils compatibles.
- Likes, passes, match sur like reciproque.
- Conversation texte gratuite entre matchs.
- Blocage, signalement, profils bloques.
- Suppression de compte.
- Parametres et rappels de confidentialite.

## Architecture

```text
lib/
  main.dart
  src/
    app.dart
    application/
      ocean_match_controller.dart
    core/
      app_theme.dart
      id_generator.dart
    data/
      ocean_match_repository.dart
    domain/
      models.dart
    presentation/
      screens/
      widgets/
```

Le controller expose les cas d usage a l UI. L implementation API persiste les
donnees serveur et le repository mock applique les regles critiques pendant les
tests :

- pas de decouverte sans email verifie et profil complet ;
- pas de position exacte affichee ;
- pas de message sans match actif ;
- pas d interaction si blocage dans un sens ou l autre ;
- match uniquement apres like reciproque ;
- signalements conserves ;
- compte supprime invisible.

## Backend

Un socle backend personnalise est disponible dans `backend/` :

- API REST Node/TypeScript ;
- PostgreSQL via `backend/migrations/001_init.sql` ;
- auth JWT + refresh tokens revocables ;
- validation serveur Zod ;
- stockage photo externe prepare ;
- schema pret pour Premium.

L app Flutter branche `ApiOceanMatchRepository` par defaut via
`createDefaultOceanMatchRepository()`. Les tests injectent explicitement
`MockOceanMatchRepository`.

Voir `docs/ARCHITECTURE.md` et `docs/API_CONTRACT.md`.

Voir aussi `docs/BACKEND.md` et `docs/FLUTTER_API_INTEGRATION.md`.

## Premium plus tard

Le MVP garde hors scope et non expose :

- likes illimites ;
- voir qui m a like ;
- filtres avances ;
- routes futures multiples ;
- visibilite multi-zones ;
- verification photo/selfie ;
- evenements et escales ;
- back-office complet de moderation.

La preparation technique est documentee dans `docs/PREMIUM_ARCHITECTURE.md` et
repose sur un catalogue de features, des droits utilisateur et des tables
inactives pour les futures surfaces. La messagerie texte entre matchs reste
gratuite.
