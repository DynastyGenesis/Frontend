// Carnet « Mes destinataires » : stockage par compte, validation, sélecteur.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:barrel_go/data/local/contacts_store.dart';
import 'package:barrel_go/features/recipients/recipients_controller.dart';
import 'package:barrel_go/features/recipients/recipients_screen.dart';

const me = '11111111-1111-4111-8111-111111111111';
const bob = '22222222-2222-4222-8222-222222222222';

({ContactsStore store, Map<String, String> disk}) memoryStore(String user,
    [Map<String, String>? shared]) {
  final disk = shared ?? <String, String>{};
  return (
    store: ContactsStore(user,
        reader: (u) async => disk[u], writer: (u, v) async => disk[u] = v),
    disk: disk,
  );
}

void main() {
  test('ajoute, relit et supprime un destinataire', () async {
    final m = memoryStore(me);
    final c = RecipientsController(m.store, currentUserId: me);
    await c.load();
    expect(c.contacts, isEmpty);

    expect(await c.add(name: ' Bob ', code: bob.toUpperCase()), isTrue);
    expect(c.contacts.single.name, 'Bob');
    expect(c.contacts.single.code, bob);

    final again = RecipientsController(memoryStore(me, m.disk).store,
        currentUserId: me);
    await again.load();
    expect(again.contacts.single.code, bob);

    expect(await again.remove(again.contacts.single), isTrue);
    expect(again.contacts, isEmpty);
  });

  test('le carnet est propre à chaque compte', () async {
    final disk = <String, String>{};
    final mine = RecipientsController(memoryStore(me, disk).store, currentUserId: me);
    await mine.load();
    await mine.add(name: 'Bob', code: bob);

    final other = RecipientsController(memoryStore(bob, disk).store, currentUserId: bob);
    await other.load();
    expect(other.contacts, isEmpty);
  });

  test('refuse un code invalide, le sien et un doublon', () async {
    final c = RecipientsController(memoryStore(me).store, currentUserId: me);
    await c.load();
    expect(c.validateCode('abc'), isNotNull);
    expect(c.validateCode(me), contains('autre personne'));
    expect(c.validateName('  '), isNotNull);
    expect(await c.add(name: 'Bob', code: 'abc'), isFalse);
    await c.add(name: 'Bob', code: bob);
    expect(c.validateCode(bob), contains('déjà'));
  });

  test('un carnet illisible donne une liste vide', () async {
    final store = ContactsStore(me, reader: (_) async => 'pas du json');
    expect(await store.load(), isEmpty);
  });

  test('un échec d’écriture est signalé et le carnet reste inchangé', () async {
    final store = ContactsStore(me,
        reader: (_) async => null, writer: (_, _) async => throw Exception());
    final c = RecipientsController(store, currentUserId: me);
    await c.load();
    expect(await c.add(name: 'Bob', code: bob), isFalse);
    expect(c.contacts, isEmpty);
    expect(c.error, isNotNull);
  });

  testWidgets('le sélecteur renvoie le destinataire choisi', (tester) async {
    final m = memoryStore(me);
    final c = RecipientsController(m.store, currentUserId: me);
    await c.load();
    await c.add(name: 'Bob', code: bob);
    RecipientContact? picked;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => picked = await pickRecipient(context, c),
          child: const Text('ouvrir'),
        ),
      ),
    ));
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bob'));
    await tester.pumpAndSettle();
    expect(picked?.code, bob);
  });
}
