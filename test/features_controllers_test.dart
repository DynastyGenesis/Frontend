// Tests des contrôleurs de lib/features avec un faux serveur (MockClient).
// Ces contrôleurs ne sont pas encore branchés aux écrans de l'application.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:barrel_go/data/api/api_client.dart';
import 'package:barrel_go/data/models/api_models.dart';
import 'package:barrel_go/data/services/backend_api.dart';
import 'package:barrel_go/features/common/file_picker_port.dart';
import 'package:barrel_go/features/disputes/disputes_controller.dart';
import 'package:barrel_go/features/driver/availability_controller.dart';
import 'package:barrel_go/features/driver/commissions_controller.dart';
import 'package:barrel_go/features/driver/location_provider.dart';
import 'package:barrel_go/features/driver/missions_controller.dart';
import 'package:barrel_go/features/notifications/notification_text.dart';
import 'package:barrel_go/features/notifications/push_registrar.dart';
import 'package:barrel_go/features/payment/card_payment_launcher.dart';
import 'package:barrel_go/features/payment/payment_controller.dart';
import 'package:barrel_go/features/reservation/my_reservations_controller.dart';
import 'package:barrel_go/features/reservation/reservation_controller.dart';
import 'package:barrel_go/features/shipments/shipments_controller.dart';

http.Response json(Object body, [int status = 200]) => http.Response.bytes(
    utf8.encode(jsonEncode(body)), status,
    headers: {'content-type': 'application/json'});

BackendApi apiWith(Future<http.Response> Function(http.Request) handler) =>
    BackendApi(ApiClient(
      baseUrl: 'https://api.test/api/v1',
      client: MockClient(handler),
    ));

const me = '11111111-1111-4111-8111-111111111111';
const friend = '22222222-2222-4222-8222-222222222222';

Map<String, dynamic> pickupJson({String status = 'pending', int id = 12}) => {
      'id': id,
      'client_id': me,
      'driver_id': null,
      'pickup_address': '10 Main St, Atlanta',
      'pickup_lat': 33.7,
      'pickup_lng': -84.3,
      'scheduled_window_start': '2026-10-28T09:00:00-04:00',
      'scheduled_window_end': '2026-10-28T11:00:00-04:00',
      'driver_reported': false,
      'status': status,
    };

Map<String, dynamic> parcelJson({int id = 5, String status = 'reserved'}) => {
      'id': id,
      'pickup_id': 12,
      'recipient_user_id': friend,
      'weight_kg': '12.50',
      'self_dropoff': false,
      'status': status,
    };

Map<String, dynamic> paged(List<Object> items, {int page = 1, int last = 1}) => {
      'data': items,
      'meta': {
        'current_page': page,
        'last_page': last,
        'per_page': 25,
        'total': items.length,
      },
    };

class FakeLauncher implements CardPaymentLauncher {
  FakeLauncher(this.outcome);
  final CardPaymentOutcome outcome;
  String? secret;

  @override
  Future<CardPaymentOutcome> confirm(String clientSecret) async {
    secret = clientSecret;
    return outcome;
  }
}

class FakePicker implements FilePickerPort {
  FakePicker(this.doc);
  final PickedDocument? doc;

  @override
  Future<PickedDocument?> pick() async => doc;
}

class FakeLocation implements LocationProvider {
  @override
  Future<GeoPoint?> current() async => const GeoPoint(33.7, -84.3);
}

class FakeTokens implements PushTokenSource {
  final controller = StreamController<String>.broadcast();

  @override
  String get platform => 'android';

  @override
  Future<String?> currentToken() async => 'tok-1';

  @override
  Stream<String> get onTokenRefresh => controller.stream;
}

