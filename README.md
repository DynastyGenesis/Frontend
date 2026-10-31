# BarelGo — application Flutter

Application pour les expéditions des États-Unis vers le Togo. Le parcours actif démarre sur l’accueil public, puis donne accès aux espaces client et livreur.

## Configuration

L’application exige un backend : sans les trois valeurs suivantes, fournies à la compilation, elle n’affiche qu’une page « Configuration du backend manquante ». Il n’existe plus de mode de démonstration locale.

```sh
flutter run \
  --dart-define=API_BASE_URL=https://VOTRE-API/api/v1 \
  --dart-define=SUPABASE_URL=https://VOTRE-PROJET.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx
```

Plus simple : copier `config/env.example.json` en `config/env.json` (ignoré par git), le remplir, puis lancer `flutter run --dart-define-from-file=config/env.json`. Les profils de `.vscode/launch.json` font de même. Voir [config/README.md](config/README.md).

Valeurs facultatives :

- `STRIPE_PUBLISHABLE_KEY` (`pk_...`) : active le paiement par carte sur Android et iOS. Sans elle, le bouton « Payer » reste masqué.
- `FIREBASE_API_KEY`, `FIREBASE_ANDROID_APP_ID`, `FIREBASE_IOS_APP_ID`, `FIREBASE_WEB_APP_ID`, `FIREBASE_SENDER_ID`, `FIREBASE_PROJECT_ID`, `FIREBASE_VAPID_KEY` : activent les notifications push. Sans elles, pas de push.

Le mode backend utilise Supabase pour l’authentification et l’API Laravel pour les opérations prises en charge. Seules des clés publiques sont utilisées dans l’application ; ne jamais y intégrer de clé secrète (Supabase `sb_secret_...`, Stripe `sk_...`, compte de service Firebase).

## Parcours disponibles

- **Public** : présentation des services et du fonctionnement, accès client et livreur.

- **Client** : inscription, connexion, mot de passe oublié, carnet « Mes destinataires » (sur l’appareil), réservations (création, liste, détail, modification tant qu’elles sont en attente, annulation, réponse à un report), colis et suivi, documents, litiges, notifications, compte, paiement par carte (si la clé Stripe est fournie, Android et iOS), grille de tarifs et tirage au sort.
- **Livreur** : missions (accepter, refuser, confirmer la collecte, proposer un autre créneau), disponibilité et envoi de la position GPS toutes les 30 s pendant l’écran des missions, estimation du trajet, déclaration de l’arrivée d’un colis par son numéro, commissions, notifications, tirage au sort et profil.
- **Notifications push** : le jeton de l’appareil est enregistré après la connexion, si Firebase est configuré.

L’historique des missions terminées n’est pas fourni par l’API. Aucune page administrateur n’est incluse : les routes `/admin/*` du backend n’ont pas d’écran dans l’application.

## Données et limites

Le jeton de session est conservé dans le stockage sécurisé du système (Keystore Android, Keychain iOS). Le carnet « Mes destinataires » est le seul stockage local : un fichier par compte (répertoire de support applicatif) ou le stockage du navigateur ; l’effacer supprime le carnet.

Le backend ne couvre pas encore tous les besoins des écrans : les informations de colis et de destinataire sont incomplètes, les étapes de transport international et de douane restent à définir, et l’historique des missions terminées n’est pas exposé. Les détails et décisions ouvertes sont décrits dans [RACCORDEMENT_BACKEND.md](RACCORDEMENT_BACKEND.md).

## Organisation

- `lib/main.dart` et `lib/app/` : initialisation et composition de l’application.
- `lib/core/` : configuration, règles métier frontend et correspondance des statuts.
- `lib/data/api/`, `lib/data/auth/`, `lib/data/services/` : client HTTP, authentification (dont `secure_session_store.dart`) et accès à l’API.
- `lib/data/app_services.dart` : point d’entrée qui fournit l’API, l’authentification, le paiement Stripe, le GPS et les notifications push.
- `lib/data/local/` : stockage local natif et web.
- `lib/presentation/pages/` : accueil public et espaces client/livreur.
- `lib/features/` : écrans et contrôleurs backend ; les raccordements client et livreur sont centralisés dans `client_flow.dart` et `driver_flow.dart` (détail dans [lib/features/README.md](lib/features/README.md)).
- `config/` : modèle de configuration de lancement (`env.example.json`).
- `test/` : tests unitaires, contrôleurs et parcours frontend.
- `.github/workflows/frontend.yml` : analyse, tests et compilation web sur push et pull request.

Le nom interne `barrel_go` est conservé pour la compatibilité des imports et scripts.

## Développement et validation

Prérequis : Flutter 3.47.1 ou compatible avec la contrainte Dart du projet. Pour Android : JDK 17 ou plus et le SDK Android.

```sh
flutter pub get
flutter analyze
flutter test --concurrency=1
flutter build web --release
```

Pour lancer l’application en mode web :

```sh
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

Au 29 octobre 2026 : 111 tests réussis, `flutter analyze` sans message, compilation web réussie. La compilation Android (`flutter build apk --debug`) n’a pas pu être confirmée dans cet environnement ; elle est à lancer localement après l’ajout de Stripe, Firebase et geolocator. Le fonctionnement de bout en bout contre un vrai Supabase, Laravel et Stripe n’a pas encore été vérifié.

Le workflow GitHub Actions exécute l’analyse, les tests et la compilation web. Les tests et builds locaux restent à lancer après toute modification.

## Avant la mise en production

Vérifier le fonctionnement de bout en bout avec une configuration de test, puis :

- **Web** : le paiement par carte n’y existe pas ; les notifications web demandent `web/firebase-messaging-sw.js`.
- **iOS** : activer les notifications dans Xcode et déposer la clé APNs dans la console Firebase.
- **Déconnexion** : le backend n’a pas de route pour retirer un jeton push, il reste enregistré.
- **Règles métier à définir** : destinataires sans compte, informations de colis (type, description, adresse au Togo, photo), transport international et douane. Ces points demandent des changements du backend.

Les identifiants de production, signatures, textes juridiques et coordonnées officielles doivent également être définis.