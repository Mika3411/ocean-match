# Integration Flutter avec l API BlueWater Match

L app Flutter utilise `OceanMatchRepository`. Le branchement par defaut passe
par `ApiOceanMatchRepository` dans `lib/src/data/api_ocean_match_repository.dart`
pour sauvegarder dans l API :

- inscription, connexion, verification email et renvoi de verification ;
- demande de reinitialisation de mot de passe ;
- publication d onboarding (`profile`, `life-aboard`, `current-zone`,
  `future-route`, `preferences`) ;
- mise a jour des zones/routes principales ;
- suppression de compte.

Les autres surfaces du MVP continuent d utiliser le socle mock local tant que
leurs endpoints ne sont pas tous branches dans Flutter.

## Configuration

Configuration d environnement cote Flutter :

```dart
const apiBaseUrl = String.fromEnvironment(
  'OCEAN_MATCH_API_URL',
  defaultValue: 'http://localhost:8080/v1',
);
```

Si `OCEAN_MATCH_API_URL` n est pas fourni, l app utilise `http://localhost:8080/v1`,
ou `http://10.0.2.2:8080/v1` sur emulateur Android.

Lancement web ou desktop local :

```bash
flutter run --dart-define=OCEAN_MATCH_API_URL=http://localhost:8080/v1
```

Sur emulateur Android, utiliser plutot `http://10.0.2.2:8080/v1`.

Pour forcer le repository mock :

```bash
flutter run --dart-define=OCEAN_MATCH_USE_MOCK_REPOSITORY=true
```

## Auth et stockage des tokens

Responses auth :

```json
{
  "user": {
    "id": "uuid",
    "email": "lea@example.com",
    "emailVerified": true,
    "status": "active",
    "planTier": "free"
  },
  "tokens": {
    "accessToken": "jwt",
    "refreshToken": "opaque",
    "tokenType": "Bearer",
    "expiresInSeconds": 900
  }
}
```

Etat actuel :

- les access/refresh tokens sont conserves en memoire ;
- l access token est envoye sur les routes protegees deja branchees ;
- si l API retourne `401`, le repository tente `POST /auth/refresh`, puis
  rejoue la requete.

Recommandations restantes avant production :

- stocker `refreshToken` dans `flutter_secure_storage` ;
- garder `accessToken` en memoire ou stockage securise court ;
- appeler `POST /auth/logout` avec le refresh token lors de la deconnexion.

## Mapping repository

Correspondance directe avec `OceanMatchRepository` :

```text
signUp                  -> POST /auth/signup
login                   -> POST /auth/login
verifyEmail             -> POST /auth/verify-email
requestEmailVerification -> POST /auth/resend-verification
requestPasswordReset    -> POST /auth/password-reset
deleteAccount           -> DELETE /account

completeOnboarding      -> PUT /profile, POST /photos, PUT /life-aboard,
                            PUT /current-zone, PUT /future-route, PUT /preferences
updateCurrentZone       -> PUT /current-zone
updateFutureRoute       -> PUT /future-route
getPortActivities       -> GET /ports
getDiscoveryProfiles    -> GET /discovery
likeProfile             -> POST /likes
passProfile             -> POST /passes
getConversationSummaries -> GET /conversations
getMessages             -> GET /conversations/:id/messages
sendMessage             -> POST /conversations/:id/messages
blockUser               -> POST /blocks
unblockUser             -> DELETE /blocks/:id
getBlocks               -> GET /blocks
reportUser              -> POST /reports
```

## Enums API

L API utilise des valeurs `snake_case`. Il faut les mapper vers les enums Dart :

```text
Gender.nonBinary             <-> non_binary
BoardStatus.longDistanceSailor <-> long_distance_sailor
BoardStatus.futureLiveaboard <-> future_liveaboard
RouteFlexibility.veryFlexible <-> very_flexible
Intention.seriousRelationship <-> serious_relationship
Intention.casualDating       <-> casual_dating
Intention.sailingProject     <-> sailing_project
Intention.liveaboardProject  <-> liveaboard_project
ReportReason.fakeProfile     <-> fake_profile
ReportReason.inappropriateContent <-> inappropriate_content
ReportReason.suspiciousBehavior   <-> suspicious_behavior
ReportStatus.newReport       <-> new_report
```

## Flux photo

1. `POST /photos/upload-url` avec `contentType` et `fileSizeBytes`.
2. Upload direct du fichier vers `uploadUrl` avec les headers retournes. En
   local, le driver `mock` accepte ce `PUT` sur l API elle-meme.
3. `POST /photos` avec `storageBucket`, `storageKey`, `contentType`,
   `sizeBytes`, `isPrimary` et `order`.

Exemple :

```json
{
  "contentType": "image/jpeg",
  "fileSizeBytes": 734003
}
```

La reponse contient :

```json
{
  "storageBucket": "ocean-match-photos",
  "storageKey": "users/<userId>/2026-07-06/<uuid>.jpg",
  "uploadUrl": "https://...",
  "expiresAt": "2026-07-06T12:15:00.000Z",
  "headers": {
    "content-type": "image/jpeg"
  }
}
```

## Payloads principaux

`PUT /profile` :

```json
{
  "firstName": "Lea",
  "birthDate": "1992-05-12",
  "gender": "woman",
  "searchGender": "everyone",
  "languages": ["Francais", "Anglais"],
  "bio": "Vie a bord entre Canaries et Cap-Vert."
}
```

`PUT /life-aboard` :

```json
{
  "status": "liveaboard",
  "boatOrProject": "Voilier 36 pieds",
  "sailingType": "Hauturier tranquille",
  "experience": "confirmed",
  "lifestyleTags": ["minimaliste", "escales calmes"]
}
```

`PUT /current-zone` :

```json
{
  "zone": "Canaries",
  "country": "Espagne",
  "portId": "las-palmas"
}
```

`PUT /future-route` :

```json
{
  "destinationZone": "Caraibes",
  "destinationPortId": "le-marin",
  "startPeriod": "Hiver",
  "endPeriod": "Printemps",
  "flexibility": "flexible",
  "comment": ""
}
```

`GET /ports` :

```json
{
  "ports": [
    {
      "port": {
        "id": "las-palmas",
        "name": "Las Palmas",
        "country": "Espagne",
        "region": "Canaries",
        "latitude": 28.1235,
        "longitude": -15.4363
      },
      "currentCount": 12,
      "destinationCount": 8,
      "isCurrentUserHere": true,
      "isCurrentUserGoing": false
    }
  ]
}
```

`PUT /preferences` :

```json
{
  "ageMin": 28,
  "ageMax": 45,
  "genderTargets": "everyone",
  "zones": ["Canaries", "Caraibes"],
  "intentions": ["serious_relationship", "sailing_project"]
}
```

## Erreurs

Format standard :

```json
{
  "error": {
    "code": "validation_failed",
    "message": "Validation serveur echouee.",
    "details": {}
  }
}
```

Codes a gerer cote Flutter :

- `401` : access token absent, invalide ou expire ;
- `403` : email non verifie, compte suspendu, interaction bloquee ;
- `409` : ressource deja existante ;
- `422` : validation serveur ou contrainte securite ;
- `500` : erreur serveur.
