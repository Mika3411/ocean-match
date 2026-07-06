# Checklist de preparation MVP

## Tests manuels critiques

- Creer un compte avec email et mot de passe.
- Verifier l email.
- Completer toutes les etapes onboarding.
- Ajouter 2 photos depuis galerie ou photos demo.
- Verifier que Decouvrir affiche seulement des zones larges.
- Passer un profil.
- Liker un profil.
- Obtenir un match avec le profil demo Lea.
- Ouvrir Messages.
- Envoyer un message texte.
- Bloquer un match.
- Verifier que le match bloque ne peut plus recevoir de message.
- Signaler un profil depuis le detail.
- Signaler depuis une conversation.
- Supprimer le compte.
- Verifier que l utilisateur revient a l accueil.

## Tests techniques API a ajouter

- Contrainte de like unique.
- Contrainte de match unique par paire utilisateur.
- Aucun message sans match actif.
- Aucun message si blocage dans un sens.
- Aucun profil bloque dans Decouvrir.
- Aucun compte supprime dans Decouvrir.
- Suppression ou invalidation des photos apres suppression compte.
- Signalement conserve meme si blocage ou suppression.

## Avant beta

- Brancher `ApiOceanMatchRepository`.
- Ajouter stockage objet avec URL signees.
- Ajouter vraie verification email.
- Ajouter vraie recuperation mot de passe.
- Ajouter migrations PostgreSQL.
- Ajouter monitoring erreurs.
- Ajouter CGU et politique de confidentialite.
- Ajouter politique de moderation minimale.
- Tester iOS et Android sur vrais appareils.
