// Tirage au sort : modèle, contrôleur et écran (GET /raffle/current et /raffle/history).
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:barrel_go/data/api/api_client.dart';
import 'package:barrel_go/data/models/api_models_raffle.dart';
import 'package:barrel_go/data/services/backend_api.dart';
import 'package:barrel_go/features/raffle/raffle_screen.dart';

const me = '11111111-1111-4111-8111-111111111111';

http.Response json(Object body, [int status = 200]) => http.Response.bytes(
    utf8.encode(jsonEncode(body)), status,
    headers: {'content-type': 'application/json'});

BackendApi apiWith(Future<http.Response> Function(http.Request) handler) =>
    BackendApi(ApiClient(
      baseUrl: 'https://api.test/api/v1',
      client: MockClient(handler),
    ));

Map<String, dynamic> draw({String? winner, double? amount, String? at}) => {
      'id': winner == null ? null : 3,
      'state': 'GA',
      'period_start': '2026-10-01',
      'period_end': '2026-10-31',
      'winner_user_id': winner,
      'amount_refunded': amount,
      'drawn_at': at,
    };

void main() {
  test('un tirage non effectué a des champs nuls', () {
    final d = ApiRaffleDraw.fromJson(draw());
    expect(d.id, isNull);
    expect(d.isDrawn, isFalse);
    expect(d.winnerUserId, isNull);
    expect(d.state, 'GA');
  });

  test('un tirage effectué est lu en entier', () {
    final d = ApiRaffleDraw.fromJson(
        draw(winner: me, amount: 42.5, at: '2026-10-31T12:00:00-04:00'));
    expect(d.isDrawn, isTrue);
    expect(d.amountRefunded, 42.5);
    expect(d.winnerUserId, me);
  });

  test('charge le tirage du mois et l’historique', () async {
    final paths = <String>[];
    final api = apiWith((request) async {
      paths.add(request.url.path);
      if (request.url.path.endsWith('/raffle/current')) return json(draw());
      return json([
        draw(winner: me, amount: 10, at: '2026-09-30T12:00:00-04:00'),
        draw(winner: 'autre', amount: 5, at: '2026-08-31T12:00:00-04:00'),
      ]);
    });
    final c = RaffleController(api, currentUserId: me);
    await c.load();
    expect(paths, ['/api/v1/raffle/current', '/api/v1/raffle/history']);
    expect(c.current?.isDrawn, isFalse);
    expect(c.history, hasLength(2));
    expect(c.isWinner(c.history.first), isTrue);
    expect(c.isWinner(c.history.last), isFalse);
    expect(c.missingState, isFalse);
  });

  test('sans État sur le profil, le 404 devient une invitation à le renseigner',
      () async {
    final api = apiWith((request) async {
      if (request.url.path.endsWith('/raffle/current')) {
        return json({'message': "Aucun état n'est renseigné sur votre profil."}, 404);
      }
      return json([]);
    });
    final c = RaffleController(api, currentUserId: me);
    await c.load();
    expect(c.missingState, isTrue);
    expect(c.error, isNull);
    expect(c.current, isNull);
  });

  test('une autre erreur reste affichée', () async {
    final api = apiWith((_) async => json({'message': 'Panne'}, 503));
    final c = RaffleController(api, currentUserId: me);
    await c.load();
    expect(c.missingState, isFalse);
    expect(c.error, isNotNull);
  });

  testWidgets('l’écran propose de renseigner l’État', (tester) async {
    var opened = false;
    final api = apiWith((request) async {
      if (request.url.path.endsWith('/raffle/current')) {
        return json({'message': 'Aucun état'}, 404);
      }
      return json([]);
    });
    await tester.pumpWidget(MaterialApp(
      home: RaffleScreen(
        controller: RaffleController(api, currentUserId: me),
        onOpenAccount: () => opened = true,
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('État non renseigné'), findsOneWidget);
    await tester.tap(find.text('Renseigner mon État'));
    expect(opened, isTrue);
  });

  testWidgets('l’écran signale un gain', (tester) async {
    final api = apiWith((request) async {
      if (request.url.path.endsWith('/raffle/current')) {
        return json(draw(winner: me, amount: 20, at: '2026-10-31T12:00:00-04:00'));
      }
      return json([]);
    });
    await tester.pumpWidget(MaterialApp(
      home: RaffleScreen(controller: RaffleController(api, currentUserId: me)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Vous avez gagné'), findsOneWidget);
    expect(find.textContaining('Crédit offert'), findsOneWidget);
  });
}
