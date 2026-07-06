# Architecture Premium Ocean Match

Objectif : preparer les options Premium sans les activer dans le MVP et sans
fragiliser la boucle gratuite actuelle : match reciproque puis messagerie texte
gratuite entre matchs.

## Principe

Premium est un systeme de droits, pas une duplication du produit.

Le MVP continue de fonctionner avec :

- inscription, verification email et profil complet ;
- decouverte gratuite selon les regles actuelles ;
- likes, passes et matchs reciproques ;
- conversations et messages texte gratuits entre matchs ;
- blocage et signalement.

Les options futures sont preparees par trois couches :

- catalogue : quelles fonctionnalites existent et quel est leur etat ;
- entitlements : quels utilisateurs auront droit a quoi plus tard ;
- donnees futures : tables inactives pour stocker les options quand elles seront
  exposees par de nouvelles routes.

## Etat MVP

Toutes les options Premium futures sont enregistrees dans `feature_catalog` avec
`mvp_state = 'not_exposed'`.

La classe backend `EntitlementService` ignore volontairement toute feature dont
`feature_catalog.mvp_state` n est pas `active`. Meme si une ligne est ajoutee
dans `user_feature_flags`, elle ne debloque rien tant que le catalogue reste
`not_exposed`.

Aucune route publique n est ajoutee pour :

- voir qui m a like ;
- gerer plusieurs routes futures ;
- gerer plusieurs zones de visibilite ;
- gerer des filtres avances ;
- demander une verification photo ;
- creer ou rejoindre des evenements ;
- utiliser un back-office de moderation.

## Tables ajoutees

Migration : `backend/migrations/002_premium_readiness.sql`.

### Droits et activation

`feature_catalog`

- liste les features connues ;
- separe le groupe fonctionnel, le modele d acces et l etat MVP ;
- garde `mvp_state = 'not_exposed'` tant que la feature n est pas lancee.

`user_feature_flags`

- existait deja ;
- recoit `metadata` et `updated_at` ;
- reference maintenant `feature_catalog`.

`user_usage_counters`

- prepare les futurs quotas ;
- servira notamment a compter les likes si une limite gratuite est introduite ;
- ne change rien aujourd hui : aucun quota payant n est applique dans le MVP.

### Filtres avances

`advanced_discovery_filters`

- stocke les filtres optionnels futurs : statuts de vie a bord, experiences,
  tags de style de vie, langues, profils verifies ;
- pas utilise par `/discovery` dans le MVP ;
- les filtres devront passer par une validation serveur avant activation.

### Routes futures multiples

La table `future_routes` existe deja avec plusieurs lignes possibles, mais le
MVP conserve l index `future_routes_one_active_per_user_idx`, qui impose une
seule route active par utilisateur.

Activation future :

1. passer `multi_future_routes` a `active` dans `feature_catalog` ;
2. ajouter les endpoints de gestion multi-routes ;
3. adapter la decouverte pour lire plusieurs routes actives ;
4. remplacer ou supprimer l index MVP selon la limite produit choisie.

### Visibilite multi-zones

`profile_visibility_zones`

- prepare plusieurs zones publiques de visibilite ;
- chaque zone passe par `is_public_zone_text` ;
- `is_active` reste inutilise par le MVP ;
- `/discovery` continue de lire `current_zones`.

### Verification photo

`photo_verification_requests`

- prepare les demandes de verification selfie/photo ;
- stocke uniquement des references objet externe ;
- ne remplace pas la moderation photo MVP ;
- aucune route de verification n est exposee.

### Evenements

`events` et `event_participants`

- preparent des evenements en zones larges, sans localisation exacte ;
- les evenements commencent en `draft` ;
- aucun endpoint public n existe dans le MVP.

### Back-office moderation

`moderator_accounts`, `moderation_cases`, `moderation_actions`

- preparent des comptes moderateurs, des dossiers et un journal d actions ;
- aucune interface admin n est exposee dans le MVP ;
- les signalements utilisateur restent geres par `reports`.

## Mapping des options futures

```text
likes illimites        -> feature_catalog.unlimited_likes + user_usage_counters
voir qui m a like      -> feature_catalog.see_who_liked_me + likes
filtres avances        -> feature_catalog.advanced_filters + advanced_discovery_filters
plusieurs routes       -> feature_catalog.multi_future_routes + future_routes
visibilite multi-zones -> feature_catalog.multi_zone_visibility + profile_visibility_zones
verification photo     -> feature_catalog.photo_verification + photo_verification_requests
evenements             -> feature_catalog.events + events + event_participants
back-office moderation -> feature_catalog.moderation_backoffice + moderation_*
```

## Regles d activation future

Pour activer une option Premium plus tard :

1. ajouter ou completer les endpoints backend ;
2. verifier le droit via `EntitlementService.isEnabled` ;
3. garder une validation Zod dediee pour chaque payload ;
4. garder les contraintes SQL de zone large pour tout texte public ;
5. passer la feature a `active` dans `feature_catalog` uniquement au moment du
   lancement ;
6. ajouter les ecrans Flutter apres activation backend.

## Garde-fous produit

- La messagerie texte entre matchs reste gratuite et ne doit pas dependre d un
  entitlement Premium.
- Le match reciproque reste le declencheur des conversations.
- Les likes illimites ne doivent pas permettre de contacter sans match.
- Voir qui a like ne doit pas contourner les blocages, comptes suspendus ou
  comptes supprimes.
- Multi-routes et multi-zones restent des zones larges, jamais des positions
  exactes.
- La verification photo est un signal de confiance, pas une obligation MVP.
- Les evenements doivent passer par moderation avant publication.
- Le back-office doit utiliser des comptes moderateurs separes des droits
  Premium utilisateur.
