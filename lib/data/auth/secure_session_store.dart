// Session Supabase dans le stockage sécurisé du système.
//
// Android : Keystore ; iOS/macOS : Keychain ; web : chiffrement WebCrypto.
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_session.dart';

class SecureSessionStore implements SessionStore {
  SecureSessionStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'barelgo_auth_session';

  final FlutterSecureStorage _storage;

  @override
  Future<AuthSession?> load() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          return AuthSession.fromJson(Map<String, dynamic>.from(decoded));
        }
      }
    } catch (_) {
      // Stockage illisible (clé système changée, données corrompues) :
      // l'utilisateur se reconnecte simplement.
      await _deleteQuietly();
      return null;
    }
    return null;
  }

  @override
  Future<void> save(AuthSession? session) async {
    if (session == null) {
      await _deleteQuietly();
      return;
    }
    await _storage.write(key: _key, value: jsonEncode(session.toJson()));
  }

  Future<void> _deleteQuietly() async {
    try {
      await _storage.delete(key: _key);
    } catch (_) {
      // Rien à effacer.
    }
  }
}
