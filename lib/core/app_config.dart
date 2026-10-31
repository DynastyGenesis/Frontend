/// Configuration de connexion au backend.
///
/// Les valeurs sont fournies à la compilation, par exemple :
/// `flutter run --dart-define=API_BASE_URL=https://api.exemple.com/api/v1
///  --dart-define=SUPABASE_URL=https://xxxx.supabase.co
///  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_xxx`
///
/// Sans ces valeurs, l'application n'affiche qu'une page de configuration.
/// Aucune clé secrète ne doit être placée ici : seule la clé publique Supabase
/// (publishable) est utilisée côté application.
class AppConfig {
  const AppConfig({
    this.apiBaseUrl = '',
    this.supabaseUrl = '',
    this.supabaseKey = '',
    this.stripePublishableKey = '',
    this.firebase = const FirebaseConfig(),
  });

  static const AppConfig current = AppConfig(
    apiBaseUrl: String.fromEnvironment('API_BASE_URL'),
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabaseKey: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
    stripePublishableKey: String.fromEnvironment('STRIPE_PUBLISHABLE_KEY'),
    firebase: FirebaseConfig(
      apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
      androidAppId: String.fromEnvironment('FIREBASE_ANDROID_APP_ID'),
      iosAppId: String.fromEnvironment('FIREBASE_IOS_APP_ID'),
      webAppId: String.fromEnvironment('FIREBASE_WEB_APP_ID'),
      messagingSenderId: String.fromEnvironment('FIREBASE_SENDER_ID'),
      projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
      vapidKey: String.fromEnvironment('FIREBASE_VAPID_KEY'),
    ),
  );

  /// Base de l'API Laravel, préfixe `/api/v1` inclus.
  final String apiBaseUrl;

  /// URL du projet Supabase (service d'authentification).
  final String supabaseUrl;

  /// Clé publique (publishable) du projet Supabase.
  final String supabaseKey;

  /// Clé publique Stripe (`pk_...`). Vide : le paiement par carte reste masqué.
  final String stripePublishableKey;

  /// Projet Firebase pour les notifications push. Facultatif.
  final FirebaseConfig firebase;

  /// Vrai seulement si les trois valeurs sont renseignées.
  bool get useBackend =>
      apiBaseUrl.isNotEmpty && supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;

  bool get hasStripe => stripePublishableKey.startsWith('pk_');
}

/// Identifiants publics d'une application Firebase (aucun secret).
///
/// Ils remplacent `google-services.json` / `GoogleService-Info.plist`.
/// Seul l'identifiant d'application change d'une plateforme à l'autre.
class FirebaseConfig {
  const FirebaseConfig({
    this.apiKey = '',
    this.androidAppId = '',
    this.iosAppId = '',
    this.webAppId = '',
    this.messagingSenderId = '',
    this.projectId = '',
    this.vapidKey = '',
  });

  final String apiKey;
  final String androidAppId;
  final String iosAppId;
  final String webAppId;
  final String messagingSenderId;
  final String projectId;

  /// Clé VAPID, nécessaire uniquement pour les notifications web.
  final String vapidKey;

  /// Identifiant d'application pour `platform` (`android`, `ios` ou `web`).
  String appIdFor(String platform) => switch (platform) {
        'android' => androidAppId,
        'ios' => iosAppId,
        'web' => webAppId,
        _ => '',
      };

  bool isCompleteFor(String platform) =>
      apiKey.isNotEmpty &&
      appIdFor(platform).isNotEmpty &&
      messagingSenderId.isNotEmpty &&
      projectId.isNotEmpty &&
      (platform != 'web' || vapidKey.isNotEmpty);
}
