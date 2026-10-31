import 'dart:convert';

import 'contacts_store_stub.dart'
    if (dart.library.io) 'contacts_store_io.dart'
    if (dart.library.js_interop) 'contacts_store_web.dart' as platform;

/// Destinataire enregistré par l'utilisateur : un nom et le code (UUID) lu
/// dans « Mon compte » du destinataire.
class RecipientContact {
  const RecipientContact({required this.name, required this.code});

  factory RecipientContact.fromJson(Map<String, dynamic> json) =>
      RecipientContact(
        name: json['name'] is String ? json['name'] as String : '',
        code: json['code'] is String ? json['code'] as String : '',
      );

  final String name;
  final String code;

  Map<String, dynamic> toJson() => {'name': name, 'code': code};
}

/// Carnet de destinataires, propre à un compte et gardé sur l'appareil. Le
/// backend n'a pas de recherche de destinataire : sans ce carnet, il faudrait
/// ressaisir le code à chaque colis. Rien n'est envoyé au serveur.
class ContactsStore {
  ContactsStore(
    this.userId, {
    Future<String?> Function(String userId)? reader,
    Future<void> Function(String userId, String value)? writer,
  })  : _reader = reader ?? platform.readContacts,
        _writer = writer ?? platform.writeContacts;

  final String userId;
  final Future<String?> Function(String userId) _reader;
  final Future<void> Function(String userId, String value) _writer;

  /// Lit le carnet ; un fichier absent ou illisible donne un carnet vide.
  Future<List<RecipientContact>> load() async {
    try {
      final raw = await _reader(userId);
      if (raw == null) return [];
      final decoded = jsonDecode(raw);
      return [
        if (decoded is List)
          for (final item in decoded)
            if (item is Map<String, dynamic>) RecipientContact.fromJson(item),
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<RecipientContact> contacts) =>
      _writer(userId, jsonEncode([for (final c in contacts) c.toJson()]));
}
