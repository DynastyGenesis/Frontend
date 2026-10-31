// Modèles typés des réponses du backend (contrat docs/openapi.yaml du dépôt
// BarellGo_Backend). Ils sont tolérants : une valeur absente ou d'un autre type
// donne une valeur par défaut au lieu de faire échouer l'écran.
// Les montants peuvent arriver sous forme de nombre ou de chaîne décimale
// ("150.00") ; les deux sont acceptés.

double _toDouble(dynamic value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

int _toInt(dynamic value, [int fallback = 0]) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

int? _toIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

DateTime? _toDate(dynamic value) =>
    value is String ? DateTime.tryParse(value) : null;

String _toText(dynamic value, [String fallback = '']) =>
    value is String ? value : fallback;

/// Profil renvoyé par `GET /me`.
class ApiUser {
  const ApiUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.state,
    this.roles = const [],
  });

  factory ApiUser.fromJson(Map<String, dynamic> json) => ApiUser(
        id: _toText(json['id']),
        name: _toText(json['name']),
        email: _toText(json['email']),
        phone: json['phone'] as String?,
        state: json['state'] as String?,
        roles: [
          if (json['roles'] is List)
            for (final role in json['roles'] as List) '$role',
        ],
      );

  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? state;
  final List<String> roles;

  bool get isDriver => roles.contains('livreur');
  bool get isAdmin => roles.contains('admin');
}

/// Réservation de collecte (pickup). Sert aussi de « mission » côté livreur.
class ApiPickup {
  const ApiPickup({
    required this.id,
    required this.clientId,
    required this.address,
    required this.status,
    this.driverId,
    this.lat,
    this.lng,
    this.windowStart,
    this.windowEnd,
    this.assignedAt,
    this.driverReported = false,
  });

  factory ApiPickup.fromJson(Map<String, dynamic> json) => ApiPickup(
        id: _toInt(json['id']),
        clientId: _toText(json['client_id']),
        driverId: _toIntOrNull(json['driver_id']),
        address: _toText(json['pickup_address']),
        lat: json['pickup_lat'] == null ? null : _toDouble(json['pickup_lat']),
        lng: json['pickup_lng'] == null ? null : _toDouble(json['pickup_lng']),
        windowStart: _toDate(json['scheduled_window_start']),
        windowEnd: _toDate(json['scheduled_window_end']),
        assignedAt: _toDate(json['assigned_at']),
        driverReported: json['driver_reported'] == true,
        status: _toText(json['status'], 'pending'),
      );

  final int id;
  final String clientId;
  final int? driverId;
  final String address;
  final double? lat;
  final double? lng;
  final DateTime? windowStart;
  final DateTime? windowEnd;
  final DateTime? assignedAt;
  final bool driverReported;

  /// pending, assigned, collected, delayed, reassigned ou cancelled.
  final String status;
}

/// Colis d'une réservation.
class ApiParcel {
  const ApiParcel({
    required this.id,
    required this.pickupId,
    required this.recipientUserId,
    required this.weightKg,
    required this.status,
    this.selfDropoff = false,
    this.handledByAgentId,
  });

  factory ApiParcel.fromJson(Map<String, dynamic> json) => ApiParcel(
        id: _toInt(json['id']),
        pickupId: _toInt(json['pickup_id']),
        recipientUserId: _toText(json['recipient_user_id']),
        weightKg: _toDouble(json['weight_kg']),
        selfDropoff: json['self_dropoff'] == true,
        handledByAgentId: _toIntOrNull(json['handled_by_agent_id']),
        status: _toText(json['status'], 'reserved'),
      );

  final int id;
  final int pickupId;
  final String recipientUserId;
  final double weightKg;
  final bool selfDropoff;
  final int? handledByAgentId;

  /// reserved, collected, in_transit, arrived, delivered, cancelled
  /// ou delayed_reassigned.
  final String status;
}

/// Ligne de l'historique de statut d'un colis.
class ApiStatusEntry {
  const ApiStatusEntry({
    required this.id,
    required this.status,
    this.note,
    this.createdAt,
  });

  factory ApiStatusEntry.fromJson(Map<String, dynamic> json) => ApiStatusEntry(
        id: _toInt(json['id']),
        status: _toText(json['status']),
        note: json['note'] as String?,
        createdAt: _toDate(json['created_at']),
      );

  final int id;
  final String status;
  final String? note;
  final DateTime? createdAt;
}

/// Réponse de `GET /shipments/{id}/status`.
class ApiShipmentStatus {
  const ApiShipmentStatus({required this.parcel, required this.history});

