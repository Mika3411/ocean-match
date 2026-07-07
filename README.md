# BlueWater Match MVP

Application Flutter iOS/Android pour tester le concept BlueWater Match : une app de rencontre pour personnes vivant, naviguant ou projetant de vivre en bateau.

## Statut

Le workspace contient le code source Flutter du MVP avec une architecture propre et un repository mock en memoire. Le SDK Flutter n est pas installe sur cette machine, donc les dossiers natifs `ios/` et `android/` n ont pas ete generes ici.

Pour lancer localement apres installation Flutter :

```bash
flutter create .
flutter pub get
flutter run
```

`flutter create .` ajoute les projets natifs iOS/Android sans ecraser `lib/` ni `pubspec.yaml` si vous refusez les conflits eventuels.

## Compte test

Le repository mock cree un compte complet et actif au demarrage :

```text
Email: test@oceanmatch.app
Mot de passe: password-demo
```

Le mock accepte aussi `password123` pour ce compte test.

Ce compte arrive directement sur Decouvrir.

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

Le controller expose les cas d usage a l UI. Le repository mock applique deja les regles serveur critiques :

- pas de decouverte sans email verifie et profil complet ;
- pas de position exacte affichee ;
- pas de message sans match actif ;
- pas d interaction si blocage dans un sens ou l autre ;
- match uniquement apres like reciproque ;
- signalements conserves ;
- compte supprime invisible.

## Backend futur

Un socle backend personnalise est maintenant disponible dans `backend/` :

- API REST Node/TypeScript ;
- PostgreSQL via `backend/migrations/001_init.sql` ;
- auth JWT + refresh tokens revocables ;
- validation serveur Zod ;
- stockage photo externe prepare ;
- schema pret pour Premium.

Remplacer `MockOceanMatchRepository` par une implementation API dans `lib/src/data/`, en gardant l interface `OceanMatchRepository`.

Exemples futurs :

- `ApiOceanMatchRepository`
- `AuthApiClient`
- `ProfilesApiClient`
- `MessagingApiClient`
- `PhotoStorageClient`

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
