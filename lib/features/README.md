# lib/features — écrans et contrôleurs raccordés au backend

Les parcours client et livreur sont assemblés depuis `client_flow.dart` et
`driver_flow.dart` quand les trois valeurs backend sont configurées. Sans
configuration, l'application affiche une page de configuration.

Parcours actuellement raccordés : réservations et créneaux, liste/détail des
réservations, colis et suivi, documents, litiges, notifications, compte client,
missions disponibles, actions de mission prises en charge par l’API, compte et
commissions livreur.

Les tests de contrôleurs sont dans `test/features_controllers_test.dart` ; le
test `test/client_flow_test.dart` couvre l'aiguillage des pages.

## Principe
- Un contrôleur (`ChangeNotifier`) par écran, sans dépendance à Flutter UI : `busy`, `error`, `failure`.
- Chaque écran reçoit son contrôleur de l'extérieur et se redessine avec `ListenableBuilder`.
- Les SDK absents du projet sont isolés derrière des interfaces (ports).

## Écrans raccordés et limites restantes
| Nouvel écran | Remplace |
|---|---|
| `reservation/reservation_screen.dart` | assistant « Nouvelle expédition » du client |
| `reservation/my_reservations_screen.dart` | liste et détail des expéditions (côté réservation) |
| `payment/payment_screen.dart` | paiement par carte (si la clé Stripe est fournie) |
| `shipments/shipments_screen.dart` | liste, suivi, documents et confirmation de livraison |
| `disputes/disputes_screen.dart` | litiges client ; ouverture possible depuis le détail d’un colis |
| `notifications/notifications_screen.dart` | notifications ; push non activé |
| `account/account_screen.dart` | compte, code destinataire et état américain |
| `pricing/pricing_rules.dart` | grille tarifaire (menu « Tarifs ») |
| `raffle/raffle_screen.dart` | tirage au sort du mois et historique (menus client et livreur) |
| `driver/missions_screen.dart` | missions et commissions du livreur ; GPS/historique non raccordés |

## Ports et leurs adaptateurs (fournis par `AppServices`)
- `payment/card_payment_launcher.dart` → `stripe_card_payment_launcher.dart` (`flutter_stripe`, Android/iOS). Bouton « Payer » masqué si indisponible.
- `driver/location_provider.dart` → `geolocator_location_provider.dart`. Disponibilité, trajet et confirmation de collecte.
- `notifications/push_registrar.dart` → `firebase_push_token_source.dart` ; `AppServices.startPush()` après la connexion.
- `common/file_picker_port.dart` : `FileSelectorPicker` (dépendance `file_selector`).
- Session : `data/auth/secure_session_store.dart`.

Écrans ajoutés : `reservation/edit_reservation.dart` (modifier adresse/créneau d'une réservation « pending ») et `driver/parcel_arrival.dart` (déclarer l'arrivée d'un colis par son numéro).

## Lacunes du backend rencontrées
- Pas de recherche de destinataire : on saisit son **code** (= son identifiant utilisateur, affiché dans son écran Compte).
- Pas de liste des missions terminées (historique livreur) : l’écran indique cette limite au lieu d’afficher les missions locales.
- L'état « acceptée » d'une mission n'est pas exposé : un 409 sur « accepter » en tient lieu.
- L'arrivée du livreur dépend de sa position (moins de 150 m, envoyée toutes les 30 s).
- Type, description, photo et adresse de livraison d'un colis ne sont pas stockés.
- `docs/openapi.yaml` du backend est invalide à la ligne 1243.

## Adaptations du frontend au backend (le backend n'est pas modifié)
- **Destinataire** : il doit avoir un compte. L'expéditeur saisit son code (écran « Mon compte »). Un code inconnu est refusé par le backend : l'écran indique quel colis est en cause, laisse corriger les colis non enregistrés et reprend l'envoi sans recréer la réservation.
- **Informations de colis** : seul ce que le backend stocke est demandé (destinataire, poids, dépôt par le client). Pas de type, description, adresse au Togo ni photo en mode réel.
- **Suivi** : les étapes affichées sont les statuts du backend ; « En livraison » est rapproché de « Arrivé au Togo », et il n'y a pas d'étape douane.
- **Historique livreur** : l'écran dit que l'API ne le fournit pas.

## Reste à décider hors du code
Fonctions qui ne reviendraient que si le backend créait les routes : recherche de destinataire, portefeuille, support, paramètres, historique des missions.
