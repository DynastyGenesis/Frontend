import '../api/api_client.dart';
import '../api/paged.dart';
import '../models/api_models.dart';
import '../models/api_models_raffle.dart';
import '../models/api_models_extra.dart';

/// Appels vers les routes du backend Laravel (préfixe `/api/v1`).
///
/// Chaque méthode correspond à une route du contrat `docs/openapi.yaml` du
/// dépôt BarellGo_Backend. Les identifiants numériques (réservation, colis,
/// paiement) sont des entiers ; les identifiants d'utilisateurs sont des UUID.
class BackendApi {
  BackendApi(this._client);

  final ApiClient _client;

  /// Client HTTP sous-jacent, pour les écrans qui ont besoin d'un appel brut.
  ApiClient get client => _client;

  Map<String, dynamic> _map(dynamic json) =>
      json is Map<String, dynamic> ? json : const <String, dynamic>{};

  Map<String, dynamic> _page(int page, int perPage, [String? key, String? value]) =>
      {
        'page': page,
        'per_page': perPage,
        if (key != null && value != null) key: value,
      };

  // ---- Compte ----

  Future<ApiUser> me() async => ApiUser.fromJson(_map(await _client.get('/me')));

  /// Renseigne l'état américain (code à deux lettres) de l'utilisateur.
  Future<ApiUser> updateState(String state) async => ApiUser.fromJson(
        _map(await _client.patch('/me', body: {'state': state})),
      );

  /// Crée le profil livreur. `vehicleType` : moto, tricycle ou camionnette.
  /// Répond 409 si le profil existe déjà.
  Future<void> becomeDriver({
    required String vehicleType,
    String? badgeNumber,
  }) async {
    await _client.post('/livreur/onboarding', body: {
      'vehicle_type': vehicleType,
      if (badgeNumber != null && badgeNumber.isNotEmpty)
        'badge_number': badgeNumber,
    });
  }

  // ---- Réservations ----

  Future<List<ApiSlot>> pickupSlots({String? date}) async {
    final json = await _client.get('/pickup-slots', query: {'date': date});
    return [
      if (json is List)
        for (final item in json)
          if (item is Map<String, dynamic>) ApiSlot.fromJson(item),
    ];
  }

  Future<ApiPickup> createReservation({
    required String address,
    required ApiSlot slot,
  }) async =>
      ApiPickup.fromJson(_map(await _client.post('/reservations', body: {
        'pickup_address': address,
        'scheduled_window_start': slot.startIso,
        'scheduled_window_end': slot.endIso,
      })));

  Future<Paged<ApiPickup>> reservations({
    int page = 1,
    int perPage = 25,
    String? status,
  }) async =>
      Paged.fromJson(
        await _client.get('/reservations',
            query: _page(page, perPage, 'status', status)),
        ApiPickup.fromJson,
      );

  Future<ApiPickup> reservation(int id) async =>
      ApiPickup.fromJson(_map(await _client.get('/reservations/$id')));

  Future<ApiPickup> updateReservation(
    int id, {
    String? address,
    ApiSlot? slot,
  }) async =>
      ApiPickup.fromJson(_map(await _client.patch('/reservations/$id', body: {
        'pickup_address': ?address,
        if (slot != null) 'scheduled_window_start': slot.startIso,
        if (slot != null) 'scheduled_window_end': slot.endIso,
      })));

  /// Annule la réservation. Répond 409 si elle n'est plus annulable.
  Future<void> cancelReservation(int id) async {
    await _client.post('/reservations/$id/cancel');
  }

  Future<ApiParcel> addParcel(
    int pickupId, {
    required String recipientUserId,
    required double weightKg,
    bool selfDropoff = false,
  }) async =>
      ApiParcel.fromJson(
        _map(await _client.post('/reservations/$pickupId/parcels', body: {
          'recipient_user_id': recipientUserId,
          'weight_kg': weightKg,
          'self_dropoff': selfDropoff,
        })),
      );

