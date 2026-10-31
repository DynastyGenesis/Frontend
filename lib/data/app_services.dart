import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../core/app_config.dart';
import 'api/api_client.dart';
import 'auth/auth_service.dart';
import 'auth/auth_session.dart';
import 'auth/secure_session_store.dart';
import 'services/backend_api.dart';
import '../features/driver/geolocator_location_provider.dart';
import '../features/driver/location_provider.dart';
import '../features/notifications/firebase_push_token_source.dart';
import '../features/notifications/push_registrar.dart';
import '../features/payment/card_payment_launcher.dart';
import '../features/payment/stripe_card_payment_launcher.dart';

/// Point d'entrée unique vers l'authentification et l'API.
///
/// `AppServices.instance` vaut null quand le backend n'est pas configuré :
/// l'application affiche alors une page de configuration.
class AppServices {
  AppServices._(this.config, this.auth, this.client, this.api, this.launcher,
      this.location, this._pushSource);

  static AppServices? instance;

  /// Espace (`client` ou `driver`) demandé avant la redirection Google, quand
  /// l'application vient d'être rouverte après une connexion Google réussie.
  static String? oauthReturnSpace;

  final AppConfig config;
  final AuthService auth;
  final ApiClient client;
  final BackendApi api;

  /// Paiement par carte (Stripe). Indisponible sans clé publique ni mobile.
  final CardPaymentLauncher launcher;

  /// Position GPS de l'appareil pour le livreur.
  final LocationProvider location;

  final PushTokenSource? _pushSource;
  PushRegistrar? _push;

  /// Vrai quand une vraie source de position est branchée.
  bool get hasLocation => location is! NoLocationProvider;

  /// Enregistre le jeton de notification de l'appareil auprès du backend.
  /// À appeler après chaque connexion ; sans effet si Firebase n'est pas
  /// configuré ou si personne n'est connecté.
  Future<void> startPush() async {
    final source = _pushSource;
    if (source == null || !auth.isSignedIn) return;
    _push ??= PushRegistrar(api, source);
    await _push!.start();
  }

  /// Prépare les services si le backend est configuré.
  static Future<void> initialize({
    AppConfig config = AppConfig.current,
    SessionStore? store,
    http.Client? httpClient,
    CardPaymentLauncher? launcher,
    LocationProvider? location,
    PushTokenSource? pushSource,
  }) async {
    if (!config.useBackend) {
      instance = null;
      return;
    }
    final auth = AuthService(
      config: config,
      store: store ?? SecureSessionStore(),
      client: httpClient,
    );
    if (kIsWeb && await auth.completeOAuthRedirect(Uri.base)) {
      oauthReturnSpace =
          Uri.base.queryParameters['space'] == 'driver' ? 'driver' : 'client';
    } else {
      await auth.restore();
    }
    final client = ApiClient(
      baseUrl: config.apiBaseUrl,
      client: httpClient,
      tokenProvider: auth.accessToken,
      onUnauthorized: auth.refresh,
    );
    instance = AppServices._(
      config,
      auth,
      client,
      BackendApi(client),
      launcher ?? await StripeCardPaymentLauncher.create(config),
      location ?? const GeolocatorLocationProvider(),
      pushSource ?? await FirebasePushTokenSource.create(config),
    );
    await instance!.startPush();
  }
}
