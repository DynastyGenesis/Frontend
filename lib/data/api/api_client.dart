import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

/// Fournit le jeton d'accès courant (ou null si personne n'est connecté).
typedef TokenProvider = Future<String?> Function();

/// Appelée sur une réponse 401. Renvoie true si le jeton a pu être renouvelé,
/// auquel cas la requête est rejouée une seule fois.
typedef UnauthorizedHandler = Future<bool> Function();

/// Client HTTP JSON pour l'API Laravel.
///
/// - ajoute `Authorization: Bearer <jeton>` ;
/// - décode toujours le corps en UTF-8 (les messages sont en français) ;
/// - transforme les erreurs réseau et HTTP en [ApiException] ;
/// - rejoue une fois la requête après un renouvellement de jeton sur 401.
class ApiClient {
  ApiClient({
    required String baseUrl,
    http.Client? client,
    this.tokenProvider,
    this.onUnauthorized,
    this.timeout = const Duration(seconds: 20),
  })  : baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
        _client = client ?? http.Client();

  final String baseUrl;
  final TokenProvider? tokenProvider;
  final UnauthorizedHandler? onUnauthorized;
  final Duration timeout;
  final http.Client _client;

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
    bool auth = true,
  }) =>
      _send('GET', path, query: query, auth: auth);

  Future<dynamic> post(
    String path, {
    Object? body,
    bool auth = true,
  }) =>
      _send('POST', path, body: body, auth: auth);

  Future<dynamic> patch(
    String path, {
    Object? body,
    bool auth = true,
  }) =>
      _send('PATCH', path, body: body, auth: auth);

  /// Envoie un fichier en `multipart/form-data` (ex. documents d'un colis).
  /// Le type MIME est contrôlé par le backend à partir du contenu du fichier.
  Future<dynamic> postFile(
    String path, {
    required String fileField,
    required List<int> bytes,
    required String filename,
    Map<String, String> fields = const {},
    bool retried = false,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (tokenProvider != null) {
      final token = await tokenProvider!();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    final http.Response response;
    try {
      final request = http.MultipartRequest('POST', _uri(path, null))
        ..headers.addAll(headers)
        ..fields.addAll(fields)
        ..files.add(http.MultipartFile.fromBytes(fileField, bytes,
            filename: filename));
      final streamed = await _client.send(request).timeout(timeout * 3);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const ApiException(
        'L’envoi du fichier prend trop de temps. Réessayez avec une meilleure connexion.',
      );
    } catch (_) {
      throw const ApiException(
        'Connexion au serveur impossible. Vérifiez votre connexion Internet.',
      );
    }

    if (response.statusCode == 401 && !retried && onUnauthorized != null) {
      if (await onUnauthorized!()) {
        return postFile(path,
            fileField: fileField,
            bytes: bytes,
            filename: filename,
            fields: fields,
            retried: true);
      }
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decode(response);
    }
    throw _errorFrom(response);
  }

  Uri _uri(String path, Map<String, dynamic>? query) {
    final clean = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$baseUrl$clean');
    if (query == null || query.isEmpty) return uri;
    final params = <String, String>{
      ...uri.queryParameters,
      for (final entry in query.entries)
        if (entry.value != null) entry.key: '${entry.value}',
    };
    return uri.replace(queryParameters: params);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    bool auth = true,
    bool retried = false,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json';
    if (auth && tokenProvider != null) {
      final token = await tokenProvider!();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    final http.Response response;
    try {
      final request = http.Request(method, _uri(path, query))
        ..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      final streamed = await _client.send(request).timeout(timeout);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const ApiException(
        'Le serveur met trop de temps à répondre. Réessayez dans un instant.',
      );
    } catch (_) {
      throw const ApiException(
        'Connexion au serveur impossible. Vérifiez votre connexion Internet.',
      );
    }

    if (response.statusCode == 401 &&
        auth &&
        !retried &&
        onUnauthorized != null) {
      final renewed = await onUnauthorized!();
      if (renewed) {
        return _send(
          method,
          path,
          query: query,
          body: body,
          auth: auth,
          retried: true,
        );
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _decode(response);
    }
    throw _errorFrom(response);
  }

  dynamic _decode(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      throw ApiException(
        'Réponse inattendue du serveur.',
        statusCode: response.statusCode,
      );
    }
  }

  ApiException _errorFrom(http.Response response) {
    String? serverMessage;
    final fieldErrors = <String, List<String>>{};
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) {
          serverMessage = message.trim();
        }
        final errors = decoded['errors'];
        if (errors is Map) {
          errors.forEach((key, value) {
            if (value is List) {
              fieldErrors['$key'] = [for (final item in value) '$item'];
            } else if (value != null) {
              fieldErrors['$key'] = ['$value'];
            }
          });
        }
      }
    } catch (_) {
      // Corps absent ou non JSON : le message par défaut s'applique.
    }

    final status = response.statusCode;
    return ApiException(
      serverMessage ?? _defaultMessage(status),
      statusCode: status,
      fieldErrors: fieldErrors,
      retryAfterSeconds: int.tryParse(response.headers['retry-after'] ?? ''),
    );
  }

  static String _defaultMessage(int status) => switch (status) {
        401 => 'Session expirée. Reconnectez-vous.',
        403 => 'Action non autorisée.',
        404 => 'Élément introuvable.',
        409 => 'Action impossible dans l’état actuel.',
        422 => 'Les données envoyées ne sont pas valides.',
        429 => 'Trop de requêtes. Réessayez dans un instant.',
        503 => 'Service momentanément indisponible.',
        _ => 'Une erreur est survenue côté serveur.',
      };

  void close() => _client.close();
}
