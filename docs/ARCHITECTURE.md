# Architecture technique MVP Ocean Match

## Objectif

Livrer une app Flutter simple, testable et evolutive, avec une separation claire entre UI, etat applicatif, domaine et acces donnees.

## Couches

### Presentation

Responsabilites :

- afficher les ecrans ;
- collecter les saisies utilisateur ;
- appeler le controller ;
- montrer erreurs, confirmations, dialogues de securite.

Fichiers :

- `lib/src/presentation/screens/*`
- `lib/src/presentation/widgets/*`

### Application

Responsabilites :

- orchestration des cas d usage ;
- etat de session ;
- rafraichissement decouverte, conversations, messages ;
- notification de l UI via `ChangeNotifier`.

Fichier :

- `lib/src/application/ocean_match_controller.dart`

### Domaine

Responsabilites :

- modeles metier ;
- enums et libelles ;
- objets composes pour decouverte et conversations.

Fichier :

- `lib/src/domain/models.dart`

### Data

Responsabilites :

- contrat `OceanMatchRepository` ;
- implementation mock pour le MVP local ;
- emplacement futur de l implementation API.

Fichier :

- `lib/src/data/ocean_match_repository.dart`

## Remplacement du mock par une API

Le point de remplacement est dans `lib/src/app.dart` :

```dart
_controller = OceanMatchController(
  repository: MockOceanMatchRepository(),
);
```

Future :

```dart
_controller = OceanMatchController(
  repository: ApiOceanMatchRepository(apiClient: apiClient),
);
```

## Regles de securite appliquees cote data

- Compte non verifie : pas de decouverte.
- Profil incomplet : pas de decouverte.
- Profil bloque : invisible et impossible a contacter.
- Message : autorise seulement dans une conversation issue d un match actif.
- Match : cree uniquement apres like reciproque.
- Suppression : retire le profil, les photos et les interactions futures.
- Localisation : seulement zones larges, aucune coordonnee GPS publique.

## Evolution Premium

Prevoir plus tard une table ou endpoint `subscriptions` et des feature flags :

- `unlimited_likes`
- `see_who_liked_me`
- `advanced_filters`
- `multi_routes`
- `multi_zone_visibility`
- `photo_verification`

Ces options ne doivent pas changer la boucle gratuite du MVP : match + message texte gratuit.
