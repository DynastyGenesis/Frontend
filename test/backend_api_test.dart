import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:barrel_go/data/api/api_client.dart';
import 'package:barrel_go/data/models/api_models.dart';
import 'package:barrel_go/data/services/backend_api.dart';

http.Response jsonResponse(Object body, int status) => http.Response.bytes(
    utf8.encode(jsonEncode(body)), status,
    headers: {'content-type': 'application/json'});

BackendApi apiWith(Future<http.Response> Function(http.Request) handler) =>
    BackendApi(ApiClient(
      baseUrl: 'https://api.test/api/v1',
      client: MockClient(handler),
    ));

void main() {
  test('me lit le profil et les rôles', () async {
    final api = apiWith((request) async {
      expect(request.url.path, '/api/v1/me');
      return jsonResponse({
        'id': 'uuid-1',
        'name': 'Koffi',
        'email': 'k@x.co',
        'roles': ['client_expediteur', 'livreur'],
      }, 200);
    });
    final user = await api.me();
    expect(user.name, 'Koffi');
    expect(user.isDriver, isTrue);
    expect(user.isAdmin, isFalse);
  });

  test('createReservation renvoie le créneau exactement comme reçu', () async {
    late Map<String, dynamic> sent;
    final api = apiWith((request) async {
      sent = jsonDecode(request.body) as Map<String, dynamic>;
      return jsonResponse({
        'id': 12,
        'client_id': 'uuid-1',
        'driver_id': null,
        'pickup_address': '10 Main St, Atlanta',
        'pickup_lat': '33.7490000',
        'pickup_lng': -84.388,
        'scheduled_window_start': '2026-10-28T09:00:00-04:00',
        'scheduled_window_end': '2026-10-28T11:00:00-04:00',
        'driver_reported': false,
        'status': 'pending',
      }, 201);
    });
    const slot = ApiSlot(
      startIso: '2026-10-28T09:00:00-04:00',
      endIso: '2026-10-28T11:00:00-04:00',
    );
    final pickup =
        await api.createReservation(address: '10 Main St, Atlanta', slot: slot);
    expect(sent['scheduled_window_start'], '2026-10-28T09:00:00-04:00');
    expect(sent['scheduled_window_end'], '2026-10-28T11:00:00-04:00');
    expect(pickup.id, 12);
    expect(pickup.lat, closeTo(33.749, 0.0001));
    expect(pickup.status, 'pending');
  });

  test('pickupSlots lit un tableau JSON nu', () async {
    final api = apiWith((request) async {
      expect(request.url.queryParameters['date'], '2026-10-28');
      return jsonResponse([
        {
          'window_start': '2026-10-28T09:00:00-04:00',
          'window_end': '2026-10-28T11:00:00-04:00'
        },
      ], 200);
    });
    final slots = await api.pickupSlots(date: '2026-10-28');
    expect(slots, hasLength(1));
    expect(slots.first.start, isNotNull);
  });

  test('shipments filtre par rôle et lit la pagination', () async {
    final api = apiWith((request) async {
      expect(request.url.queryParameters['role'], 'recipient');
      expect(request.url.queryParameters.containsKey('status'), isFalse);
      return jsonResponse({
        'data': [
          {
            'id': 5,
            'pickup_id': 12,
            'recipient_user_id': 'uuid-2',
            'weight_kg': '23.50',
            'self_dropoff': false,
            'status': 'in_transit',
          },
        ],
        'meta': {'current_page': 1, 'last_page': 1, 'per_page': 25, 'total': 1},
      }, 200);
    });
    final page = await api.shipments(role: 'recipient');
    expect(page.items.single.weightKg, 23.5);
    expect(page.items.single.status, 'in_transit');
    expect(page.hasMore, isFalse);
  });

  test('capturePayment expose le client_secret sans le stocker', () async {
    final api = apiWith((request) async {
      expect(jsonDecode(request.body), {'pickup_id': 12});
      return jsonResponse({
        'id': 3,
        'pickup_id': 12,
        'payer_user_id': 'uuid-1',
        'amount': '157.50',
        'status': 'pending',
        'client_secret': 'pi_secret_abc',
      }, 200);
    });
    final payment = await api.capturePayment(12);
    expect(payment.amount, 157.5);
    expect(payment.clientSecret, 'pi_secret_abc');
  });

  test('estimate lit le total hors frais kilométriques', () async {
    final api = apiWith((request) async => jsonResponse({
          'barrel_price': 150,
          'insurance_amount': 7.5,
          'estimated_discount': 0,
          'estimated_total_excluding_km_fee': 157.5,
          'note': 'Estimation hors frais kilométrique.',
        }, 200));
    final estimate = await api.estimate();
    expect(estimate.estimatedTotal, 157.5);
  });

  test('confirmDelivery envoie le rôle choisi', () async {
    late Map<String, dynamic> sent;
    final api = apiWith((request) async {
      sent = jsonDecode(request.body) as Map<String, dynamic>;
      return jsonResponse({
        'id': 5,
        'pickup_id': 12,
        'recipient_user_id': 'uuid-2',
        'weight_kg': 20,
        'status': 'delivered',
      }, 200);
    });
    final parcel = await api.confirmDelivery(5, role: 'destinataire');
    expect(sent, {'role': 'destinataire'});
    expect(parcel.status, 'delivered');
  });

  test('un modèle tolère les champs absents', () {
    final parcel = ApiParcel.fromJson(const {});
    expect(parcel.id, 0);
    expect(parcel.status, 'reserved');
    expect(ApiNotification.fromJson(const {'id': 'n1', 'type': 't'}).isRead,
        isFalse);
  });
}
