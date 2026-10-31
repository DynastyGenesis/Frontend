import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:barrel_go/data/api/api_client.dart';
import 'package:barrel_go/data/api/api_exception.dart';
import 'package:barrel_go/data/api/paged.dart';

http.Response jsonResponse(Object body, int status,
        {Map<String, String> headers = const {}}) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status,
        headers: {'content-type': 'application/json', ...headers});

void main() {
  test('joint le jeton et construit l’adresse avec la pagination', () async {
    late http.Request seen;
    final client = ApiClient(
      baseUrl: 'https://api.test/api/v1/',
      tokenProvider: () async => 'jeton-1',
      client: MockClient((request) async {
        seen = request;
        return jsonResponse({'ok': true}, 200);
      }),
    );
    final result =
        await client.get('/reservations', query: {'page': 2, 'status': null});
    expect(result, {'ok': true});
    expect(seen.url.toString(), 'https://api.test/api/v1/reservations?page=2');
    expect(seen.headers['Authorization'], 'Bearer jeton-1');
  });

  test('envoie le corps JSON et décode les accents en UTF-8', () async {
    late http.Request seen;
    final client = ApiClient(
      baseUrl: 'https://api.test/api/v1',
      client: MockClient((request) async {
        seen = request;
        return jsonResponse({'message': 'Créé à Lomé'}, 201);
      }),
    );
    final result =
        await client.post('/reservations', body: {'pickup_address': 'Lomé'});
    expect(jsonDecode(seen.body), {'pickup_address': 'Lomé'});
    expect(seen.headers['Content-Type'], contains('application/json'));
    expect(result['message'], 'Créé à Lomé');
  });

  test('une réponse vide renvoie null', () async {
    final client = ApiClient(
      baseUrl: 'https://api.test',
      client: MockClient((_) async => http.Response('', 204)),
    );
    expect(await client.post('/missions/1/accept'), isNull);
  });

  test('une erreur 422 expose les messages par champ', () async {
    final client = ApiClient(
      baseUrl: 'https://api.test',
      client: MockClient((_) async => jsonResponse({
            'message': 'Les données envoyées ne sont pas valides.',
            'errors': {
              'pickup_address': ['Adresse trop imprécise.']
            },
          }, 422)),
    );
    await expectLater(
      client.post('/reservations', body: {'pickup_address': 'x'}),
      throwsA(isA<ApiException>()
          .having((e) => e.isValidation, 'isValidation', true)
          .having((e) => e.displayMessage, 'displayMessage',
              'Adresse trop imprécise.')),
    );
  });

  test('les statuts 404, 409, 429 et 503 donnent un message français',
      () async {
    for (final status in [404, 409, 429, 503]) {
      final client = ApiClient(
        baseUrl: 'https://api.test',
        client: MockClient((_) async =>
            http.Response('', status, headers: {'retry-after': '7'})),
      );
      try {
        await client.get('/x');
        fail('une exception était attendue');
      } on ApiException catch (error) {
        expect(error.statusCode, status);
        expect(error.message, isNotEmpty);
        if (status == 429) expect(error.retryAfterSeconds, 7);
      }
    }
  });

  test('une panne réseau devient une ApiException sans code', () async {
    final client = ApiClient(
      baseUrl: 'https://api.test',
      client: MockClient((_) async => throw http.ClientException('hors ligne')),
    );
    await expectLater(
      client.get('/x'),
      throwsA(isA<ApiException>().having((e) => e.isNetwork, 'isNetwork', true)),
    );
  });

  test('un 401 renouvelle le jeton puis rejoue la requête une seule fois',
      () async {
    var token = 'ancien';
    var calls = 0;
    final client = ApiClient(
      baseUrl: 'https://api.test',
      tokenProvider: () async => token,
      onUnauthorized: () async {
        token = 'nouveau';
        return true;
      },
      client: MockClient((request) async {
        calls++;
        if (request.headers['Authorization'] == 'Bearer nouveau') {
          return jsonResponse({'id': 1}, 200);
        }
        return jsonResponse({'message': 'Non authentifié.'}, 401);
      }),
    );
    expect(await client.get('/me'), {'id': 1});
    expect(calls, 2);
  });

  test('un 401 sans renouvellement possible lève une erreur 401', () async {
    final client = ApiClient(
      baseUrl: 'https://api.test',
      onUnauthorized: () async => false,
      client: MockClient((_) async => jsonResponse({}, 401)),
    );
    await expectLater(
      client.get('/me'),
      throwsA(isA<ApiException>()
          .having((e) => e.isUnauthorized, 'isUnauthorized', true)),
    );
  });

  test('Paged lit data et meta', () {
    final page = Paged<int>.fromJson({
      'data': [
        {'id': 3},
        {'id': 4},
      ],
      'meta': {'current_page': 1, 'last_page': 2, 'per_page': 2, 'total': 3},
    }, (json) => json['id'] as int);
    expect(page.items, [3, 4]);
    expect(page.hasMore, isTrue);
    expect(page.meta.total, 3);
  });
}
