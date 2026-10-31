# Rapport d’audit du projet Ships4US

> **Mise à jour du 31 octobre 2026 :** ce rapport décrit l’ancien état du projet (démonstration locale). Le mode de démonstration, l’ancienne coque `legacy` et le portefeuille ont été supprimés ; l’application est désormais raccordée au backend (voir `README.md` et `RACCORDEMENT_BACKEND.md`). Le contenu ci-dessous est conservé comme historique.

Date : 12 octobre 2026 · Périmètre : projet local `ships4us_client_mobile_modular` et archives présentes dans son dossier parent.

## 1. État général

Le projet possède une interface de démonstration étendue : accueil public, accès client, espace client et espace livreur. Plusieurs actions fonctionnent pendant une session : création d’une réservation, modification du profil, import de documents, variation du solde fictif, progression d’une mission et confirmation de livraison.

Il n’est pas encore prêt pour exploiter un service réel de transport. Les comptes ne sont pas authentifiés, les données métier ne sont pas sauvegardées durablement et les parcours client et livreur ne partagent pas une même source de données. Aucun serveur applicatif ni connexion à une base métier n’a été identifié dans ce projet.

Les limites de démonstration sont souvent annoncées dans les écrans et le README. Elles constituent du travail restant, distinct des anomalies de cohérence décrites plus bas.

## 2. Méthode et vérifications

- Inventaire des sources, ressources, configurations de plateformes, tests, documentation et livrables locaux.
- Lecture de la navigation, des modèles et des principales actions des parcours actuels et de l’ancienne version.
- Exécution de la totalité des tests existants : **19 tests réussis**.
- Analyse statique complète : **20 remarques de niveau information, aucune erreur ni avertissement**. La commande retourne néanmoins un code de sortie 1 à cause de ces remarques.
- Inspection visuelle des captures générées par les tests : réception des colis, documents, paramètres et tableau de bord livreur.

Les constats fonctionnels ci-dessous proviennent principalement de la lecture du code. Les 19 tests ne reproduisent pas toutes les anomalies signalées. Les compilations Windows et web n’ont pas été relancées pendant cet audit ; les livrables existants datent du 8 octobre. Aucun paiement réel, appareil Android/iOS, imprimante physique, serveur distant ou scénario simultané à plusieurs utilisateurs n’a été testé. Cet audit ne certifie pas une conformité réglementaire ni une reproduction de chaque maquette au pixel près.

## 3. Inventaire et organisation

| Élément | État constaté |
|---|---|
| Technologie | Flutter et Dart, version applicative déclarée 1.0.0+1 |
| Sources applicatives | 27 fichiers Dart sous `lib` |
| Ressources | 24 fichiers image, 6 fichiers de police ; dossier d’icônes sans fichier |
| Tests | 5 fichiers de tests ; 19 tests exécutés |
| Plateformes présentes | Android, iOS, Windows, macOS, Linux et web ; présence des dossiers distincte d’une validation sur chaque plateforme |
| Gestion de versions | Dépôt Git présent, premier commit `bd3881c` du 12 octobre 2026, distant configuré vers `DynastyGenesis/Frontend` ; état distant non vérifié |
| Intégration continue | Aucun workflow CI ni dossier de tests d’intégration identifié |
| Documentation | README présent, mais mélange descriptions anciennes et nouvelles |

Le démarrage actuel passe par `lib/main.dart`, puis `lib/app/app.dart`, et affiche l’accueil public Ships4US. L’application conserve une autre branche accessible avec l’option `legacy`, regroupant l’ancien accueil barrelGo, le suivi, les devis et les anciens espaces client/livreur.

Les services de `lib/data/services` fournissent des exemples locaux. Ils ne constituent pas une connexion à un serveur. Les pages actuelles gèrent une grande partie des données directement dans leur état d’interface.

## 4. Accueil public et connexion

**Présent :** présentation de l’entreprise et de ses services, parcours d’expédition, sections de navigation, contact, boutons d’accès client et livreur, formulaires de connexion et d’inscription, adaptation aux écrans étroits.

**Limites :** le formulaire de contact ne transmet aucun message. Les conditions d’utilisation et la confidentialité ouvrent des textes d’attente. La connexion vérifie la forme des champs puis ouvre directement l’espace demandé : elle ne vérifie aucun compte ni mot de passe auprès d’un service. Le nom et l’adresse e-mail saisis ne personnalisent pas le compte de démonstration ouvert. La récupération de mot de passe est informative.

**Incohérence éditoriale :** l’accueil indique encore « Votre espace dédié arrive prochainement » pour le livreur, alors que le bouton permet déjà d’ouvrir son parcours de démonstration.

Sources principales : `ships_public_home_page.dart`, `ships_login_page.dart:28`.

## 5. Parcours client

