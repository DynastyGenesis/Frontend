// NON ASSEMBLÉ. Liste des notifications (GET /notifications).
import '../../data/api/paged.dart';
import '../../data/models/api_models.dart';
import '../../data/services/backend_api.dart';
import '../common/feature_controller.dart';

class NotificationsController extends PagedController<ApiNotification> {
  NotificationsController(this._api);

  final BackendApi _api;

  @override
  Future<Paged<ApiNotification>> fetchPage(int page) =>
      _api.notifications(page: page);

  int get unreadCount => items.where((n) => !n.isRead).length;
}
