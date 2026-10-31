import 'package:flutter_test/flutter_test.dart';
import 'package:barrel_go/core/status_mapping.dart';

void main() {
  test('chaque statut de colis du backend a un libellé d’écran', () {
    const expected = {
      'reserved': 'En attente de collecte',
      'collected': 'Collecté aux États-Unis',
      'in_transit': 'En transit',
      'arrived': 'Arrivé au Togo',
      'delivered': 'Livré',
      'cancelled': 'Annulé',
      'delayed_reassigned': 'Collecte reprogrammée',
    };
    expected.forEach((status, label) {
      expect(parcelStatusLabel(status), label);
      expect(parcelStatusFromLabel(label), status);
    });
  });

  test('les anciens libellés d’écran gardent un équivalent', () {
    expect(parcelStatusFromLabel('En livraison'), 'arrived');
    expect(parcelStatusFromLabel('Collecté'), 'collected');
    expect(parcelStatusFromLabel('Annulées'), 'cancelled');
    expect(parcelStatusFromLabel('inconnu'), isNull);
  });

  test('la frise avance avec le statut', () {
    final steps = [
      'reserved',
      'collected',
      'in_transit',
      'arrived',
      'delivered',
    ].map(parcelStepFromBackend).toList();
    expect(steps.first, 1);
    expect(steps.last, 5);
    for (var i = 1; i < steps.length; i++) {
      expect(steps[i], greaterThanOrEqualTo(steps[i - 1]));
    }
  });

  test('l’annulation n’est proposée qu’avant la collecte', () {
    expect(pickupCanBeCancelled('pending'), isTrue);
    expect(pickupCanBeCancelled('assigned'), isTrue);
    expect(pickupCanBeCancelled('collected'), isFalse);
    expect(pickupCanBeCancelled('cancelled'), isFalse);
  });

  test('les statuts de réservation ont un libellé français', () {
    expect(pickupStatusLabel('pending'), 'En attente de livreur');
    expect(pickupStatusLabel('assigned'), 'Livreur assigné');
  });
}
