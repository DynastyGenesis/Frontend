// Modèle du tirage au sort mensuel (routes `/raffle/current` et `/raffle/history`).
// Même tolérance que api_models.dart : valeur absente = valeur par défaut.

double _toDouble(dynamic value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
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

String? _toTextOrNull(dynamic value) => value is String ? value : null;

/// Tirage au sort mensuel d'un État (`GET /raffle/current`, `/raffle/history`).
/// Avant le tirage, `id`, `winnerUserId`, `amountRefunded` et `drawnAt` sont nuls.
class ApiRaffleDraw {
  const ApiRaffleDraw({
    this.id,
    required this.state,
    this.periodStart,
    this.periodEnd,
    this.winnerUserId,
    this.amountRefunded,
    this.drawnAt,
  });

  factory ApiRaffleDraw.fromJson(Map<String, dynamic> json) => ApiRaffleDraw(
        id: _toIntOrNull(json['id']),
        state: _toText(json['state']),
        periodStart: _toDate(json['period_start']),
        periodEnd: _toDate(json['period_end']),
        winnerUserId: _toTextOrNull(json['winner_user_id']),
        amountRefunded: json['amount_refunded'] == null
            ? null
            : _toDouble(json['amount_refunded']),
        drawnAt: _toDate(json['drawn_at']),
      );

  final int? id;
  final String state;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final String? winnerUserId;
  final double? amountRefunded;
  final DateTime? drawnAt;

  bool get isDrawn => drawnAt != null;
}
