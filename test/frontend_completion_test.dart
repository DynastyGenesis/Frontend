// Tests des éléments ajoutés le 28 octobre 2026, encore non assemblés :
// stockage sécurisé de la session, modification d'une réservation, arrivée
// d'un colis, configuration Stripe/Firebase et adaptateurs sans configuration.
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:barrel_go/core/app_config.dart';
import 'package:barrel_go/data/api/api_client.dart';
import 'package:barrel_go/data/auth/auth_session.dart';
import 'package:barrel_go/data/auth/secure_session_store.dart';
import 'package:barrel_go/data/models/api_models.dart';
import 'package:barrel_go/data/services/backend_api.dart';
import 'package:barrel_go/features/driver/parcel_arrival.dart';
import 'package:barrel_go/features/notifications/firebase_push_token_source.dart';
import 'package:barrel_go/features/payment/card_payment_launcher.dart';
import 'package:barrel_go/features/payment/stripe_card_payment_launcher.dart';
import 'package:barrel_go/features/reservation/edit_reservation.dart';
import 'package:barrel_go/features/reservation/reservation_controller.dart';

http.Response json(Object body, [int status = 200]) => http.Response.bytes(
    utf8.encode(jsonEncode(body)), status,
    headers: {'content-type': 'application/json'});

BackendApi apiWith(Future<http.Response> Function(http.Request) handler) =>
    BackendApi(ApiClient(
      baseUrl: 'https://api.test/api/v1',
      client: MockClient(handler),
    ));

Map<String, dynamic> pickupJson({String status = 'pending'}) => {
      'id': 12,
      'client_id': '11111111-1111-4111-8111-111111111111',
      'driver_id': null,
      'pickup_address': '10 Main St, Atlanta',
      'scheduled_window_start': '2026-11-02T09:00:00-05:00',
      'scheduled_window_end': '2026-11-02T11:00:00-05:00',
      'driver_reported': false,
      'status': status,
    };

final session = AuthSession(
  accessToken: 'jeton',
  refreshToken: 'renouvellement',
  expiresAt: DateTime.utc(2030),
  userId: '11111111-1111-4111-8111-111111111111',
  email: 'client@exemple.com',
);

