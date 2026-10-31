// NON ASSEMBLÉ. Liste et détail des réservations de l'expéditeur.
import '../../core/status_mapping.dart';
import '../../data/api/paged.dart';
import '../../data/models/api_models.dart';
import '../../data/services/backend_api.dart';
import '../common/feature_controller.dart';

class MyReservationsController extends PagedController<ApiPickup> {
  MyReservationsController(this._api);

  final BackendApi _api;

  /// Filtre de statut backend (pending, assigned, collected, delayed,
  /// reassigned, cancelled) ; null = toutes.
  String? statusFilter;

  Future<void> setFilter(String? status) {
    statusFilter = status;
    return refresh();
  }

  @override
  Future<Paged<ApiPickup>> fetchPage(int page) =>
      _api.reservations(page: page, status: statusFilter);
}

/// Détail d'une réservation : colis, annulation, réponse à un report.
class ReservationDetailController extends FeatureController {
  ReservationDetailController(this._api, this.pickup);

  final BackendApi _api;
  ApiPickup pickup;
  List<ApiParcel> parcels = [];

  bool get canCancel => pickupCanBeCancelled(pickup.status);

  /// Le livreur a proposé un nouveau créneau : le client doit répondre.
  bool get awaitingReportAnswer => pickup.status == 'delayed' && pickup.driverReported;

  /// Une réservation collectée peut être payée.
  bool get canPay => pickup.status == 'collected';

  Future<void> load() async {
    final result = await run(() async {
      final fresh = await _api.reservation(pickup.id);
      final list = await _api.parcelsOf(pickup.id);
      return (fresh, list.items);
    });
    if (result == null) return;
    pickup = result.$1;
    parcels = result.$2;
    notifyListeners();
  }

  /// Renvoie vrai si la réservation est annulée. Un 409 (déjà collectée)
  /// recharge l'état pour afficher la situation réelle.
  Future<bool> cancel() async {
    final done = await run(() async {
      await _api.cancelReservation(pickup.id);
      return true;
    });
    if (done == true) {
      await load();
      return true;
    }
    if (failure?.isConflict == true) await load();
    return false;
  }

  Future<bool> answerReport({required bool accept}) async {
    final done = await run(() async {
      await _api.respondToReport(pickup.id, accept: accept);
      return true;
    });
    if (done == true) await load();
    return done == true;
  }
}
