import 'package:web/web.dart' as web;

String _key(String userId) => 'barelgo-contacts-v1-$userId';

Future<String?> readContacts(String userId) async =>
    web.window.localStorage.getItem(_key(userId));

Future<void> writeContacts(String userId, String value) async {
  web.window.localStorage.setItem(_key(userId), value);
}