void main() {
  reservationRecipientTests();

  group('SecureSessionStore', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
    });

    test('enregistre, relit puis efface la session', () async {
      final store = SecureSessionStore();
      expect(await store.load(), isNull);
      await store.save(session);
      final loaded = await store.load();
      expect(loaded?.accessToken, 'jeton');
      expect(loaded?.email, 'client@exemple.com');
      await store.save(null);
      expect(await store.load(), isNull);
    });

    test('une valeur illisible donne une session vide', () async {
      FlutterSecureStorage.setMockInitialValues(
          {'barelgo_auth_session': 'pas du json'});
      expect(await SecureSessionStore().load(), isNull);
    });
  });

  group('EditReservationController', () {
    test('n’envoie que l’adresse modifiée', () async {
      Map<String, dynamic>? sent;
      final api = apiWith((request) async {
        expect(request.method, 'PATCH');
        expect(request.url.path, '/api/v1/reservations/12');
        sent = jsonDecode(request.body) as Map<String, dynamic>;
        return json({...pickupJson(), 'pickup_address': sent!['pickup_address']});
      });
      final c = EditReservationController(api, ApiPickup.fromJson(pickupJson()));
      expect(c.hasChanges, isFalse);
      c.setAddress('  22 Peachtree St, Atlanta ');
      final updated = await c.save();
      expect(sent, {'pickup_address': '22 Peachtree St, Atlanta'});
      expect(updated?.address, '22 Peachtree St, Atlanta');
      c.dispose();
    });

    test('envoie le créneau choisi tel que reçu du backend', () async {
      Map<String, dynamic>? sent;
      final api = apiWith((request) async {
        sent = jsonDecode(request.body) as Map<String, dynamic>;
        return json(pickupJson());
      });
      final c = EditReservationController(api, ApiPickup.fromJson(pickupJson()));
      c.slots.select(ApiSlot.fromJson(const {
        'window_start': '2026-11-03T13:00:00-05:00',
        'window_end': '2026-11-03T15:00:00-05:00',
      }));
      await c.save();
      expect(sent, {
        'scheduled_window_start': '2026-11-03T13:00:00-05:00',
        'scheduled_window_end': '2026-11-03T15:00:00-05:00',
      });
      c.dispose();
    });

    test('refuse localement une réservation déjà affectée', () async {
      var calls = 0;
      final api = apiWith((_) async {
        calls++;
        return json({});
      });
      final c = EditReservationController(
          api, ApiPickup.fromJson(pickupJson(status: 'assigned')));
      c.setAddress('Autre adresse');
      expect(c.canEdit, isFalse);
      expect(await c.save(), isNull);
      expect(calls, 0);
      expect(c.error, contains('livreur'));
      c.dispose();
    });

    test('affiche le message du backend en cas de refus', () async {
      final api = apiWith((_) async => json({
            'message': 'Ce champ ne peut plus être modifié.',
            'errors': {
              'pickup_address': ['Ce champ ne peut plus être modifié.']
            },
          }, 422));
      final c = EditReservationController(api, ApiPickup.fromJson(pickupJson()));
      c.setAddress('Autre adresse');
      expect(await c.save(), isNull);
      expect(c.failure?.isValidation, isTrue);
      expect(c.error, isNotNull);
      c.dispose();
    });
  });

  group('ParcelArrivalController', () {
    test('lit le numéro saisi', () {
      expect(ParcelArrivalController.parseNumber('1042'), 1042);
      expect(ParcelArrivalController.parseNumber('#1042'), 1042);
      expect(ParcelArrivalController.parseNumber('colis 7'), 7);
      expect(ParcelArrivalController.parseNumber('abc'), isNull);
      expect(ParcelArrivalController.parseNumber('0'), isNull);
      expect(ParcelArrivalController.parseNumber('1' * 19), isNull);
    });

    test('déclare l’arrivée et garde le colis dans la liste', () async {
      final api = apiWith((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/shipments/1042/arrive');
        return json({
          'id': 1042,
          'pickup_id': 12,
          'recipient_user_id': '22222222-2222-4222-8222-222222222222',
          'weight_kg': '10.00',
          'self_dropoff': false,
          'status': 'arrived',
        });
      });
      final c = ParcelArrivalController(api);
      final parcel = await c.declare('#1042');
      expect(parcel?.status, 'arrived');
      expect(c.declared.single.id, 1042);
    });

    test('explique un colis qui n’est pas en transit', () async {
      final api = apiWith(
          (_) async => json({'message': "Le colis n'est pas en transit."}, 409));
      final c = ParcelArrivalController(api);
      expect(await c.declare('5'), isNull);
      expect(c.error, contains('n’est pas en transit'));
      expect(c.declared, isEmpty);
    });

    test('explique un colis hors de ses missions', () async {
      final api = apiWith((_) async => json({'message': 'Introuvable'}, 404));
      final c = ParcelArrivalController(api);
      await c.declare('5');
      expect(c.error, contains('ne fait pas partie de vos missions'));
    });

    test('n’appelle pas le serveur sans numéro valide', () async {
      var calls = 0;
      final api = apiWith((_) async {
        calls++;
        return json({});
      });
      final c = ParcelArrivalController(api);
      await c.declare('');
      expect(calls, 0);
      expect(c.error, isNotNull);
    });
  });

  group('Configuration Stripe et Firebase', () {
    test('Stripe exige une clé publique pk_', () {
      expect(const AppConfig().hasStripe, isFalse);
      expect(const AppConfig(stripePublishableKey: 'sk_test_x').hasStripe,
          isFalse);
      expect(const AppConfig(stripePublishableKey: 'pk_test_x').hasStripe,
          isTrue);
    });

    test('Firebase choisit l’identifiant de la plateforme', () {
      const firebase = FirebaseConfig(
        apiKey: 'cle',
        androidAppId: '1:1:android:a',
        iosAppId: '1:1:ios:b',
        messagingSenderId: '1',
        projectId: 'barelgo',
      );
      expect(firebase.appIdFor('android'), '1:1:android:a');
      expect(firebase.appIdFor('ios'), '1:1:ios:b');
      expect(firebase.isCompleteFor('android'), isTrue);
      expect(firebase.isCompleteFor('web'), isFalse);
      expect(const FirebaseConfig().isCompleteFor('android'), isFalse);
    });

    test('sans clé Stripe, le paiement reste indisponible', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        final launcher = await StripeCardPaymentLauncher.create(const AppConfig());
        expect(launcher, isA<UnavailableCardPaymentLauncher>());
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    test('sans configuration Firebase, pas de source de jeton push', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        expect(await FirebasePushTokenSource.create(const AppConfig()), isNull);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}

// ---- Réservation : code destinataire refusé par le backend ----
void reservationRecipientTests() {
  const me = '11111111-1111-4111-8111-111111111111';
  const friend = '22222222-2222-4222-8222-222222222222';
  const unknown = '33333333-3333-4333-8333-333333333333';
  const slot = ApiSlot(
      startIso: '2026-11-02T09:00:00-05:00', endIso: '2026-11-02T11:00:00-05:00');

  group('ReservationController : destinataire inconnu', () {
    test('le colis refusé peut être corrigé puis l’envoi repris', () async {
      var reservations = 0;
      final sentCodes = <String>[];
      final api = apiWith((request) async {
        if (request.url.path.endsWith('/reservations')) {
          reservations++;
          return json({...pickupJson(), 'id': 12}, 201);
        }
        final code = (jsonDecode(request.body) as Map)['recipient_user_id'] as String;
        sentCodes.add(code);
        if (code == unknown) {
          return json({
            'message': 'Le destinataire sélectionné n’existe pas.',
            'errors': {
              'recipient_user_id': ['Le destinataire sélectionné n’existe pas.']
            },
          }, 422);
        }
        return json({
          'id': sentCodes.length,
          'pickup_id': 12,
          'recipient_user_id': code,
          'weight_kg': '2.00',
          'self_dropoff': false,
          'status': 'reserved',
        }, 201);
      });
      final c = ReservationController(api, currentUserId: me);
      c.drafts.first
        ..recipientCode = friend
        ..weightText = '2';
      c.addParcel();
      c.drafts.last
        ..recipientCode = unknown
        ..weightText = '3';
      c.address = '10 Main St, Atlanta';
      c.slots.select(slot);

      expect(await c.submit(), isNull);
      expect(c.error, contains('colis 2'));
      expect(c.error, contains('introuvable'));
      expect(c.hasUnsentParcels, isTrue);
      expect(c.parcelLocked(0), isTrue);
      expect(c.parcelLocked(1), isFalse);

      c.removeParcel(0); // déjà enregistré : refusé
      expect(c.drafts, hasLength(2));

      c.drafts.last.recipientCode = friend;
      expect((await c.submit())?.id, 12);
      expect(reservations, 1);
      expect(sentCodes, [friend, unknown, friend]);
      expect(c.hasUnsentParcels, isFalse);
    });
  });
}