  Future<Paged<ApiParcel>> parcelsOf(int pickupId,
          {int page = 1, int perPage = 25}) async =>
      Paged.fromJson(
        await _client.get('/reservations/$pickupId/parcels',
            query: _page(page, perPage)),
        ApiParcel.fromJson,
      );

  /// Désigne le payeur (expéditeur ou destinataire). Répond 409 si un
  /// paiement est déjà engagé.
  Future<ApiPayment> designatePayer(int pickupId, String payerUserId) async =>
      ApiPayment.fromJson(
        _map(await _client.patch('/reservations/$pickupId/payer',
            body: {'payer_user_id': payerUserId})),
      );

  /// Réponse du client à un report proposé par le livreur.
  Future<void> respondToReport(int pickupId, {required bool accept}) async {
    await _client
        .post('/reservations/$pickupId/report-response', body: {'accept': accept});
  }

  // ---- Prix et paiement ----

  /// Estimation avant réservation. Route publique : le jeton, s'il existe,
  /// sert seulement à calculer la remise du premier envoi.
  Future<ApiPriceEstimate> estimate({bool selfDropoff = false}) async =>
      ApiPriceEstimate.fromJson(
        _map(await _client
            .post('/pricing/estimate', body: {'self_dropoff': selfDropoff})),
      );

  Future<ApiPricing> quote(int parcelId) async => ApiPricing.fromJson(
        _map(await _client.post('/pricing/quote', body: {'parcel_id': parcelId})),
      );

  /// Prépare le paiement d'une réservation collectée. La réponse contient le
  /// `clientSecret` Stripe, à transmettre au SDK de paiement sans le stocker.
  Future<ApiPayment> capturePayment(int pickupId) async =>
      ApiPayment.fromJson(
        _map(await _client
            .post('/payments/capture', body: {'pickup_id': pickupId})),
      );

  Future<Map<String, dynamic>> receipt(int paymentId) async =>
      _map(await _client.get('/payments/$paymentId/receipt'));

  // ---- Suivi des colis ----

  /// `role` : `sender` (colis envoyés), `recipient` (colis reçus) ou null.
  Future<Paged<ApiParcel>> shipments({
    String? role,
    String? status,
    int page = 1,
    int perPage = 25,
  }) async =>
      Paged.fromJson(
        await _client.get('/shipments', query: {
          'page': page,
          'per_page': perPage,
          'role': role,
          'status': status,
        }),
        ApiParcel.fromJson,
      );

  Future<ApiShipmentStatus> shipmentStatus(int parcelId) async =>
      ApiShipmentStatus.fromJson(
        _map(await _client.get('/shipments/$parcelId/status')),
      );

  /// Le livreur déclare l'arrivée du colis (in_transit vers arrived).
  Future<ApiParcel> markArrived(int parcelId) async => ApiParcel.fromJson(
        _map(await _client.post('/shipments/$parcelId/arrive')),
      );

  /// `role` : `expediteur` ou `destinataire`.
  Future<ApiParcel> confirmDelivery(int parcelId, {required String role}) async =>
      ApiParcel.fromJson(
        _map(await _client
            .post('/shipments/$parcelId/confirm-delivery', body: {'role': role})),
      );

  // ---- Livreur ----

  Future<Paged<ApiPickup>> missions({int page = 1, int perPage = 25}) async =>
      Paged.fromJson(
        await _client.get('/livreur/missions', query: _page(page, perPage)),
        ApiPickup.fromJson,
      );

  Future<void> acceptMission(int pickupId) async {
    await _client.post('/missions/$pickupId/accept');
  }

  Future<void> declineMission(int pickupId) async {
    await _client.post('/missions/$pickupId/decline');
  }

  /// Confirme la collecte (route historiquement nommée « weigh »).
  Future<ApiPickup> confirmCollection(int pickupId) async =>
      ApiPickup.fromJson(_map(await _client.post('/missions/$pickupId/weigh')));

