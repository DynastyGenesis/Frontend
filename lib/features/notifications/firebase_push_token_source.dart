// Jeton de notification push fourni par Firebase Cloud Messaging.
//
// Firebase est initialisé à partir des valeurs `FIREBASE_*` de la configuration
// (aucun fichier google-services.json n'est nécessaire). Créé par
// `AppServices`, qui enregistre le jeton après la connexion (`startPush`).
//
// iOS : activer « Push Notifications » et « Background Modes > Remote
// notifications » dans Xcode, et déposer la clé APNs dans la console Firebase.
// Web : ajouter `web/firebase-messaging-sw.js` avec les mêmes identifiants.
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../core/app_config.dart';
import 'push_registrar.dart';

class FirebasePushTokenSource implements PushTokenSource {
  FirebasePushTokenSource._(this.platform, this._vapidKey);

  @override
  final String platform;
  final String _vapidKey;

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  /// Plateforme au sens du backend, ou null si non prise en charge.
  static String? currentPlatform() {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => null,
    };
  }

  /// Initialise Firebase. Renvoie null si la configuration manque, si la
  /// plateforme n'est pas prise en charge ou si l'initialisation échoue :
  /// l'application fonctionne alors sans notifications push.
  static Future<FirebasePushTokenSource?> create(AppConfig config) async {
    final platform = currentPlatform();
    final firebase = config.firebase;
    if (platform == null || !firebase.isCompleteFor(platform)) return null;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: firebase.apiKey,
            appId: firebase.appIdFor(platform),
            messagingSenderId: firebase.messagingSenderId,
            projectId: firebase.projectId,
          ),
        );
      }
      return FirebasePushTokenSource._(platform, firebase.vapidKey);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> currentToken() async {
    try {
      final settings = await _messaging.requestPermission();
      final status = settings.authorizationStatus;
      if (status != AuthorizationStatus.authorized &&
          status != AuthorizationStatus.provisional) {
        return null;
      }
      // `getToken` est déprécié au profit de `register()`, qui fournit un
      // identifiant d'installation (FID). Le backend envoie avec le jeton FCM
      // (`CloudMessage::withToken`) : on garde ce jeton tant qu'il n'évolue pas.
      // ignore: deprecated_member_use
      return await _messaging.getToken(
          vapidKey: platform == 'web' ? _vapidKey : null);
    } catch (_) {
      return null;
    }
  }

  @override
  // ignore: deprecated_member_use
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;
}
