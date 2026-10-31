// NON ASSEMBLÉ. Paiement d'une réservation collectée.
//
// 1. Détail du prix par colis (POST /pricing/quote, frais kilométriques inclus).
// 2. POST /payments/capture -> clientSecret.
// 3. Le SDK de carte confirme (CardPaymentLauncher).
// 4. Le webhook Stripe marque le paiement « succeeded » côté serveur : on relit
//    le reçu (GET /payments/{id}/receipt) jusqu'à confirmation.
import '../../data/models/api_models.dart';
import '../../data/services/backend_api.dart';
import '../common/feature_controller.dart';
import 'card_payment_launcher.dart';

enum PaymentStage { idle, confirming, waitingServer, paid }

class PaymentController extends FeatureController {
  PaymentController(
    this._api,
    this._launcher,
    this.pickup, {
    this.pollDelay = const Duration(seconds: 2),
    this.pollAttempts = 5,
  });

  final BackendApi _api;
  final CardPaymentLauncher _launcher;
  final ApiPickup pickup;
  final Duration pollDelay;
  final int pollAttempts;

  List<ApiParcel> parcels = [];
  final Map<int, ApiPricing> quotes = {};
  ApiPayment? payment;
  PaymentStage stage = PaymentStage.idle;

  /// Message non bloquant (ex. paiement en cours de validation).
  String? info;

  double get total => quotes.values.fold(0, (sum, q) => sum + q.totalAmount);
  bool get quotesComplete => parcels.isNotEmpty && quotes.length == parcels.length;

  Future<void> load() async {
    final list = await run(() async => (await _api.parcelsOf(pickup.id)).items);
    if (list == null) return;
    parcels = list;
    quotes.clear();
    for (final parcel in parcels) {
      final quote = await run(() => _api.quote(parcel.id));
      if (quote != null) quotes[parcel.id] = quote;
    }
    notifyListeners();
  }

  /// Lance le paiement. Renvoie vrai si le serveur confirme le paiement.
  Future<bool> pay() async {
    info = null;
    final created = await run(() => _api.capturePayment(pickup.id));
    if (created == null) return false;
    payment = created;

    if (created.status == 'succeeded') {
      stage = PaymentStage.paid;
      notifyListeners();
      return true;
    }
    final secret = created.clientSecret;
    if (secret == null || secret.isEmpty) {
      error = 'Le paiement n’a pas pu être préparé. Réessayez.';
      notifyListeners();
      return false;
    }

    stage = PaymentStage.confirming;
    notifyListeners();
    final outcome = await _launcher.confirm(secret);
    if (outcome.status != CardPaymentStatus.succeeded) {
      stage = PaymentStage.idle;
      error = outcome.status == CardPaymentStatus.canceled
          ? 'Paiement annulé.'
          : outcome.message ?? 'Le paiement a échoué. Vérifiez votre carte.';
      notifyListeners();
      return false;
    }

    stage = PaymentStage.waitingServer;
    notifyListeners();
    for (var attempt = 0; attempt < pollAttempts; attempt++) {
      final receipt = await run(() async =>
          ApiPayment.fromJson(await _api.receipt(created.id)));
      if (receipt != null) {
        payment = receipt;
        if (receipt.status == 'succeeded') {
          stage = PaymentStage.paid;
          notifyListeners();
          return true;
        }
        if (receipt.status == 'failed') {
          stage = PaymentStage.idle;
          error = 'Le paiement a été refusé. Aucun montant n’a été débité.';
          notifyListeners();
          return false;
        }
      }
      await Future<void>.delayed(pollDelay);
    }
    info = 'Paiement en cours de validation. Vous serez notifié dès qu’il est confirmé.';
    notifyListeners();
    return false;
  }
}
