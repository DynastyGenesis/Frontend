// Vérifie l'assemblage des adaptateurs (Stripe, GPS, push, session) dans AppServices.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:barrel_go/core/app_config.dart';
import 'package:barrel_go/data/app_services.dart';
import 'package:barrel_go/data/auth/auth_session.dart';
import 'package:barrel_go/features/driver/location_provider.dart';
import 'package:barrel_go/features/driver_flow.dart';
import 'package:barrel_go/features/notifications/push_registrar.dart';
import 'package:barrel_go/features/payment/card_payment_launcher.dart';

const config = AppConfig(
  apiBaseUrl: 'https://api.test/api/v1',
  supabaseUrl: 'https://x.supabase.co',
  supabaseKey: 'sb_publishable_x',
);

class FakeSource implements PushTokenSource {
  @override
  String get platform => 'android';
  @override
  Future<String?> currentToken() async => 'jeton-appareil';
  @override
  Stream<String> get onTokenRefresh => const Stream.empty();
}

class FakeLocation implements LocationProvider {
  @override
  Future<GeoPoint?> current() async => const GeoPoint(33.7, -84.3);
}

class FakeLauncher implements CardPaymentLauncher {
  @override
  Future<CardPaymentOutcome> confirm(String clientSecret) async =>
      const CardPaymentOutcome(CardPaymentStatus.succeeded);
}

void main() {
  tearDown(() => AppServices.instance = null);

  Future<List<http.Request>> start({bool signedIn = true}) async {
    final calls = <http.Request>[];
    final store = MemorySessionStore();
    if (signedIn) {
      await store.save(AuthSession(
        accessToken: 'jeton',
        refreshToken: 'r',
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
        userId: '11111111-1111-4111-8111-111111111111',
      ));
    }
    await AppServices.initialize(
      config: config,
      store: store,
      httpClient: MockClient((request) async {
        calls.add(request);
        return http.Response(jsonEncode({'message': 'Token enregistré.'}), 200,
            headers: {'content-type': 'application/json'});
      }),
      launcher: FakeLauncher(),
      location: FakeLocation(),
      pushSource: FakeSource(),
    );
    return calls;
  }

  test('au démarrage, une session ouverte enregistre le jeton push', () async {
    final calls = await start();
    final push = calls.singleWhere((r) => r.url.path.endsWith('/notifications/subscribe'));
    expect(jsonDecode(push.body), {'token': 'jeton-appareil', 'platform': 'android'});
    expect(push.headers['Authorization'], 'Bearer jeton');
  });

  test('sans session, aucun jeton push n’est envoyé', () async {
    final calls = await start(signedIn: false);
    expect(calls, isEmpty);
    await AppServices.instance!.startPush();
    expect(calls, isEmpty);
  });

  test('le GPS et le paiement fournis sont ceux de l’application', () async {
    await start();
    final services = AppServices.instance!;
    expect(services.hasLocation, isTrue);
    expect(services.launcher, isA<FakeLauncher>());
  });

  test('sans Firebase, Stripe ni GPS fourni, les valeurs par défaut sont sûres',
      () async {
    await AppServices.initialize(config: config, store: MemorySessionStore());
    final services = AppServices.instance!;
    expect(services.launcher, isA<UnavailableCardPaymentLauncher>());
    await services.startPush();
  });

  testWidgets('le menu livreur propose l’arrivée d’un colis', (tester) async {
    await start();
    await tester.pumpWidget(const MaterialApp(home: DriverBackendMenuScreen()));
    expect(find.text('Arrivée d’un colis'), findsOneWidget);
    await tester.tap(find.text('Arrivée d’un colis'));
    await tester.pumpAndSettle();
    expect(find.text('Numéro du colis'), findsOneWidget);
  });
}