void main() {
  group('Réservation', () {
    test('validation du code destinataire, du poids et de l’adresse', () {
      final c = ReservationController(apiWith((_) async => json({})),
          currentUserId: me);
      expect(c.validateRecipient(''), isNotNull);
      expect(c.validateRecipient('abc'), isNotNull);
      expect(c.validateRecipient(me.toUpperCase()), isNotNull);
      expect(c.validateRecipient(friend), isNull);
      expect(c.validateWeight('0'), isNotNull);
      expect(c.validateWeight('1000'), isNotNull);
      expect(c.validateWeight('abc'), isNotNull);
      expect(c.validateWeight('12,5'), isNull);
      expect(c.validateAddress('rue'), isNotNull);
      expect(c.validateAddress('10 Main St, Atlanta'), isNull);
    });

    test('le destinataire ne peut payer que s’il est seul', () {
      final c = ReservationController(apiWith((_) async => json({})),
          currentUserId: me);
      c.drafts.first.recipientCode = friend;
      expect(c.canRecipientPay, isTrue);
      c.addParcel();
      c.drafts.last.recipientCode = '33333333-3333-4333-8333-333333333333';
      expect(c.canRecipientPay, isFalse);
    });

    test('envoi : réservation, colis puis payeur, dans cet ordre', () async {
      final calls = <String>[];
      final api = apiWith((request) async {
        calls.add('${request.method} ${request.url.path}');
        if (request.url.path.endsWith('/reservations')) {
          return json(pickupJson(), 201);
        }
        if (request.url.path.endsWith('/parcels')) {
          return json(parcelJson(), 201);
        }
        return json({
          'id': 3,
          'pickup_id': 12,
          'payer_user_id': friend,
          'amount': '0',
          'status': 'pending',
        });
      });
      final c = ReservationController(api, currentUserId: me);
      c.drafts.first
        ..recipientCode = friend
        ..weightText = '12,5';
      c.address = '10 Main St, Atlanta';
      c.slots.select(const ApiSlot(
          startIso: '2026-10-28T09:00:00-04:00',
          endIso: '2026-10-28T11:00:00-04:00'));
      c.setRecipientPays(true);
      final pickup = await c.submit();
      expect(pickup?.id, 12);
      expect(calls, [
        'POST /api/v1/reservations',
        'POST /api/v1/reservations/12/parcels',
        'PATCH /api/v1/reservations/12/payer',
      ]);
      expect(c.locked, isTrue);
    });

    test('un échec en cours d’envoi reprend sans recréer la réservation',
        () async {
      var reservations = 0, parcels = 0;
      final api = apiWith((request) async {
        if (request.url.path.endsWith('/reservations')) {
          reservations++;
          return json(pickupJson(), 201);
        }
        parcels++;
        if (parcels == 2) return json({'message': 'Panne'}, 500);
        return json(parcelJson(), 201);
      });
      final c = ReservationController(api, currentUserId: me);
      c.drafts.first
        ..recipientCode = friend
        ..weightText = '2';
      c.addParcel();
      c.drafts.last
        ..recipientCode = friend
        ..weightText = '3';
      c.address = '10 Main St, Atlanta';
      c.slots.select(const ApiSlot(
          startIso: '2026-10-28T09:00:00-04:00',
          endIso: '2026-10-28T11:00:00-04:00'));
      expect(await c.submit(), isNull);
      expect(c.error, isNotNull);
      expect((await c.submit())?.id, 12);
      expect(reservations, 1);
      expect(parcels, 3);
    });

    test('refuse d’envoyer si le formulaire est incomplet', () async {
      final c = ReservationController(apiWith((_) async => json({})),
          currentUserId: me);
      expect(await c.submit(), isNull);
      expect(c.error, contains('Complétez'));
    });
  });

  group('Mes réservations', () {
    test('le filtre de statut est transmis au serveur', () async {
      String? status;
      final api = apiWith((request) async {
        status = request.url.queryParameters['status'];
        return json(paged([pickupJson()]));
      });
      final c = MyReservationsController(api);
      await c.setFilter('collected');
      expect(status, 'collected');
      expect(c.items.single.id, 12);
    });

    test('annuler une réservation déjà collectée (409) recharge l’état',
        () async {
      var reads = 0;
      final api = apiWith((request) async {
        if (request.method == 'POST') {
          return json({'message': 'Déjà collectée'}, 409);
        }
        if (request.url.path.endsWith('/parcels')) return json(paged([]));
        reads++;
        return json(pickupJson(status: 'collected'));
      });
      final c = ReservationDetailController(
          api, ApiPickup.fromJson(pickupJson()));
      expect(await c.cancel(), isFalse);
      expect(c.pickup.status, 'collected');
      expect(c.canPay, isTrue);
      expect(reads, 1);
    });
  });

  group('Paiement', () {
    BackendApi paymentApi({String finalStatus = 'succeeded'}) =>
        apiWith((request) async {
          final path = request.url.path;
          if (path.endsWith('/parcels')) return json(paged([parcelJson()]));
          if (path.endsWith('/pricing/quote')) {
            return json({
              'barrel_price': '150.00',
              'insurance_amount': '7.50',
              'km_fee': '12.00',
              'toll_fee': '0.00',
              'discount_total': '10.00',
              'total_amount': '159.50',
            });
          }
          if (path.endsWith('/payments/capture')) {
            return json({
              'id': 9,
              'pickup_id': 12,
              'payer_user_id': me,
              'amount': '159.50',
              'status': 'pending',
              'client_secret': 'pi_secret_123',
            }, 201);
          }
          return json({
            'id': 9,
            'pickup_id': 12,
            'payer_user_id': me,
            'amount': '159.50',
            'status': finalStatus,
          });
        });

    test('paiement réussi : le serveur confirme', () async {
      final launcher =
          FakeLauncher(const CardPaymentOutcome(CardPaymentStatus.succeeded));
      final c = PaymentController(paymentApi(), launcher,
          ApiPickup.fromJson(pickupJson(status: 'collected')),
          pollDelay: Duration.zero);
      await c.load();
      expect(c.total, closeTo(159.5, 0.001));
      expect(await c.pay(), isTrue);
      expect(c.stage, PaymentStage.paid);
      expect(launcher.secret, 'pi_secret_123');
    });

    test('paiement annulé dans le SDK', () async {
      final c = PaymentController(
          paymentApi(),
          FakeLauncher(const CardPaymentOutcome(CardPaymentStatus.canceled)),
          ApiPickup.fromJson(pickupJson(status: 'collected')),
          pollDelay: Duration.zero);
      expect(await c.pay(), isFalse);
      expect(c.error, 'Paiement annulé.');
      expect(c.stage, PaymentStage.idle);
    });

    test('serveur qui tarde à confirmer : message d’attente', () async {
      final c = PaymentController(
          paymentApi(finalStatus: 'pending'),
          FakeLauncher(const CardPaymentOutcome(CardPaymentStatus.succeeded)),
          ApiPickup.fromJson(pickupJson(status: 'collected')),
          pollDelay: Duration.zero,
          pollAttempts: 2);
      expect(await c.pay(), isFalse);
      expect(c.info, contains('validation'));
    });

    test('sans SDK de paiement, un message clair est renvoyé', () async {
      final c = PaymentController(paymentApi(),
          const UnavailableCardPaymentLauncher(),
          ApiPickup.fromJson(pickupJson(status: 'collected')));
      expect(await c.pay(), isFalse);
      expect(c.error, contains('pas encore disponible'));
    });
  });

  group('Colis et documents', () {
    test('le rôle de confirmation dépend du compte connecté', () {
      final api = apiWith((_) async => json({}));
      final parcel = ApiParcel.fromJson(parcelJson(status: 'arrived'));
      final asRecipient =
          ShipmentDetailController(api, parcel, currentUserId: friend);
      final asSender = ShipmentDetailController(api, parcel, currentUserId: me);
      expect(asRecipient.deliveryRole, 'destinataire');
      expect(asSender.deliveryRole, 'expediteur');
      expect(asSender.canConfirmDelivery, isTrue);
    });

    test('envoi d’un document en multipart', () async {
      http.Request? seen;
      final api = apiWith((request) async {
        seen = request;
        return json({
          'id': 1,
          'parcel_id': 5,
          'type': 'proof_of_deposit',
          'file_path': 'https://files.test/a.pdf',
        }, 201);
      });
      final c = ShipmentDetailController(
        api,
        ApiParcel.fromJson(parcelJson()),
        currentUserId: me,
        picker: FakePicker(PickedDocument(
            'preuve.pdf', Uint8List.fromList('%PDF-1.7'.codeUnits))),
      );
      expect(await c.addDocument('proof_of_deposit'), isTrue);
      expect(seen!.method, 'POST');
      expect(seen!.url.path, '/api/v1/shipments/5/documents');
      expect(seen!.headers['content-type'], startsWith('multipart/form-data'));
      expect(seen!.body, contains('proof_of_deposit'));
      expect(c.documents.single.label, 'Preuve de dépôt');
    });

    test('un fichier non accepté n’est pas envoyé', () async {
      var calls = 0;
      final api = apiWith((_) async {
        calls++;
        return json({});
      });
      final c = ShipmentDetailController(
        api,
        ApiParcel.fromJson(parcelJson()),
        currentUserId: me,
        picker: FakePicker(PickedDocument('virus.exe', Uint8List(10))),
      );
      expect(await c.addDocument('customs_declaration'), isFalse);
      expect(c.error, contains('Format non accepté'));
      expect(calls, 0);
    });

    test('la liste filtre par rôle et statut', () async {
      Map<String, String>? query;
      final api = apiWith((request) async {
        query = request.url.queryParameters;
        return json(paged([parcelJson()]));
      });
      final c = ShipmentsController(api);
      await c.setFilters(role: 'recipient', status: 'arrived');
      expect(query!['role'], 'recipient');
      expect(query!['status'], 'arrived');
    });
  });

  group('Litiges', () {
    test('type obligatoire avant l’envoi', () async {
      var calls = 0;
      final c = DisputesController(apiWith((_) async {
        calls++;
        return json({});
      }));
      expect(await c.open(parcelId: 5, type: 'inconnu'), isFalse);
      expect(c.error, isNotNull);
      expect(calls, 0);
    });

    test('ouverture puis rechargement de la liste', () async {
      final calls = <String>[];
      final api = apiWith((request) async {
        calls.add(request.method);
        if (request.method == 'POST') {
          return json({'id': 1, 'parcel_id': 5, 'type': 'damage', 'status': 'open'}, 201);
        }
        return json(paged([
          {'id': 1, 'parcel_id': 5, 'type': 'damage', 'status': 'open'}
        ]));
      });
      final c = DisputesController(api);
      expect(await c.open(parcelId: 5, type: 'damage', description: 'Cassé'), isTrue);
      expect(calls, ['POST', 'GET']);
      expect(c.items.single.typeLabel, 'Colis abîmé');
      expect(c.items.single.statusLabel, 'Ouvert');
    });
  });

  group('Notifications', () {
    test('texte français selon le type', () {
      final view = describeNotification(const ApiNotification(
          id: 'n1',
          type: 'parcel_status_changed',
          data: {'parcel_id': 5, 'status': 'delivered'}));
      expect(view.title, 'Colis mis à jour');
      expect(view.body, contains('Livré'));
      expect(view.target, NotificationTarget.parcel);
      expect(view.id, 5);
      expect(
          describeNotification(
                  const ApiNotification(id: 'n2', type: 'inconnu'))
              .target,
          NotificationTarget.none);
    });

    test('le jeton push n’est envoyé qu’une fois', () async {
      var posts = 0;
      final api = apiWith((request) async {
        posts++;
        expect(jsonDecode(request.body), {'token': 'tok-1', 'platform': 'android'});
        return json({}, 201);
      });
      final source = FakeTokens();
      final registrar = PushRegistrar(api, source);
      await registrar.start();
      source.controller.add('tok-1');
      await Future<void>.delayed(Duration.zero);
      expect(posts, 1);
      await registrar.stop();
    });
  });

  group('Livreur', () {
    test('accepter une mission déjà acceptée (409) recharge la liste',
        () async {
      var lists = 0;
      final api = apiWith((request) async {
        if (request.method == 'POST') {
          return json({'message': 'Déjà acceptée'}, 409);
        }
        lists++;
        return json(paged([pickupJson(status: 'assigned')]));
      });
      final c = MissionsController(api);
      await c.refresh();
      expect(await c.accept(c.items.first), isFalse);
      expect(lists, 2);
    });

    test('sans position, la disponibilité n’est pas changée', () async {
      var calls = 0;
      final c = AvailabilityController(
          apiWith((_) async {
            calls++;
            return json({});
          }),
          const NoLocationProvider());
      expect(await c.setAvailable(false), isFalse);
      expect(c.available, isTrue);
      expect(c.error, contains('Position indisponible'));
      expect(calls, 0);
    });

    test('la position est envoyée avec la disponibilité', () async {
      Map<String, dynamic>? sent;
      final api = apiWith((request) async {
        sent = jsonDecode(request.body) as Map<String, dynamic>;
        return json({});
      });
      final c = AvailabilityController(api, FakeLocation());
      expect(await c.setAvailable(false), isTrue);
      expect(sent, {'lat': 33.7, 'lng': -84.3, 'available': false});
    });

    test('commissions : lecture des cycles et de la pagination', () async {
      final api = apiWith((request) async => json({
            'commissions': [
              {'id': 1, 'parcel_id': 5, 'driver_id': 2, 'amount': 22.5, 'billing_cycle_id': 1}
            ],
            'billing_cycles': [
              {
                'id': 1,
                'driver_id': 2,
                'period_start': '2026-10-01',
                'period_end': '2026-10-31',
                'total_amount': 22.5,
                'status': 'open'
              }
            ],
            'meta': {'current_page': 1, 'last_page': 2, 'per_page': 25, 'total': 30},
          }));
      final c = CommissionsController(api);
      await c.refresh();
      expect(c.commissions.single.amount, 22.5);
      expect(c.cycles.single.totalAmount, 22.5);
      expect(c.hasMore, isTrue);
    });

    test('itinéraire : 409 donne un message sur la position', () async {
      final api = apiWith((_) async => json({'message': 'x'}, 409));
      final c = RouteEstimateController(api, 12);
      await c.load();
      expect(c.error, contains('Position'));
    });
  });

  test('grille de prix publique', () async {
    final api = apiWith((request) async {
      expect(request.url.path, '/api/v1/pricing/rules');
      return json({'barrel_price': 150, 'insurance_rate': '5.00'});
    });
    final rules = await api.pricingRules();
    expect(rules['barrel_price'], 150);
    expect(rules.containsKey('insurance_rate'), isFalse);
  });
}
