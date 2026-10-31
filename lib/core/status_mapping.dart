import 'frontend_rules.dart';

// Correspondance entre les statuts du backend (anglais, en minuscules) et les
// libellés français déjà utilisés par les écrans. Les libellés des écrans ne
// changent pas : seule la source des statuts change.

/// Libellé d'écran d'un statut de colis du backend.
String parcelStatusLabel(String status) => switch (status) {
      'reserved' => 'En attente de collecte',
      'collected' => 'Collecté aux États-Unis',
      'in_transit' => 'En transit',
      'arrived' => 'Arrivé au Togo',
      'delivered' => 'Livré',
      'cancelled' => 'Annulé',
      'delayed_reassigned' => 'Collecte reprogrammée',
      _ => status,
    };

/// Statut backend d'un libellé d'écran, ou null s'il n'a pas d'équivalent.
///
/// « En livraison » n'existe pas côté backend : la dernière étape avant
/// « Livré » est « arrived ».
String? parcelStatusFromLabel(String label) => switch (label) {
      'En attente de collecte' => 'reserved',
      'Collecté' || 'Collecté aux États-Unis' => 'collected',
      'En transit' => 'in_transit',
      'Arrivé au Togo' || 'En livraison' => 'arrived',
      'Livré' => 'delivered',
      'Annulé' || 'Annulées' => 'cancelled',
      'Collecte reprogrammée' => 'delayed_reassigned',
      _ => null,
    };

/// Libellé d'écran d'un statut de réservation (pickup) du backend.
String pickupStatusLabel(String status) => switch (status) {
      'pending' => 'En attente de livreur',
      'assigned' => 'Livreur assigné',
      'collected' => 'Collecté',
      'delayed' => 'Collecte reportée',
      'reassigned' => 'Livreur réassigné',
      'cancelled' => 'Annulé',
      _ => status,
    };

/// Une réservation peut être annulée par l'expéditeur tant qu'elle n'est pas
/// collectée. Le backend reste seul juge (409 sinon).
bool pickupCanBeCancelled(String status) =>
    status == 'pending' ||
    status == 'assigned' ||
    status == 'delayed' ||
    status == 'reassigned';

/// Étape (1 à 5) de la frise de suivi pour un statut de colis du backend.
int parcelStepFromBackend(String status) =>
    parcelStep(parcelStatusLabel(status));
