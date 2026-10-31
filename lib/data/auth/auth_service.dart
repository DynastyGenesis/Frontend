import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/app_config.dart';
import '../api/api_exception.dart';
import 'auth_session.dart';

/// Résultat d'une inscription.
class SignUpResult {
  const SignUpResult(this.session);

  /// Null quand le projet Supabase exige la confirmation de l'e-mail.
  final AuthSession? session;

  bool get needsEmailConfirmation => session == null;
}

/// Authentification via l'API REST de Supabase Auth (GoTrue).
///
/// Le backend Laravel ne gère ni inscription ni connexion : il valide
/// seulement le jeton émis ici. Le nom complet est envoyé dans
/// `user_metadata.full_name`, que le backend lit à la première requête.
class AuthService {
  AuthService({
    required AppConfig config,
    required this.store,
    http.Client? client,
    DateTime Function()? clock,
  })  : _base = config.supabaseUrl.replaceAll(RegExp(r'/+$'), ''),
        _key = config.supabaseKey,
        _client = client ?? http.Client(),
        _clock = clock ?? DateTime.now;

  final String _base;
  final String _key;
  final SessionStore store;
  final http.Client _client;
  final DateTime Function() _clock;

  AuthSession? _session;
  Future<bool>? _refreshing;

  AuthSession? get session => _session;
  bool get isSignedIn => _session != null;

  /// Recharge la session enregistrée et la renouvelle si elle a expiré.
  Future<void> restore() async {
    _session = await store.load();
    final current = _session;
    if (current != null && current.isExpiring(_clock())) {
      await refresh();
    }
  }

