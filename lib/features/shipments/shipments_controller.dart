// NON ASSEMBLÉ. Liste « Mes colis » (envoyés ou reçus) et détail de suivi.
import '../../core/status_mapping.dart';
import '../../data/api/paged.dart';
import '../../data/models/api_models.dart';
import '../../data/models/api_models_extra.dart';
import '../../data/services/backend_api.dart';
import '../common/feature_controller.dart';
import '../common/file_picker_port.dart';

class ShipmentsController extends PagedController<ApiParcel> {
  ShipmentsController(this._api);

  final BackendApi _api;

  /// `sender`, `recipient` ou null (tous).
  String? role;

  /// Statut backend (reserved, collected, in_transit, arrived, delivered,
  /// cancelled, delayed_reassigned) ou null.
  String? status;

  Future<void> setFilters({String? role, String? status}) {
    this.role = role;
    this.status = status;
    return refresh();
  }

  @override
  Future<Paged<ApiParcel>> fetchPage(int page) =>
      _api.shipments(role: role, status: status, page: page);
}

class ShipmentDetailController extends FeatureController {
  ShipmentDetailController(this._api, this.parcel,
      {required this.currentUserId, FilePickerPort? picker})
      : _picker = picker ?? const FileSelectorPicker();

  final BackendApi _api;
  final FilePickerPort _picker;
  ApiParcel parcel;
  final String currentUserId;

  List<ApiStatusEntry> history = [];
  List<ApiDocument> documents = [];

  /// Vrai si le compte connecté est le destinataire de ce colis.
  bool get isRecipient =>
      parcel.recipientUserId.toLowerCase() == currentUserId.toLowerCase();

  /// Rôle attendu par `POST /shipments/{id}/confirm-delivery`.
  String get deliveryRole => isRecipient ? 'destinataire' : 'expediteur';

  String get statusLabel => parcelStatusLabel(parcel.status);

  /// Le colis est arrivé : chaque partie peut confirmer la réception.
  bool get canConfirmDelivery => parcel.status == 'arrived';

  Future<void> load() async {
    final result = await run(() async {
      final status = await _api.shipmentStatus(parcel.id);
      final docs = await _api.documents(parcel.id);
      return (status, docs);
    });
    if (result == null) return;
    parcel = result.$1.parcel;
    history = result.$1.history;
    documents = result.$2;
    notifyListeners();
  }

  Future<bool> confirmDelivery() async {
    final updated = await run(() => _api.confirmDelivery(parcel.id, role: deliveryRole));
    if (updated == null) {
      if (failure?.isConflict == true) await load();
      return false;
    }
    await load();
    return true;
  }

  /// Choisit puis envoie un document. Renvoie vrai si l'envoi réussit.
  Future<bool> addDocument(String type) async {
    PickedDocument? file;
    try {
      file = await _picker.pick();
    } catch (_) {
      error = 'Impossible d’ouvrir le sélecteur de fichiers.';
      notifyListeners();
      return false;
    }
    if (file == null) return false;
    final problem = validateDocument(type, file);
    if (problem != null) {
      error = problem;
      notifyListeners();
      return false;
    }
    final picked = file;
    final doc = await run(() => _api.uploadDocument(parcel.id,
        type: type, bytes: picked.bytes, filename: picked.name));
    if (doc == null) return false;
    documents = [doc, ...documents.where((d) => d.id != doc.id)];
    notifyListeners();
    return true;
  }
}