| Écran ou fonction | Présent | Limite actuelle |
|---|---|---|
| Accueil client | Indicateurs, derniers colis, accès rapides | Plusieurs chiffres et le prénom de salutation sont fixes |
| Colis à recevoir | Cartes, recherche, détails | Liste limitée aux quatre premiers exemples |
| En transit | Liste et détails | Statuts affichés sur les cartes parfois différents du statut enregistré |
| Livrés | Liste, détails et historique visuel | La liste affiche cinq exemples comme livrés sans filtrer leur vrai statut |
| Détails et suivi | Produit, montants, frise et carte | Carte et étapes de démonstration, sans position en direct |
| Réservation | Formulaire en quatre étapes et ajout à la liste des réservations | Informations opérationnelles partiellement perdues après confirmation ; tarif fixe |
| Mes réservations / historique | Liste, filtres et panneau de détail | Dates et références partiellement fabriquées ; pas de processus d’annulation |
| Portefeuille | Solde fictif, recharge, retrait avec contrôle de solde | Pas de paiement réel ni de journal alimenté par ces opérations |
| Moyens de paiement | Ajout, suppression et choix du principal en session | Libellés fictifs ; aucun prestataire de paiement connecté |
| Notifications | Liste et lecture locale | Données principalement prédéfinies, sans événements serveur |
| Aide et support | Formulaires et dialogues | Pas d’envoi ni de suivi durable de tickets |

### Anomalies client prioritaires

1. **Nouveaux colis absents des listes de suivi.** La réservation ajoute un élément à `products`, mais les pages de colis utilisent une liste limitée à quatre ou cinq indices. Le nouveau colis apparaît dans les réservations sans rejoindre normalement les listes de réception/transit/livraison. Source : `ships_client_page.dart:594` et `:1024`.
2. **Livraisons affichées à tort.** La page « Livrés » prend les cinq premiers produits et leur impose visuellement le badge « Livré », y compris à ceux qui sont encore en attente ou en transit. Source : `ships_client_page.dart:476` et `:594`.
3. **Badge incorrect en transit.** La sélection utilise le statut enregistré, mais la carte peut afficher « En attente de collecte », car son badge dépend de la position du produit plutôt que de son statut. Source : `ships_client_page.dart:496`.
4. **Données de réservation incomplètes.** Les adresses, téléphones, nom du destinataire et type de colis ne sont pas conservés dans le nouvel enregistrement. Le formulaire est ensuite vidé. Ces données manqueraient pour organiser la collecte et la remise. Source : `ships_client_page.dart:1024`.
5. **Historique financier incohérent.** Une recharge ou un retrait change le solde, mais ne crée pas de transaction. Les six transactions, leurs montants et les totaux restent prédéfinis. Tous les boutons de reçu renvoient au même produit Nike ; le moyen de paiement affiché est le principal actuel, pas celui d’une opération historique. Sources : `ships_client_page.dart:1173` et `:1782`.
6. **Indicateurs sans lien avec les données.** Les nombres 5, 2, 8 et 4 du tableau de bord ne sont pas calculés depuis les colis. Le compteur « 8 livrés » dépasse les cinq produits initiaux. Source : `ships_client_page.dart:651`.
7. **Validation à renforcer.** Le poids ne rejette pas explicitement les valeurs non finies ; les dates et téléphones sont essentiellement des champs texte non vides. La description devient obligatoire alors que la maquette la présente comme facultative. Constat de lecture, sans reproduction de chaque cas limite. Source : `ships_client_page.dart:896`.

## 6. Documents

**Présent :** huit documents d’exemple, catégories, recherche, filtre par colis, pagination, aperçu, import PDF/JPG/JPEG/PNG, contrôle de taille jusqu’à 10 Mo et contrôle des premiers octets du fichier. Le code prévoit téléchargement, génération de PDF de démonstration, impression et accès au colis lié.

**Limites et incohérences :**

- Les imports restent en mémoire et ne sont pas déposés sur un espace serveur sécurisé.
- L’association lors d’un import propose seulement quatre références fixes. Les nouveaux colis réservés ne sont pas proposés.
- La date des nouveaux documents est fixée au 7 octobre 2026 au lieu de la date d’ajout réelle.
- Les PDF générés utilisent des prix et trajets prédéfinis ; ils ne sont pas des factures issues d’un paiement vérifié.
- Une pièce d’identité d’exemple annoncée en JPG peut être téléchargée comme un PDF de démonstration faute de fichier image original.
- Le contrôle des premiers octets ne valide pas le contenu complet du fichier. Un vrai service devra vérifier les fichiers, les droits d’accès et leur stockage.
- Le téléchargement et l’impression sur téléphone restent à valider et, si nécessaire, à adapter. L’implémentation native actuelle utilise un sélecteur de destination de fichier.