  factory ApiShipmentStatus.fromJson(Map<String, dynamic> json) {
    final parcel = json['parcel'];
    final history = json['history'];
    return ApiShipmentStatus(
      parcel: ApiParcel.fromJson(
        parcel is Map<String, dynamic> ? parcel : const <String, dynamic>{},
      ),
      history: [
        if (history is List)
          for (final item in history)
            if (item is Map<String, dynamic>) ApiStatusEntry.fromJson(item),
      ],
    );
  }

  final ApiParcel parcel;
  final List<ApiStatusEntry> history;
}

/// Paiement. `clientSecret` n'est présent que dans la réponse de
/// `POST /payments/capture` ; il ne doit jamais être enregistré ni affiché.
class ApiPayment {
  const ApiPayment({
    required this.id,
    required this.pickupId,
    required this.payerUserId,
    required this.amount,
    required this.status,
    this.paidAt,
    this.clientSecret,
  });

  factory ApiPayment.fromJson(Map<String, dynamic> json) => ApiPayment(
        id: _toInt(json['id']),
        pickupId: _toInt(json['pickup_id']),
        payerUserId: _toText(json['payer_user_id']),
        amount: _toDouble(json['amount']),
        status: _toText(json['status'], 'pending'),
        paidAt: _toDate(json['paid_at']),
        clientSecret: json['client_secret'] as String?,
      );

  final int id;
  final int pickupId;
  final String payerUserId;
  final double amount;

  /// pending, succeeded, failed ou refunded.
  final String status;
  final DateTime? paidAt;
  final String? clientSecret;
}

/// Devis réel d'un colis (`POST /pricing/quote`).
class ApiPricing {
  const ApiPricing({
    required this.barrelPrice,
    required this.insuranceAmount,
    required this.kmFee,
    required this.tollFee,
    required this.discountTotal,
    required this.totalAmount,
  });

  factory ApiPricing.fromJson(Map<String, dynamic> json) => ApiPricing(
        barrelPrice: _toDouble(json['barrel_price']),
        insuranceAmount: _toDouble(json['insurance_amount']),
        kmFee: _toDouble(json['km_fee']),
        tollFee: _toDouble(json['toll_fee']),
        discountTotal: _toDouble(json['discount_total']),
        totalAmount: _toDouble(json['total_amount']),
      );

  final double barrelPrice;
  final double insuranceAmount;
  final double kmFee;
  final double tollFee;
  final double discountTotal;
  final double totalAmount;
}

/// Estimation de prix avant réservation (`POST /pricing/estimate`).
class ApiPriceEstimate {
  const ApiPriceEstimate({
    required this.barrelPrice,
    required this.insuranceAmount,
    required this.estimatedDiscount,
    required this.estimatedTotal,
    this.note = '',
  });

  factory ApiPriceEstimate.fromJson(Map<String, dynamic> json) =>
      ApiPriceEstimate(
        barrelPrice: _toDouble(json['barrel_price']),
        insuranceAmount: _toDouble(json['insurance_amount']),
        estimatedDiscount: _toDouble(json['estimated_discount']),
        estimatedTotal: _toDouble(json['estimated_total_excluding_km_fee']),
        note: _toText(json['note']),
      );

  final double barrelPrice;
  final double insuranceAmount;
  final double estimatedDiscount;

  /// Total estimé, hors frais kilométriques (connus après assignation).
  final double estimatedTotal;
  final String note;
}

/// Créneau de collecte proposé par `GET /pickup-slots`.
///
/// Le backend compare la fenêtre envoyée à la seconde près : il faut renvoyer
/// exactement les chaînes reçues (`startIso`, `endIso`).
class ApiSlot {
  const ApiSlot({
    required this.startIso,
    required this.endIso,
    this.start,
    this.end,
  });

  factory ApiSlot.fromJson(Map<String, dynamic> json) => ApiSlot(
        startIso: _toText(json['window_start']),
        endIso: _toText(json['window_end']),
        start: _toDate(json['window_start']),
        end: _toDate(json['window_end']),
      );

  final String startIso;
  final String endIso;
  final DateTime? start;
  final DateTime? end;
}

/// Notification (`GET /notifications`).
class ApiNotification {
  const ApiNotification({
    required this.id,
    required this.type,
    this.data = const {},
    this.readAt,
  });

  factory ApiNotification.fromJson(Map<String, dynamic> json) =>
      ApiNotification(
        id: _toText(json['id']),
        type: _toText(json['type']),
        data: json['data'] is Map
            ? Map<String, dynamic>.from(json['data'] as Map)
            : const <String, dynamic>{},
        readAt: _toDate(json['read_at']),
      );

  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime? readAt;

  bool get isRead => readAt != null;
}
