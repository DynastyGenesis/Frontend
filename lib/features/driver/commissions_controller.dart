// NON ASSEMBLÉ. Commissions dues par le livreur (GET /livreur/commissions).
import '../../data/models/api_models_extra.dart';
import '../../data/services/backend_api.dart';
import '../common/feature_controller.dart';

class CommissionsController extends FeatureController {
  CommissionsController(this._api);

  final BackendApi _api;
  final List<ApiCommission> commissions = [];
  List<ApiBillingCycle> cycles = [];
  int _page = 0;
  bool hasMore = false;
  bool loadedOnce = false;

  Future<void> refresh() async {
    final result = await run(() => _api.commissions(page: 1));
    if (result == null) return;
    commissions
      ..clear()
      ..addAll(result.commissions);
    cycles = result.cycles;
    _page = 1;
    hasMore = result.meta.currentPage < result.meta.lastPage;
    loadedOnce = true;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (busy || !hasMore) return;
    final result = await run(() => _api.commissions(page: _page + 1));
    if (result == null) return;
    commissions.addAll(result.commissions);
    _page += 1;
    hasMore = result.meta.currentPage < result.meta.lastPage;
    notifyListeners();
  }

  double get totalListed => commissions.fold(0, (sum, c) => sum + c.amount);
}

