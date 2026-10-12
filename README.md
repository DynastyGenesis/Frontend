# barrelGo — Application Flutter

Application mobile client séparée de l'espace transporteur.

## Architecture

- `lib/main.dart` : point d'entrée uniquement
- `lib/app/` : composition de l'application et shell de navigation
- `lib/core/theme/` : thème et couleurs
- `lib/data/models/` : modèles métier
- `lib/data/services/` : accès aux données / futurs appels API
- `lib/presentation/pages/` : écrans métier
- `lib/presentation/widgets/` : composants réutilisables
- `test/` : tests widget
- `assets/` : ressources locales

## Écrans

Accueil, suivi, devis, mes envois, profil. Le parcours d’expédition est centré
sur le corridor Togo ↔ États-Unis, avec les deux sens disponibles dans le
formulaire de devis.

L’entrée « Espace client » ouvre les écrans frontend de connexion, de création
de compte et de récupération de mot de passe, et permet également de consulter
directement le tableau de bord en mode invité, sans créer de compte.
Le tableau de bord distingue le client expéditeur (réservation de pickup,
paiement intégral à la collecte et suivi) du destinataire au Togo (suivi de
l’arrivée, notifications facultatives et confirmation de réception). Les
écrans existants de devis, suivi, envois et profil restent accessibles. Tous
les comptes, pickups, notifications et statuts sont simulés localement : aucun
backend, paiement, stockage de compte ni envoi d’e-mail n’est configuré.

La communication sur les destinations présente l’Afrique et les États-Unis,
avec les opérations de réservation ciblées sur le Togo.

## Identité visuelle

Le thème mobile reprend les couleurs et la typographie de la référence du site,
adaptées à l’identité barrelGo :
rose `#F8979C`, bleu marine `#12375C`, Open Sans pour le corps et Poppins pour
les titres, toutes deux embarquées dans `assets/fonts/`. Les visuels de la page
d’accueil sont conservés dans `assets/images/`.

L’accueil reprend les sections de présentation, les transporteurs, la douane
électronique, les étapes d’expédition, le suivi, les actualités et les
informations de contact. Les appels à l’action devis/suivi ouvrent les écrans
correspondants de l’application.

## Lancer

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Cette version est un frontend de démonstration uniquement ; aucune API backend
n’est configurée.

## Parcours client Ships4US — maquettes du 7 octobre 2026

Le parcours client Ships4US est reproduit à partir des
captures fournies : menu bleu marine, actions bleues, cartes de colis, photos
extraites des références et panneaux de suivi. Sur écran étroit, le menu se
transforme en tiroir et les panneaux se placent sous le contenu principal.

Écrans : accueil, colis à recevoir, en transit, livrés, détails produit, suivi,
réservation en quatre étapes, liste et historique des réservations, portefeuille,
historique et détail des transactions, moyens de paiement, ajout de moyen,
paramètres de paiement, documents, notifications, profil, aide et support.

Les réservations ajoutées, le solde, les moyens de paiement et le profil sont
modifiables pour la session. Les paiements, documents, messages et positions GPS
restent des démonstrations. Aucune donnée n’est conservée après fermeture et
aucun service financier ou transporteur n’est connecté. La carte est une image
extraite de la maquette. Les reçus sont consultables dans une fenêtre.

Entrée : `lib/presentation/pages/client_space/ships_client_page.dart`.
Les anciens écrans restent disponibles avec `BarrelGoApp(legacy: true)`.

Lancer le parcours : `flutter run -d windows` ou `flutter run -d chrome`.
Vérifier : `flutter test`.
La capture de contrôle est produite dans `preview/ships4us-desktop.png`.


## Accueil public Ships4US

L’application démarre sur la nouvelle page publique : présentation de
l’entreprise, collecte aux États-Unis, transport international, suivi,
livraison au Togo, fonctionnement en quatre étapes et contact.
Les liens du menu font défiler la page jusqu’à la section correspondante.
Sur mobile, ces liens sont accessibles dans le menu.

« Se connecter — Client » ouvre le formulaire de connexion ou d’inscription,
puis le parcours client existant. « Accueil public » permet d’y revenir.
Cette connexion est une démonstration locale : aucun compte ni mot de passe
n’est enregistré ou vérifié par un service distant. Le formulaire de contact
valide la saisie mais ne transmet aucun message.

« Compte livreur » ouvre la connexion de démonstration puis le nouvel
espace livreur. Les pages de confidentialité et de conditions restent à rédiger avant
la mise en service.

Source : `lib/presentation/pages/home/ships_public_home_page.dart`.
Connexion : `lib/presentation/pages/client_space/ships_login_page.dart`.
Visuel embarqué : `assets/images/public_home_hero.png`, extrait de la maquette
publique proposée. Aucun téléchargement de visuel n’est requis au lancement.
Capture : `preview/ships4us-public-home.png`.

## Documents et paramètres du compte

Les deux écrans sont intégrés au menu client avec le style des maquettes proposées.
Documents : huit exemples, catégories, recherche, filtrage par colis, pagination,
aperçu, import PDF/JPG/PNG (10 Mo maximum), association à un colis,
téléchargement et impression. Les documents fournis sont des démonstrations ;
les fichiers importés restent en mémoire pendant la session.
Paramètres : photo, profil, adresses, préférences, notifications, accès aux moyens
de paiement, déconnexion et réinitialisation des données de démonstration.
Les opérations de sécurité demandent le futur service d’authentification.
Les réglages restent locaux à la session ; aucune donnée n’est envoyée à un serveur.
Captures : preview/ships4us-documents.png et preview/ships4us-settings.png.

## Parcours livreur Ships4US

« Compte livreur » sur l’accueil public ouvre maintenant la connexion de démonstration
puis un espace distinct du client : tableau de bord, missions disponibles,
missions en cours, historique, revenus, notifications, profil et aide.
La disponibilité et la zone (Togo / États-Unis) filtrent les missions locales.
Une mission progresse dans cet ordre : acceptation, collecte, début du trajet,
remise au réceptionnaire. La livraison exige son nom et une confirmation ;
une photo JPG/PNG jusqu’à 10 Mo peut être ajoutée. Le revenu est crédité une seule fois.
Les incidents restent attachés à la mission. L’itinéraire ouvre Google Maps ;
il n’y a pas de suivi GPS en direct. Le relevé des revenus peut être exporté en CSV.
Les données sont fictives et conservées uniquement pendant la session.
Aucune mission réelle, notification distante ou transaction financière n’est déclenchée.
Sources : lib/presentation/pages/driver_space/ships_driver_page.dart et driver_models.dart.
Captures : preview/ships4us-driver-dashboard.png et preview/ships4us-driver-mission.png.