Sources : `account/client_documents_panel.dart:59`, `:166`, `account/account_components.dart`, `account/document_export_io.dart` et `account/document_export_web.dart`.

## 7. Paramètres et profil

**Présent :** modification du nom, e-mail, téléphone, pays et photo ; adresses de collecte et de livraison ; choix USD/FCFA ; fuseau horaire ; préférences de notifications ; accès aux paiements ; déconnexion et réinitialisation de démonstration.

**Limites :** les préférences de devise, fuseau et notifications sont enregistrées dans l’objet de session mais ne pilotent pas réellement l’ensemble des montants, dates et notifications. La langue ne propose que le français. Le changement de mot de passe et la double authentification sont des dialogues informatifs.

Un ancien écran « Mes informations » subsiste avec son propre état et peut diverger des nouveaux paramètres. Le tableau de bord conserve « Bonjour Koffi ! » après modification du nom. Le bloc du moyen principal affiche un visuel VISA même lorsqu’un autre moyen est choisi.

**Point technique à tester :** certains dialogues client libèrent leur contrôleur de texte dès le retour de `showDialog`, avant la fin possible de l’animation de fermeture. Le parcours livreur possède déjà une gestion plus prudente. Le risque mérite un test ciblé ; aucun plantage de ces dialogues n’a été reproduit pendant cet audit.

Sources : `account/client_settings_panel.dart:72`, `:284`, `ships_client_page.dart:655`, `:1849`.

## 8. Parcours livreur

**Présent :** tableau de bord, disponibilité, zones Togo/États-Unis, missions disponibles, missions acceptées, recherche, détails, progression, historique, revenus, relevé CSV, notifications, profil et support. Les liens d’itinéraire ouvrent Google Maps ; un bouton peut ouvrir l’application téléphonique.

La progression locale est définie : disponible → acceptée → collectée → en livraison → livrée. La confirmation nécessite un nom de destinataire et une case de confirmation ; une photo peut être ajoutée. Le modèle empêche de confirmer directement une mission non arrivée à l’étape de remise et protège contre une seconde confirmation créditant de nouveau les revenus. Ces garde-fous font partie des tests réussis.

**Travail restant et anomalies :**

- Les sept missions initiales et les gains sont fictifs. Aucun paiement de livreur ni attribution serveur n’existe.
- Les missions du livreur et les colis du client utilisent des objets et références séparés. Une livraison confirmée ne met pas à jour le compte client.
- Aucun verrouillage ne protège une mission contre son acceptation simultanée par plusieurs livreurs réels.
- L’itinéraire est indicatif ; aucune position GPS n’est transmise en direct.
- Un incident est conservé localement, mais n’est pas envoyé à une équipe. Son bloc d’affichage disparaît lorsque la mission n’est plus active.
- Une progression ou confirmation efface l’ensemble des marqueurs de lecture des notifications : des anciennes notifications peuvent redevenir non lues.
- La preuve de remise reste locale, sans conservation serveur ni journal d’événements partagé.

Sources : `driver_models.dart`, `ships_driver_page.dart:521`, `:584`, `:877`, `:933`.

## 9. Design et fidélité aux maquettes

Les écrans actuels reprennent l’identité Ships4US : bleu, bleu marine, fond clair, navigation latérale, cartes blanches, images de produits et panneaux de suivi. Les pages Documents et Paramètres sont intégrées ; le livreur dispose d’un espace identifiable utilisant les mêmes codes visuels.

La reprise n’est toutefois pas strictement identique à toutes les maquettes : disposition de certaines informations, badges, icônes, avatar, espacement et détails typographiques diffèrent. Certains pictogrammes client sont même des caractères de texte. Les captures montrent une composition cohérente, mais une validation écran par écran, à dimensions égales, reste nécessaire pour affirmer une reproduction fidèle.

L’adaptation desktop/mobile existe dans le code et certains tests couvrent une largeur mobile. Cela ne remplace pas une validation sur téléphone avec clavier, rotation, tailles de texte et accessibilité. Aucun audit complet des lecteurs d’écran, du contraste ou de navigation clavier n’a été réalisé.

## 10. Sécurité et exploitation

Le principal manque est l’authentification réelle : les rôles client et livreur sont choisis dans la navigation, sans autorisation serveur. Un véritable service devra associer chaque colis, document, paiement et mission à un compte autorisé.

La persistance, les sauvegardes, l’historique d’événements, les règles tarifaires, les paiements et les notifications externes restent à construire. Les textes évoquant paiements sécurisés ou suivi en temps réel doivent correspondre aux services effectivement raccordés avant lancement.

Les étapes de transport international et de dédouanement sont surtout présentées visuellement. Aucun espace opérationnel d’administration, de dispatch ou de gestion douanière n’a été identifié dans ce périmètre. Il faudra définir qui valide chacune des étapes entre collecte américaine et livraison togolaise.