  /// Jeton valide à joindre aux requêtes, renouvelé si nécessaire.
  Future<String?> accessToken() async {
    final current = _session;
    if (current == null) return null;
    if (current.isExpiring(_clock())) await refresh();
    return _session?.accessToken;
  }

  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final json = await _post(
      '/auth/v1/signup',
      {
        'email': email.trim(),
        'password': password,
        'data': {'full_name': name.trim()},
      },
    );
    final session = _sessionFrom(json);
    if (session != null) await _setSession(session);
    return SignUpResult(session);
  }

  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    final json = await _post(
      '/auth/v1/token',
      {'email': email.trim(), 'password': password},
      query: {'grant_type': 'password'},
    );
    final session = _sessionFrom(json);
    if (session == null) {
      throw const ApiException('Connexion impossible pour le moment.');
    }
    await _setSession(session);
    return session;
  }

  /// Adresse Supabase qui lance la connexion Google puis renvoie vers
  /// [redirectTo] avec les jetons dans le fragment de l'URL.
  Uri googleSignInUrl(String redirectTo) =>
      Uri.parse('$_base/auth/v1/authorize').replace(
        queryParameters: {'provider': 'google', 'redirect_to': redirectTo},
      );

  /// Termine une connexion OAuth si [uri] est un retour de Supabase
  /// (jetons dans le fragment). Renvoie vrai quand une session a été créée.
  Future<bool> completeOAuthRedirect(Uri uri) async {
    if (!uri.hasFragment) return false;
    final Map<String, String> params;
    try {
      params = Uri.splitQueryString(uri.fragment);
    } catch (_) {
      return false;
    }
    final access = params['access_token'];
    if (access == null || access.isEmpty) return false;
    final expiresIn = int.tryParse(params['expires_in'] ?? '') ?? 3600;
    final claims = _jwtClaims(access);
    await _setSession(AuthSession(
      accessToken: access,
      refreshToken: params['refresh_token'] ?? '',
      expiresAt: _clock().toUtc().add(Duration(seconds: expiresIn)),
      userId: claims['sub'] as String?,
      email: claims['email'] as String?,
    ));
    return true;
  }

  Map<String, dynamic> _jwtClaims(String token) {
    try {
      final parts = token.split('.');
      final payload = utf8.decode(base64Url.decode(
        base64Url.normalize(parts[1]),
      ));
      final value = jsonDecode(payload);
      return value is Map<String, dynamic> ? value : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  /// Renouvelle le jeton. Une seule requête à la fois.
  Future<bool> refresh() {
    return _refreshing ??= _doRefresh().whenComplete(() {
      _refreshing = null;
    });
  }

  Future<bool> _doRefresh() async {
    final current = _session;
    if (current == null || current.refreshToken.isEmpty) return false;
    try {
      final json = await _post(
        '/auth/v1/token',
        {'refresh_token': current.refreshToken},
        query: {'grant_type': 'refresh_token'},
      );
      final renewed = _sessionFrom(json);
      if (renewed == null) {
        await _setSession(null);
        return false;
      }
      await _setSession(renewed);
      return true;
    } on ApiException catch (error) {
      // Refus définitif : la session n'est plus valable. Une panne réseau
      // laisse la session en place pour un nouvel essai.
      if (!error.isNetwork) await _setSession(null);
      return false;
    }
  }

  Future<void> requestPasswordReset(String email) async {
    await _post('/auth/v1/recover', {'email': email.trim()});
  }

  Future<void> signOut() async {
    final current = _session;
    await _setSession(null);
    if (current == null) return;
    try {
      await _post('/auth/v1/logout', const <String, dynamic>{},
          bearer: current.accessToken);
    } catch (_) {
      // La déconnexion locale suffit si le serveur est injoignable.
    }
  }

  Future<void> _setSession(AuthSession? session) async {
    _session = session;
    await store.save(session);
  }

  AuthSession? _sessionFrom(Map<String, dynamic> json) {
    final access = json['access_token'];
    if (access is! String || access.isEmpty) return null;
    final now = _clock().toUtc();
    final expiresAtSeconds = json['expires_at'];
    final expiresIn = json['expires_in'];
    final expiresAt = expiresAtSeconds is num
        ? DateTime.fromMillisecondsSinceEpoch(
            expiresAtSeconds.toInt() * 1000,
            isUtc: true,
          )
        : now.add(Duration(seconds: expiresIn is num ? expiresIn.toInt() : 3600));
    final user = json['user'];
    return AuthSession(
      accessToken: access,
      refreshToken: '${json['refresh_token'] ?? ''}',
      expiresAt: expiresAt,
      userId: user is Map ? user['id'] as String? : null,
      email: user is Map ? user['email'] as String? : null,
    );
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    Map<String, String>? query,
    String? bearer,
  }) async {
    final uri = Uri.parse('$_base$path').replace(queryParameters: query);
    final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {
              'apikey': _key,
              'Content-Type': 'application/json',
              if (bearer != null) 'Authorization': 'Bearer $bearer',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const ApiException(
        'Le service de connexion met trop de temps à répondre.',
      );
    } catch (_) {
      throw const ApiException(
        'Connexion au serveur impossible. Vérifiez votre connexion Internet.',
      );
    }

    final decoded = _decode(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    throw _errorFrom(response.statusCode, decoded);
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.bodyBytes.isEmpty) return <String, dynamic>{};
    try {
      final value = jsonDecode(utf8.decode(response.bodyBytes));
      return value is Map<String, dynamic> ? value : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  ApiException _errorFrom(int status, Map<String, dynamic> json) {
    final code = '${json['error_code'] ?? json['code'] ?? json['error'] ?? ''}';
    final message = switch (code) {
      'invalid_credentials' ||
      'invalid_grant' =>
        'Adresse e-mail ou mot de passe incorrect.',
      'user_already_exists' ||
      'email_exists' =>
        'Un compte existe déjà avec cette adresse e-mail.',
      'email_not_confirmed' =>
        'Confirmez votre adresse e-mail avant de vous connecter.',
      'weak_password' =>
        'Mot de passe trop faible. Choisissez-en un plus long.',
      'over_request_rate_limit' ||
      'over_email_send_rate_limit' =>
        'Trop de tentatives. Réessayez dans quelques minutes.',
      'signup_disabled' =>
        'Les inscriptions sont désactivées pour le moment.',
      _ => status == 429
          ? 'Trop de tentatives. Réessayez dans quelques minutes.'
          : 'Opération impossible pour le moment. Réessayez plus tard.',
    };
    return ApiException(message, statusCode: status);
  }
}
