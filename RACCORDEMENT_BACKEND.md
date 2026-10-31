# Raccordement au backend — état au 28 octobre 2026

Le design n'a pas changé. Sans configuration, l'application n'affiche qu'une page « Configuration du backend manquante » : le mode de démonstration locale a été supprimé le 31 octobre 2026.

## Activer le mode réel

Les trois valeurs sont fournies à la compilation :

```text
flutter run \
  --dart-define=API_BASE_URL=https://VOTRE-API/api/v1 \
  --dart-define=SUPABASE_URL=https://VOTRE-PROJET.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx
```

Facultatif : `STRIPE_PUBLISHABLE_KEY` (paiement par carte, Android et iOS) et les `FIREBASE_*`
(notifications push). Tout peut être mis dans `config/env.json` (modèle : `config/env.example.json`)
puis lancé avec `flutter run --dart-define-from-file=config/env.json`, ou avec les profils de `.vscode/launch.json`.

Seule la clé publique (publishable) est utilisée. Aucune clé secrète ne doit entrer dans l'application. Si une des trois valeurs manque, l'application ne démarre pas au-delà de la page de configuration.

## Ce qui est fait

| Étape | Fichiers |
|---|---|
| 1. Configuration et client HTTP (jeton, erreurs en français, pagination, renouvellement du jeton sur 401) | `lib/core/app_config.dart`, `lib/data/api/` |
| 2. Authentification Supabase (inscription, connexion, mot de passe oublié, déconnexion, renouvellement) | `lib/data/auth/`, `lib/data/app_services.dart`, `lib/presentation/pages/client_space/ships_login_page.dart` |
| 3. Modèles typés et correspondance des statuts | `lib/data/models/api_models.dart`, `lib/core/status_mapping.dart` |
| 4. (partiel) Passerelle API et écrans client/livreur raccordés : réservations, colis, suivi, documents, litiges, notifications, missions et commissions | `lib/data/services/backend_api.dart`, `lib/features/client_flow.dart`, `lib/features/driver_flow.dart` |
| 6. Tests | `test/` : les 6 fichiers du 12 octobre remis en place + `api_client_test`, `auth_service_test`, `backend_api_test`, `status_mapping_test` |

Changements dans les écrans existants, en mode réel seulement :
- Connexion : l'inscription et la connexion passent par Supabase. Le texte de l'encadré bleu et le libellé du bouton d'inscription changent ; la mise en page est identique.
- Un livreur qui se connecte pour la première fois choisit son véhicule (moto, tricycle, camionnette) dans une petite fenêtre, car le backend l'exige.
- « Se déconnecter » ferme aussi la session Supabase.
- « Mot de passe oublié ? » envoie un vrai e-mail de réinitialisation.

## Validation frontend au 28 octobre 2026

- `flutter test --concurrency=1` : 83 tests réussis.
- `flutter build web --release` : compilation réussie.
- `flutter analyze` : aucune erreur bloquante ; six informations de style/dépréciation subsistent dans les écrans de réservation et paiement.

Ces contrôles utilisent les tests et un build local. Le fonctionnement de bout en bout contre une instance réelle de Supabase, Laravel ou Stripe reste à vérifier avec une configuration de test dédiée.

## Ce qui reste à intégrer et les décisions à prendre

En mode backend, les menus client et livreur utilisent les écrans raccordés. Les limites fonctionnelles restantes sont :

1. **Destinataire.** Le backend exige `recipient_user_id` : le destinataire doit avoir un compte. Décision prise côté frontend (le backend ne change pas) : l'expéditeur saisit le code du destinataire, lu dans « Mon compte ». Un code inconnu est signalé colis par colis et peut être corrigé sans recréer la réservation.
2. **Informations de colis.** Le backend ne stocke ni type de colis, ni description, ni adresse du destinataire au Togo, ni photo. Décision prise côté frontend : le parcours réel ne demande que destinataire, poids et dépôt par le client.
3. **Paiement.** Le portefeuille (solde, recharge, retrait) n'a pas d'équivalent. Le backend fait un paiement Stripe par réservation, avec un payeur désigné. Le SDK Stripe est branché (Android et iOS) : le bouton « Payer » apparaît quand `STRIPE_PUBLISHABLE_KEY` est fournie. Il reste masqué sur le web.
4. **Étapes « En livraison » et douane.** Pas d'équivalent exact dans le backend.
5. **Push et GPS.** Branchés : Firebase Messaging (jeton enregistré après la connexion, si les `FIREBASE_*` sont fournies) et `geolocator` (disponibilité, position toutes les 30 s, trajet, confirmation de collecte). À faire : `web/firebase-messaging-sw.js` pour le push web, clé APNs côté iOS, pas de désinscription du jeton à la déconnexion (le backend n'a pas de route).
6. **Jeton.** Stocké dans le stockage sécurisé du système (Keystore / Keychain). L'ancienne session en clair est reprise puis effacée.

## Retiré du frontend (sans équivalent dans le backend)

Code supprimé le 26 octobre 2026, à la demande de Wisdom. À recréer seulement quand une route backend existera.

- **Espace client** : portefeuille (solde, recharge, retrait, historique), moyens de paiement et leurs paramètres, Aide & Support (tickets), page Paramètres (devise, fuseau, langue, 2FA, mot de passe, adresses, photo, suppression de compte), documents d'exemple (factures, pièce d'identité, PDF de démonstration), boutons « Voir la facture », « Contacter le transporteur » et « Signaler un problème ».
- **Espace livreur** : signalement d'incident, revenus fictifs et relevé CSV, Aide & Support, zone Togo/États-Unis modifiable, modification du profil (téléphone, véhicule).
- **Accueil public** : formulaire de contact.
- **Gardé** : compte (nom et e-mail issus de Supabase), réservations, colis et suivi, notifications, missions et historique du livreur.
- **Ajouté le 29 octobre 2026** : « Tarifs » (grille publique, menu client) et « Tirage au sort » (tirage du mois et historique, menus client et livreur) ; « Modifier la réservation » (client) et « Arrivée d'un colis » (livreur).
- **Volontairement absent** : toute page administrateur (litiges, livreurs, agents, réglages, transactions, tirage). Les routes `/admin/*` existent côté backend, sans écran dans l'application.

Le signalement et la liste des litiges sont maintenant accessibles depuis le détail d’un colis et le menu client ; le traitement administratif reste réservé au backend/admin.

Code de démonstration locale, ancienne coque `legacy`, assets et dépendances inutilisés : supprimés le 31 octobre 2026.

## Écrans et contrôleurs

`lib/features/` contient les écrans et contrôleurs raccordés décrits dans `lib/features/README.md`. `test/features_controllers_test.dart` couvre leurs contrôleurs ; `test/client_flow_test.dart` couvre l’aiguillage des pages.