Les politiques de confidentialité, conditions, règles de traitement des pièces d’identité et processus de suppression d’un vrai compte restent à fournir pour le service final. Le bouton actuel de suppression réinitialise seulement la démonstration.

## 11. Qualité du code et documentation

Points favorables : séparation en dossiers, composants réutilisables pour les nouveaux panneaux de compte, modèle de mission explicite, dépendances et polices déclarées, exports web/natif séparés, tests sur les parcours principaux, dépôt Git existant.

Points à améliorer : pages très longues (environ 1 888 lignes pour le client actuel et 1 079 pour le livreur actuel), navigation par noms de pages, données client représentées par des chaînes et dictionnaires, logique métier mêlée aux widgets, coexistence des versions anciennes et actuelles, duplication d’informations et de thèmes.

Les 20 remarques de l’analyse concernent notamment des optimisations `const`, un champ pouvant être final, des accolades, une propriété obsolète dans l’ancien livreur et de petits points dans les tests/outils de vérification. Elles n’indiquent pas d’erreur de compilation détectée par l’analyse.

Le README doit préciser la version active et les limites sans mélanger les deux produits. `FILE_MANIFEST.txt` est ancien : il contient des chemins `/mnt/data` et ne représente pas les fichiers ajoutés ensuite. Des logs et captures sont suivis par Git ; il faut choisir quels éléments servent durablement au projet et lesquels sont des diagnostics temporaires.

## 12. Plateformes et livrables

- **Windows :** fenêtre nommée Ships4US, mais métadonnées du programme encore barrelGo/com.example. Deux archives Windows du 8 octobre sont présentes sous des noms client/livreur et parcours client, de même taille ; leur contenu n’a pas été comparé octet par octet.
- **Web :** sources et compilation existante présentes. Titre, description, manifeste et couleur de thème conservent des valeurs barrelGo. Aucun déploiement public n’a été vérifié pendant cet audit.
- **Android :** identifiant `com.example.ships4us_client`, libellé barrelGo et signature de publication utilisant la configuration debug. La permission Internet est présente dans les variantes debug/profile, pas dans le manifeste principal ; elle sera à prévoir pour une version publiée connectée à un serveur.
- **iOS/macOS :** noms barrelGo et identifiants `com.example` encore présents. Compilation et distribution Apple non validées dans cet audit Windows.
- **Linux :** dossier de plateforme présent ; compilation et comportement non vérifiés.
- **Archive source :** le ZIP source du dossier parent date du 5 octobre, avant les derniers parcours. Il ne faut pas le considérer comme une sauvegarde actuelle sans le régénérer ou en vérifier le contenu.

## 13. Ordre recommandé des travaux

| Priorité | Travail | Critère concret de réussite |
|---|---|---|
| 1 — cohérence de la démonstration | Corriger listes, badges, compteurs, réservations et historique financier | Un nouveau colis apparaît au bon endroit ; une recharge crée une ligne cohérente ; aucun colis non livré n’est présenté comme livré |
| 2 — données et comptes réels | Définir le modèle partagé, le stockage et les rôles sécurisés | Une réservation reste après reconnexion et n’est accessible qu’aux personnes autorisées |
| 3 — chaîne client/livreur | Relier affectation, collecte, étapes internationales, incidents et remise | La même référence est suivie de bout en bout ; la confirmation du livreur actualise le client |
| 4 — services externes | Connecter paiement, documents, contact et notifications | Chaque opération possède un résultat vérifiable et un historique ; une demande atteint réellement l’équipe |
| 5 — préparation de livraison | Harmoniser marque, configurations, signature, documentation et contrôles automatiques | La version publiée est identifiée, reproductible et validée sur les appareils ciblés |

Tests à ajouter en priorité : nouveau colis dans toutes les listes pertinentes ; filtre livré fondé sur le vrai statut ; conservation complète des données de réservation ; solde et journal cohérents ; préférences réellement appliquées ; documents liés aux nouveaux colis ; conservation du statut lu des notifications ; fermeture des dialogues client ; synchronisation client/livreur lorsque le serveur sera raccordé.

## 14. Appréciation finale

Le projet est une base d’interface exploitable pour démontrer et affiner l’expérience Ships4US. Les trois espaces demandés sont présents et les tests existants passent. La prochaine étape utile consiste à corriger les incohérences de la démonstration, puis à construire la chaîne de données partagée et sécurisée qui rendra les opérations réelles. Aucun pourcentage d’avancement fiable ni délai de livraison ne peut être déduit du seul nombre d’écrans.

L’audit n’a apporté aucune correction au code applicatif. Les tests ont régénéré certaines captures ; ce rapport constitue le livrable documentaire ajouté au projet.
