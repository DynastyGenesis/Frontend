// Modèles des routes complémentaires du backend : documents d'un colis,
// litiges, commissions du livreur, estimation d'itinéraire.
// Même tolérance que api_models.dart : valeur absente = valeur par défaut.

import '../api/paged.dart';

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

DateTime? _toDate(dynamic value) =>
    value is String ? DateTime.tryParse(value) : null;

String _toText(dynamic value, [String fallback = '']) =>
    value is String ? value : fallback;

/// Types de documents acceptés par le backend.
const documentTypes = <String, String>{
  'proof_of_deposit': 'Preuve de dépôt',
  'customs_declaration': 'Déclaration en douane',
};

/// Types de litige acceptés par le backend.
const disputeTypes = <String, String>{
  'delay': 'Retard',
  'damage': 'Colis abîmé',
  'lost': 'Colis perdu',
  'other': 'Autre',
};

String disputeStatusLabel(String status) => switch (status) {
      'open' => 'Ouvert',
      'under_review' => 'En cours d’examen',
      'resolved' => 'Résolu',
      'rejected' => 'Refusé',
      _ => status,
    };

/// Document rattaché à un colis (`GET /shipments/{id}/documents`).
/// `url` est une adresse signée à durée limitée : ne pas la conserver.
class ApiDocument {
  const ApiDocument({
    required this.id,
    required this.parcelId,
    required this.type,
    required this.url,
    this.uploadedBy,
  });

  factory ApiDocument.fromJson(Map<String, dynamic> json) => ApiDocument(
        id: _toInt(json['id']),
        parcelId: _toInt(json['parcel_id']),
        type: _toText(json['type']),
        url: _toText(json['file_path']),
        uploadedBy: json['uploaded_by'] is String
            ? json['uploaded_by'] as String
            : null,
      );

  final int id;
  final int parcelId;
  final String type;
  final String url;
  final String? uploadedBy;

  String get label => documentTypes[type] ?? type;
}

/// Litige (`GET /disputes`, `POST /disputes`).
class ApiDispute {
  const ApiDispute({
    required this.id,
    required this.parcelId,
    required this.type,
    required this.status,
    this.description,
    this.resolutionNote,
  });

  factory ApiDispute.fromJson(Map<String, dynamic> json) => ApiDispute(
        id: _toInt(json['id']),
        parcelId: _toInt(json['parcel_id']),
        type: _toText(json['type']),
        status: _toText(json['status']),
        description:
            json['description'] is String ? json['description'] as String : null,
        resolutionNote: json['resolution_note'] is String
            ? json['resolution_note'] as String
            : null,
      );

  final int id;
  final int parcelId;
  final String type;
  final String status;
  final String? description;
  final String? resolutionNote;

  String get typeLabel => disputeTypes[type] ?? type;
  String get statusLabel => disputeStatusLabel(status);
}

/// Commission due par le livreur sur un colis.
class ApiCommission {
  const ApiCommission({
    required this.id,
    required this.parcelId,
    required this.amount,
    this.billingCycleId,
  });

  factory ApiCommission.fromJson(Map<String, dynamic> json) => ApiCommission(
        id: _toInt(json['id']),
        parcelId: _toInt(json['parcel_id']),
        amount: _toDouble(json['amount']),
        billingCycleId:
            json['billing_cycle_id'] == null ? null : _toInt(json['billing_cycle_id']),
      );

  final int id;
  final int parcelId;
  final double amount;
  final int? billingCycleId;
}

/// Cycle de facturation mensuel d'un livreur.
class ApiBillingCycle {
  const ApiBillingCycle({
    required this.id,
    required this.periodStart,
    required this.periodEnd,
    required this.totalAmount,
    required this.status,
  });

  factory ApiBillingCycle.fromJson(Map<String, dynamic> json) =>
      ApiBillingCycle(
        id: _toInt(json['id']),
        periodStart: _toDate(json['period_start']),
        periodEnd: _toDate(json['period_end']),
        totalAmount: _toDouble(json['total_amount']),
        status: _toText(json['status']),
      );

  final int id;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final double totalAmount;
  final String status;
}

/// Réponse de `GET /livreur/commissions`.
class ApiCommissions {
  const ApiCommissions({
    required this.commissions,
    required this.cycles,
    required this.meta,
  });

  factory ApiCommissions.fromJson(dynamic json) {
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};
    final rawCommissions = map['commissions'];
    final rawCycles = map['billing_cycles'];
    final meta = map['meta'];
    return ApiCommissions(
      commissions: [
        if (rawCommissions is List)
          for (final item in rawCommissions)
            if (item is Map<String, dynamic>) ApiCommission.fromJson(item),
      ],
      cycles: [
        if (rawCycles is List)
          for (final item in rawCycles)
            if (item is Map<String, dynamic>) ApiBillingCycle.fromJson(item),
      ],
      meta: PageMeta.fromJson(meta is Map<String, dynamic> ? meta : null),
    );
  }

  final List<ApiCommission> commissions;
  final List<ApiBillingCycle> cycles;
  final PageMeta meta;

  double get totalOwed =>
      commissions.fold(0, (sum, item) => sum + item.amount);
}

/// Réponse de `GET /routes/optimize` (distance, durée et frais estimés).
class ApiRouteEstimate {
  const ApiRouteEstimate({
    required this.distanceMiles,
    required this.durationMinutes,
    required this.ratePerMile,
    required this.estimatedFeeUsd,
  });

  factory ApiRouteEstimate.fromJson(Map<String, dynamic> json) =>
      ApiRouteEstimate(
        distanceMiles: _toDouble(json['distance_miles']),
        durationMinutes: _toDouble(json['duration_minutes']),
        ratePerMile: _toDouble(json['rate_per_mile']),
        estimatedFeeUsd: _toDouble(json['estimated_fee_usd']),
      );

  final double distanceMiles;
  final double durationMinutes;
  final double ratePerMile;
  final double estimatedFeeUsd;
}
