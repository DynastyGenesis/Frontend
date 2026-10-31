// NON ASSEMBLÉ. Port vers le SDK de paiement par carte (Stripe).
//
// Le backend crée un PaymentIntent (`POST /payments/capture`) et renvoie un
// `clientSecret`. C'est le SDK qui collecte la carte et confirme le paiement :
// aucune donnée de carte ne passe par notre application ni par le backend.
// À l'assemblage : implémenter ce port avec le package `flutter_stripe`
// (non ajouté au projet pour l'instant) et le fournir au PaymentController.

enum CardPaymentStatus { succeeded, canceled, failed }

class CardPaymentOutcome {
  const CardPaymentOutcome(this.status, [this.message]);
  final CardPaymentStatus status;
  final String? message;
}

abstract class CardPaymentLauncher {
  /// Affiche la feuille de paiement et confirme le paiement.
  /// Ne jamais enregistrer ni journaliser [clientSecret].
  Future<CardPaymentOutcome> confirm(String clientSecret);
}

/// Utilisé tant que le SDK de paiement n'est pas branché.
class UnavailableCardPaymentLauncher implements CardPaymentLauncher {
  const UnavailableCardPaymentLauncher();

  @override
  Future<CardPaymentOutcome> confirm(String clientSecret) async =>
      const CardPaymentOutcome(CardPaymentStatus.failed,
          'Le paiement par carte n’est pas encore disponible dans cette version.');
}
