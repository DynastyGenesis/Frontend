// NON ASSEMBLÉ. Missions du livreur.
//
// Le backend ne renvoie que les missions « assigned » ou « delayed ». Il
// n'indique pas si la mission est déjà acceptée : un 409 sur « accepter »
// signifie qu'elle l'est (ou que le délai de 5 minutes est dépassé).
// Il n'existe pas encore de liste des missions terminées (historique).
import '../../data/api/paged.dart';
import '../../data/models/api_models.dart';
import '../../data/models/api_models_extra.dart';
import '../../data/services/backend_api.dart';
import '../common/feature_controller.dart';

class MissionsController extends PagedController<ApiPickup> {
  MissionsController(this._api);

  final BackendApi _api;

  @override
  Future<Paged<ApiPickup>> fetchPage(int page) => _api.missions(page: page);

  Future<bool> _act(Future<void> Function() action) async {
    final ok = await run(() async {
      await action();
      return true;
    });
    if (ok == true) {
      await refresh();
      return true;
    }
    if (failure?.isConflict == true) await refresh();
    return false;
  }

  Future<bool> accept(ApiPickup mission) => _act(() => _api.acceptMission(mission.id));

  Future<bool> decline(ApiPickup mission) => _act(() => _api.declineMission(mission.id));

  /// Confirme la collecte. Refusée (409) tant que le livreur n'est pas arrivé
  /// sur place : sa position doit avoir été envoyée à moins de 150 m.
  Future<bool> confirmCollection(ApiPickup mission) =>
      _act(() async => _api.confirmCollection(mission.id));

  /// Propose un nouveau créneau au client. Une seule fois par mission.
  Future<bool> report(ApiPickup mission, ApiSlot newSlot, {String? note}) =>
      _act(() => _api.reportMission(mission.id, newSlot: newSlot, note: note));
}

/// Estimation d'itinéraire vers le lieu de collecte.
class RouteEstimateController extends FeatureController {
  RouteEstimateController(this._api, this.pickupId);

  final BackendApi _api;
  final int pickupId;
  ApiRouteEstimate? estimate;

  Future<void> load() async {
    final result = await run(() => _api.routeTo(pickupId));
    if (result != null) {
      estimate = result;
    } else if (failure?.isConflict == true) {
      error = 'Position inconnue ou trop ancienne. Activez la localisation puis réessayez.';
    } else if (failure?.isUnavailable == true) {
      error = 'Le calcul d’itinéraire est momentanément indisponible.';
    }
    notifyListeners();
  }
}