  Future<void> reportMission(
    int pickupId, {
    required ApiSlot newSlot,
    String? note,
  }) async {
    await _client.post('/missions/$pickupId/report', body: {
      'new_scheduled_window_start': newSlot.startIso,
      'new_scheduled_window_end': newSlot.endIso,
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  Future<void> sendLocation({
    required double lat,
    required double lng,
    bool available = true,
  }) async {
    await _client.post('/livreur/location',
        body: {'lat': lat, 'lng': lng, 'available': available});
  }

  // ---- Notifications et litiges ----

  Future<Paged<ApiNotification>> notifications(
          {int page = 1, int perPage = 25}) async =>
      Paged.fromJson(
        await _client.get('/notifications', query: _page(page, perPage)),
        ApiNotification.fromJson,
      );

  /// Enregistre le jeton push de l'appareil. `platform` : ios, android, web.
  Future<void> subscribePush({
    required String token,
    required String platform,
  }) async {
    await _client.post('/notifications/subscribe',
        body: {'token': token, 'platform': platform});
  }

  /// `type` : delay, damage, lost ou other.
  Future<void> openDispute({
    required int parcelId,
    required String type,
    String? description,
  }) async {
    await _client.post('/disputes', body: {
      'parcel_id': parcelId,
      'type': type,
      if (description != null && description.isNotEmpty)
        'description': description,
    });
  }

  // ---- Routes complémentaires (écrans non assemblés de lib/features) ----

  /// Grille de prix publique : clé du réglage vers valeur.
  Future<Map<String, double>> pricingRules() async {
    final json = _map(await _client.get('/pricing/rules'));
    return {
      for (final entry in json.entries)
        if (entry.value is num) entry.key: (entry.value as num).toDouble(),
    };
  }

  /// Documents d'un colis (preuve de dépôt, déclaration douane).
  Future<List<ApiDocument>> documents(int parcelId) async {
    final json = await _client.get('/shipments/$parcelId/documents');
    return [
      if (json is List)
        for (final item in json)
          if (item is Map<String, dynamic>) ApiDocument.fromJson(item),
    ];
  }

  /// `type` : proof_of_deposit ou customs_declaration. 10 Mo maximum.
  Future<ApiDocument> uploadDocument(
    int parcelId, {
    required String type,
    required List<int> bytes,
    required String filename,
  }) async =>
      ApiDocument.fromJson(_map(await _client.postFile(
        '/shipments/$parcelId/documents',
        fileField: 'file',
        bytes: bytes,
        filename: filename,
        fields: {'type': type},
      )));

  Future<Paged<ApiDispute>> disputes({int page = 1, int perPage = 25}) async =>
      Paged.fromJson(
        await _client.get('/disputes', query: _page(page, perPage)),
        ApiDispute.fromJson,
      );

  /// Commissions et cycles de facturation du livreur connecté.
  Future<ApiCommissions> commissions({int page = 1, int perPage = 25}) async =>
      ApiCommissions.fromJson(
        await _client.get('/livreur/commissions', query: _page(page, perPage)),
      );

  /// Distance, durée et frais estimés jusqu'au lieu de collecte. Répond 409
  /// si la position du livreur est inconnue ou trop ancienne, 503 si le
  /// module d'itinéraire est indisponible.
  Future<ApiRouteEstimate> routeTo(int pickupId) async =>
      ApiRouteEstimate.fromJson(
        _map(await _client.get('/routes/optimize', query: {'pickup_id': pickupId})),
      );

  // ---- Tirage au sort ----

  /// Tirage du mois pour l'État du compte. Répond 404 si aucun État n'est renseigné.
  Future<ApiRaffleDraw> raffleCurrent() async =>
      ApiRaffleDraw.fromJson(_map(await _client.get('/raffle/current')));

  /// Tirages terminés : ceux de l'État du compte, ou tous pour un administrateur.
  Future<List<ApiRaffleDraw>> raffleHistory() async {
    final json = await _client.get('/raffle/history');
    return [
      if (json is List)
        for (final item in json)
          if (item is Map<String, dynamic>) ApiRaffleDraw.fromJson(item),
    ];
  }
}
