// NON ASSEMBLÉ. Enregistrement du jeton de notification push (POST /notifications/subscribe).
//
// Le jeton vient de Firebase Cloud Messaging. Firebase n'est pas encore dans le
// projet : à l'assemblage, implémenter [PushTokenSource] avec `firebase_messaging`
// (demande d'autorisation, `getToken()`, `onTokenRefresh`) puis appeler
// `PushRegistrar.start()` après la connexion.
import 'dart:async';

import '../../data/services/backend_api.dart';

abstract class PushTokenSource {
  /// `ios`, `android` ou `web` (valeurs acceptées par le backend).
  String get platform;

  /// Jeton actuel, ou null si l'utilisateur a refusé les notifications.
  Future<String?> currentToken();

  /// Nouveau jeton quand Firebase le renouvelle.
  Stream<String> get onTokenRefresh;
}

class PushRegistrar {
  PushRegistrar(this._api, this._source);

  final BackendApi _api;
  final PushTokenSource _source;
  StreamSubscription<String>? _subscription;
  String? _lastSent;

  /// Enregistre le jeton courant et suit ses renouvellements. Les erreurs
  /// réseau sont silencieuses : l'appel est retenté au prochain démarrage.
  Future<void> start() async {
    await _send(await _source.currentToken());
    _subscription ??= _source.onTokenRefresh.listen(_send);
  }

  Future<void> _send(String? token) async {
    if (token == null || token.isEmpty || token == _lastSent) return;
    try {
      await _api.subscribePush(token: token, platform: _source.platform);
      _lastSent = token;
    } catch (_) {
      // Sans conséquence : réessayé au prochain démarrage.
    }
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
