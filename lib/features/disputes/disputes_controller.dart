// NON ASSEMBLÉ. Litiges : ouverture (POST /disputes) et suivi (GET /disputes).
import '../../data/api/paged.dart';
import '../../data/models/api_models_extra.dart';
import '../../data/services/backend_api.dart';
import '../common/feature_controller.dart';

class DisputesController extends PagedController<ApiDispute> {
  DisputesController(this._api);

  final BackendApi _api;

  @override
  Future<Paged<ApiDispute>> fetchPage(int page) => _api.disputes(page: page);

  /// Ouvre un litige. `type` : delay, damage, lost ou other.
  Future<bool> open({
    required int parcelId,
    required String type,
    String? description,
  }) async {
    if (!disputeTypes.containsKey(type)) {
      error = 'Choisissez le type de problème.';
      notifyListeners();
      return false;
    }
    final text = description?.trim() ?? '';
    if (text.length > 2000) {
      error = 'La description ne doit pas dépasser 2000 caractères.';
      notifyListeners();
      return false;
    }
    final ok = await run(() async {
      await _api.openDispute(parcelId: parcelId, type: type, description: text);
      return true;
    });
    if (ok == true) await refresh();
    return ok == true;
  }
}
