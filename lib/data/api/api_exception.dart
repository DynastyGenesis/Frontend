/// Erreur renvoyée par le backend ou par le réseau.
///
/// `statusCode` vaut null quand la requête n'a pas atteint le serveur
/// (pas de réseau, délai dépassé).
class ApiException implements Exception {
  const ApiException(
    this.message, {
    this.statusCode,
    this.fieldErrors = const {},
    this.retryAfterSeconds,
  });

  final String message;
  final int? statusCode;

  /// Erreurs par champ (réponse 422), messages déjà en français.
  final Map<String, List<String>> fieldErrors;

  /// Valeur de l'en-tête Retry-After (réponse 429), en secondes.
  final int? retryAfterSeconds;

  bool get isNetwork => statusCode == null;
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;
  bool get isValidation => statusCode == 422;
  bool get isRateLimited => statusCode == 429;
  bool get isUnavailable => statusCode == 503;

  /// Message prêt à afficher : le premier message de champ s'il existe.
  String get displayMessage {
    for (final messages in fieldErrors.values) {
      if (messages.isNotEmpty) return messages.first;
    }
    return message;
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
