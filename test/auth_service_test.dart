import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:barrel_go/core/app_config.dart';
import 'package:barrel_go/data/api/api_exception.dart';
import 'package:barrel_go/data/auth/auth_service.dart';
import 'package:barrel_go/data/auth/auth_session.dart';

const config = AppConfig(
  apiBaseUrl: 'https://api.test/api/v1',
  supabaseUrl: 'https://projet.supabase.test/',
  supabaseKey: 'sb_publishable_test',
);

http.Response jsonResponse(Object body, int status) => http.Response.bytes(
    utf8.encode(jsonEncode(body)), status,
    headers: {'content-type': 'application/json'});

Map<String, dynamic> sessionBody(String access, {int expiresIn = 3600}) => {
      'access_token': access,
      'refresh_token': 'refresh-$access',
      'expires_in': expiresIn,
      'user': {'id': 'uuid-1', 'email': 'a@b.co'},
    };

void main() {
  final now = DateTime.utc(2026, 10, 26, 12);

  test('la configuration exige les trois valeurs', () {
    expect(config.useBackend, isTrue);
    expect(const AppConfig().useBackend, isFalse);
    expect(const AppConfig(apiBaseUrl: 'https://x').useBackend, isFalse);
  });

  test('signIn appelle le jeton par mot de passe et enregistre la session',
      () async {
    late http.Request seen;
    final store = MemorySessionStore();
    final service = AuthService(
      config: config,
      store: store,
      clock: () => now,
      client: MockClient((request) async {
        seen = request;
        return jsonResponse(sessionBody('acces-1'), 200);
      }),
    );
    final session = await service.signIn(email: ' a@b.co ', password: 'secret1');
    expect(seen.url.path, '/auth/v1/token');
    expect(seen.url.queryParameters['grant_type'], 'password');
    expect(seen.headers['apikey'], 'sb_publishable_test');
    expect(jsonDecode(seen.body), {'email': 'a@b.co', 'password': 'secret1'});
    expect(session.accessToken, 'acces-1');
    expect(session.userId, 'uuid-1');
    expect((await store.load())!.accessToken, 'acces-1');
    expect(await service.accessToken(), 'acces-1');
  });

  test('signIn traduit un identifiant incorrect en français', () async {
    final service = AuthService(
      config: config,
      store: MemorySessionStore(),
      client: MockClient((_) async => jsonResponse({
            'error_code': 'invalid_credentials',
            'msg': 'Invalid login credentials',
          }, 400)),
    );
    await expectLater(
      service.signIn(email: 'a@b.co', password: 'mauvais'),
      throwsA(isA<ApiException>().having((e) => e.message, 'message',
          'Adresse e-mail ou mot de passe incorrect.')),
    );
  });

  test('signUp envoie le nom dans full_name', () async {
    late http.Request seen;
    final service = AuthService(
      config: config,
      store: MemorySessionStore(),
      clock: () => now,
      client: MockClient((request) async {
        seen = request;
        return jsonResponse(sessionBody('acces-2'), 200);
      }),
    );
    final result = await service.signUp(
        email: 'a@b.co', password: 'secret1', name: ' Koffi Mensah ');
    expect(jsonDecode(seen.body)['data'], {'full_name': 'Koffi Mensah'});
    expect(result.needsEmailConfirmation, isFalse);
  });

  test('signUp sans session signale la confirmation de l’e-mail', () async {
    final service = AuthService(
      config: config,
      store: MemorySessionStore(),
      client: MockClient(
          (_) async => jsonResponse({'id': 'uuid-2', 'email': 'a@b.co'}, 200)),
    );
    final result =
        await service.signUp(email: 'a@b.co', password: 'secret1', name: 'K');
    expect(result.needsEmailConfirmation, isTrue);
    expect(service.isSignedIn, isFalse);
  });

  test('un jeton expiré est renouvelé avant usage', () async {
    var clockNow = now;
    var calls = 0;
    final service = AuthService(
      config: config,
      store: MemorySessionStore(),
      clock: () => clockNow,
      client: MockClient((request) async {
        calls++;
        if (request.url.queryParameters['grant_type'] == 'refresh_token') {
          expect(jsonDecode(request.body), {'refresh_token': 'refresh-acces-1'});
          return jsonResponse(sessionBody('acces-2'), 200);
        }
        return jsonResponse(sessionBody('acces-1', expiresIn: 60), 200);
      }),
    );
    await service.signIn(email: 'a@b.co', password: 'secret1');
    clockNow = now.add(const Duration(minutes: 5));
    expect(await service.accessToken(), 'acces-2');
    expect(calls, 2);
  });

  test('un refus de renouvellement efface la session', () async {
    var clockNow = now;
    final store = MemorySessionStore();
    final service = AuthService(
      config: config,
      store: store,
      clock: () => clockNow,
      client: MockClient((request) async {
        if (request.url.queryParameters['grant_type'] == 'refresh_token') {
          return jsonResponse({'error_code': 'invalid_grant'}, 400);
        }
        return jsonResponse(sessionBody('acces-1', expiresIn: 60), 200);
      }),
    );
    await service.signIn(email: 'a@b.co', password: 'secret1');
    clockNow = now.add(const Duration(minutes: 5));
    expect(await service.refresh(), isFalse);
    expect(service.isSignedIn, isFalse);
    expect(await store.load(), isNull);
  });

  test('restore recharge une session enregistrée', () async {
    final store = MemorySessionStore();
    await store.save(AuthSession(
      accessToken: 'stocke',
      refreshToken: 'r',
      expiresAt: now.add(const Duration(hours: 1)),
    ));
    final service = AuthService(
      config: config,
      store: store,
      clock: () => now,
      client: MockClient((_) async => fail('aucun appel réseau attendu')),
    );
    await service.restore();
    expect(await service.accessToken(), 'stocke');
  });

  test('signOut efface la session même si le serveur est injoignable',
      () async {
    final store = MemorySessionStore();
    final service = AuthService(
      config: config,
      store: store,
      clock: () => now,
      client: MockClient((request) async {
        if (request.url.path == '/auth/v1/logout') {
          throw http.ClientException('hors ligne');
        }
        return jsonResponse(sessionBody('acces-1'), 200);
      }),
    );
    await service.signIn(email: 'a@b.co', password: 'secret1');
    await service.signOut();
    expect(service.isSignedIn, isFalse);
    expect(await store.load(), isNull);
  });

  test('completeOAuthRedirect enregistre la session Google du fragment',
      () async {
    final payload = base64Url
        .encode(utf8.encode(jsonEncode({'sub': 'uuid-g', 'email': 'g@b.co'})))
        .replaceAll('=', '');
    final token = 'e30.$payload.sig';
    final store = MemorySessionStore();
    final service = AuthService(
      config: config,
      store: store,
      clock: () => now,
      client: MockClient((_) async => jsonResponse({}, 500)),
    );
    expect(await service.completeOAuthRedirect(Uri.parse('https://x.test/')),
        isFalse);
    final ok = await service.completeOAuthRedirect(Uri.parse(
        'https://x.test/?space=driver#access_token=$token&refresh_token=r1&expires_in=600'));
    expect(ok, isTrue);
    expect(service.session!.userId, 'uuid-g');
    expect(service.session!.email, 'g@b.co');
    expect(service.session!.expiresAt, now.add(const Duration(seconds: 600)));
    expect((await store.load())!.refreshToken, 'r1');
    final url = service.googleSignInUrl('https://x.test/?space=client');
    expect(url.path, '/auth/v1/authorize');
    expect(url.queryParameters['provider'], 'google');
  });
}
