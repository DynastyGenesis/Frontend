// NON ASSEMBLÉ. Parcours « Nouvelle réservation » (4 étapes).
//
// Ordre des appels backend : POST /reservations, puis un POST
// /reservations/{id}/parcels par colis, puis (si le destinataire paie)
// PATCH /reservations/{id}/payer. Le paiement lui-même se fait après la
// collecte (voir lib/features/payment).
import '../../data/models/api_models.dart';
import '../../data/services/backend_api.dart';
import '../common/feature_controller.dart';
import '../common/slots_controller.dart';
import '../recipients/recipients_controller.dart';

/// Colis en cours de saisie.
class ParcelDraft {
  ParcelDraft({this.recipientCode = '', this.weightText = '', this.selfDropoff = false});

  /// Identifiant (UUID) du compte destinataire.
  String recipientCode;
  String weightText;

  /// Vrai si l'expéditeur dépose lui-même le colis (remise sur le prix).
  bool selfDropoff;

  double? get weight => double.tryParse(weightText.trim().replaceAll(',', '.'));
}

class ReservationController extends FeatureController {
  ReservationController(this._api, {required this.currentUserId, SlotsController? slots})
      : slots = slots ?? SlotsController(_api);

  final BackendApi _api;

  /// Identifiant du compte connecté (un expéditeur ne peut pas être son propre destinataire).
  final String currentUserId;
  final SlotsController slots;

  final List<ParcelDraft> drafts = [ParcelDraft()];
  String address = '';
  bool recipientPays = false;
  ApiPriceEstimate? estimate;

  /// Réservation déjà créée côté serveur ; une nouvelle tentative la reprend.
  ApiPickup? created;
  int _parcelsSent = 0;
  bool _payerSet = false;

  /// Une fois la réservation créée, la collecte et le payeur ne sont plus modifiables.
  bool get locked => created != null;

  /// Un colis déjà enregistré par le backend ne peut plus être modifié ici.
  bool parcelLocked(int index) => index < _parcelsSent;

  /// Des colis restent à envoyer (envoi interrompu par une erreur).
  bool get hasUnsentParcels => created != null && _parcelsSent < drafts.length;

  // ---- Validation (messages français affichés sous les champs) ----

  String? validateRecipient(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Saisissez le code du destinataire.';
    if (!isRecipientCode(text)) {
      return 'Code invalide. Demandez-le au destinataire (écran Mon compte).';
    }
    if (text.toLowerCase() == currentUserId.toLowerCase()) {
      return 'Le destinataire doit être une autre personne que vous.';
    }
    return null;
  }

  String? validateWeight(String? value) {
    final n = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
    if (n == null || !n.isFinite) return 'Saisissez un poids valide.';
    if (n < 0.01) return 'Le poids doit être supérieur à 0.';
    if (n > 999.99) return 'Le poids ne doit pas dépasser 999,99 kg.';
    return null;
  }

  String? validateAddress(String? value) {
    final text = (value ?? '').trim();
    if (text.length < 5) return 'Saisissez l’adresse complète de collecte.';
    if (text.length > 255) return 'Adresse trop longue (255 caractères maximum).';
    return null;
  }

  bool get parcelsValid =>
      drafts.isNotEmpty &&
      drafts.every((d) =>
          validateRecipient(d.recipientCode) == null &&
          validateWeight(d.weightText) == null);

  bool get collectionValid =>
      validateAddress(address) == null && slots.selected != null;

  /// Le destinataire ne peut payer que s'il n'y en a qu'un seul.
  bool get canRecipientPay {
    final codes = drafts.map((d) => d.recipientCode.trim().toLowerCase()).toSet();
    return codes.length == 1 && codes.first.isNotEmpty;
  }

  // ---- Colis ----

  void addParcel() {
    drafts.add(ParcelDraft());
    notifyListeners();
  }

  void removeParcel(int index) {
    if (parcelLocked(index) || drafts.length <= 1) return;
    drafts.removeAt(index);
    if (!canRecipientPay) recipientPays = false;
    notifyListeners();
  }

  void touch() => notifyListeners();

  void setRecipientPays(bool value) {
    recipientPays = value && canRecipientPay;
    notifyListeners();
  }

  // ---- Prix ----

  /// Estimation avant réservation (hors frais kilométriques, connus après assignation).
  Future<void> loadEstimate() async {
    final result =
        await run(() => _api.estimate(selfDropoff: drafts.first.selfDropoff));
    if (result != null) {
      estimate = result;
      notifyListeners();
    }
  }

  /// Total estimé pour tous les colis (le prix est calculé par colis).
  double? get estimatedTotal =>
      estimate == null ? null : estimate!.estimatedTotal * drafts.length;

  // ---- Envoi ----

  /// Crée la réservation puis ajoute les colis. Renvoie la réservation, ou null
  /// en cas d'échec ; relancer reprend là où l'envoi s'est arrêté.
  Future<ApiPickup?> submit() async {
    if (!parcelsValid || !collectionValid) {
      error = 'Complétez les colis et la collecte avant de confirmer.';
      notifyListeners();
      return null;
    }
    final pickup = await run(() async {
      final slot = slots.selected!;
      final pickup =
          created ??= await _api.createReservation(address: address.trim(), slot: slot);
      while (_parcelsSent < drafts.length) {
        final draft = drafts[_parcelsSent];
        await _api.addParcel(
          pickup.id,
          recipientUserId: draft.recipientCode.trim().toLowerCase(),
          weightKg: draft.weight!,
          selfDropoff: draft.selfDropoff,
        );
        _parcelsSent++;
      }
      if (recipientPays && !_payerSet) {
        await _api.designatePayer(
            pickup.id, drafts.first.recipientCode.trim().toLowerCase());
        _payerSet = true;
      }
      return pickup;
    });
    if (pickup == null && failure?.isValidation == true) _explainParcelRefusal();
    return pickup;
  }

  /// Le backend refuse un colis (code destinataire inconnu, poids…) : on dit
  /// lequel, et le formulaire des colis restants reste modifiable.
  void _explainParcelRefusal() {
    final fields = failure!.fieldErrors.keys;
    final number = _parcelsSent + 1;
    if (fields.any((k) => k.contains('recipient'))) {
      error = 'Le destinataire du colis $number est introuvable. Vérifiez son '
          'code : il doit avoir un compte BarelGo et le lire dans Mon compte. '
          'Corrigez le colis puis reprenez l’envoi.';
    } else if (fields.any((k) => k.contains('weight'))) {
      error = 'Le poids du colis $number est refusé. Corrigez-le puis reprenez l’envoi.';
    }
    notifyListeners();
  }
}
