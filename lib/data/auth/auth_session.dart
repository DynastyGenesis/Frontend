/// Session d'authentification Supabase conservée sur l'appareil.
class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    this.userId,
    this.email,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        accessToken: '${json['access_token']}',
        refreshToken: '${json['refresh_token'] ?? ''}',
        expiresAt: DateTime.tryParse('${json['expires_at']}')?.toUtc() ??
            DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        userId: json['user_id'] as String?,
        email: json['email'] as String?,
      );

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final String? userId;
  final String? email;

  /// Vrai quand le jeton expire dans moins de 30 secondes.
  bool isExpiring(DateTime now) =>
      now.toUtc().isAfter(expiresAt.subtract(const Duration(seconds: 30)));

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'expires_at': expiresAt.toUtc().toIso8601String(),
        'user_id': userId,
        'email': email,
      };
}

/// Stockage de la session. Remplaçable dans les tests.
abstract class SessionStore {
  Future<AuthSession?> load();
  Future<void> save(AuthSession? session);
}

/// Stockage en mémoire (tests).
class MemorySessionStore implements SessionStore {
  AuthSession? _session;

  @override
  Future<AuthSession?> load() async => _session;

  @override
  Future<void> save(AuthSession? session) async => _session = session;
}
