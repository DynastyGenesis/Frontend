# Corrections frontend — 12 octobre 2026

> **Mise à jour du 31 octobre 2026 :** ce rapport décrit l’ancien état du projet (démonstration locale). Le mode de démonstration, l’ancienne coque `legacy` et le portefeuille ont été supprimés ; l’application est désormais raccordée au backend (voir `README.md` et `RACCORDEMENT_BACKEND.md`). Le contenu ci-dessous est conservé comme historique.

Le backend n’a pas été modifié, conformément à la demande. L’identité bleue Ships4US est conservée.

## Corrections réalisées

- Listes de colis fondées sur les statuts, affichage des nouvelles réservations, badges et compteurs cohérents.
- Réservations conservant type, description, coordonnées, destinataire, dates et références ; description facultative, poids non fini rejeté, téléphones et dates contrôlés, date passée refusée.
- Annulation locale des réservations avant collecte ; retrait des missions de collecte correspondantes lors de l’ouverture du livreur.
- Portefeuille : historique alimenté par chaque recharge/retrait simulé, référence propre, date, montant et moyen de paiement historique ; totaux calculés depuis les opérations.
- Profil et préférences : salutation personnalisée, e-mail issu du formulaire local, avatar affiché, ancien écran de profil relié au même compte, conversion USD/FCFA et décalage d’affichage des dates appliqués, notifications filtrées.
- Documents associés à tous les colis actuels, date d’ajout réelle, estimation de transport créée pour chaque nouvelle réservation, prix de PDF tirés du colis, pièces d’exemple décrites comme PDF générés. Contrôle de taille avant lecture complète du document.
- Dialogues client attendant la fin de la fermeture avant de libérer les champs ; panneau d’aide adapté aux espaces étroits.
- Sauvegarde JSON locale des parcours, profils, documents, opérations et preuves ; adaptateurs natif/web et signalement des erreurs de sauvegarde.
- Liaison locale client/livreur : nouvelle réservation visible en mission de collecte américaine ; remise locale au Togo actualisant le colis lié. La collecte américaine ne vaut pas livraison finale.
- Lecture des notifications livreur conservée lorsqu’une nouvelle notification est ajoutée ; incidents conservés et encore affichés après livraison.
- Contact : brouillons conservés sur l’appareil, consultables dans l’espace client ; aucun envoi prétendu.
- Export mobile via partage PDF natif, export ordinateur et navigateur conservés ; autorisations de fichiers macOS ajoutées.
- Nom Ships4US dans les métadonnées visibles des plateformes ; descriptions et documentation actualisées, manifeste de fichiers régénéré et workflow de contrôles frontend préparé.
- Remarques de qualité du code corrigées dans les fichiers actuels, les anciens écrans et les outils de vérification.

## Vérification

La suite comporte désormais **28 tests** : les 19 existants et 9 tests de régression. La suite complète passe ; les tests de réservation et de régression ont été rejoués après le renforcement des dates. Les compilations de publication Windows et web réussissent.

Les tests vérifient notamment les vrais filtres de statut, les poids invalides, les préférences horaires, le rechargement et sa conservation, les données de réservation, les notifications lues, la fermeture des dialogues et la mise à jour du client après remise par le livreur sans double crédit.

Le partage/impression sur appareils Android/iOS, une imprimante physique et le workflow GitHub ne sont pas certifiés par ces vérifications locales. Une reproduction de chaque maquette au pixel près n’a pas été certifiée.

## Limites conservées pour le travail ultérieur

Authentification réelle, autorisations, synchronisation entre appareils, affectation concurrente, paiements, notifications externes, GPS, opérations internationales/douane et stockage sécurisé relèvent du backend futur. Les données locales sont fictives ; la conversion et les tarifs sont indicatifs. Les textes juridiques de l’entreprise et les signatures/identifiants de distribution restent à fournir avant publication.

Les anciens écrans sont conservés pour compatibilité ; les grandes pages actuelles pourront être découpées ultérieurement. La présente correction ne prétend pas transformer la démonstration en service de production.
