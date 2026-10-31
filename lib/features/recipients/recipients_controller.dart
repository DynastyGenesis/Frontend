// Carnet « Mes destinataires » : noms et codes gardés sur l'appareil.
import '../../data/local/contacts_store.dart';
import '../common/feature_controller.dart';

final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

/// Un code destinataire est l'identifiant (UUID) de son compte.
bool isRecipientCode(String value) => _uuid.hasMatch(value.trim());

class RecipientsController extends FeatureController {
  RecipientsController(this._store, {required this.currentUserId});

  final ContactsStore _store;

  /// Un expéditeur ne peut pas être son propre destinataire.
  final String currentUserId;

  List<RecipientContact> contacts = [];
  bool loadedOnce = false;

  Future<void> load() async {
    contacts = await _store.load();
    loadedOnce = true;
    notifyListeners();
  }

  String? validateName(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Saisissez un nom.';
    if (text.length > 60) return 'Nom trop long (60 caractères maximum).';
    return null;
  }

  String? validateCode(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Saisissez le code du destinataire.';
    if (!isRecipientCode(text)) {
      return 'Code invalide. Demandez-le au destinataire (écran Mon compte).';
    }
    if (text.toLowerCase() == currentUserId.toLowerCase()) {
      return 'Le destinataire doit être une autre personne que vous.';
    }
    if (contacts.any((c) => c.code == text.toLowerCase())) {
      return 'Ce code est déjà dans votre carnet.';
    }
    return null;
  }

  /// Ajoute un destinataire. Renvoie faux si le nom ou le code est invalide
  /// ou si l'enregistrement sur l'appareil échoue.
  Future<bool> add({required String name, required String code}) async {
    if (validateName(name) != null || validateCode(code) != null) return false;
    final next = [
      ...contacts,
      RecipientContact(name: name.trim(), code: code.trim().toLowerCase()),
    ];
    return _persist(next);
  }

  Future<bool> remove(RecipientContact contact) =>
      _persist([for (final c in contacts) if (c.code != contact.code) c]);

  Future<bool> _persist(List<RecipientContact> next) async {
    final saved = await run(() async {
      await _store.save(next);
      return true;
    });
    if (saved != true) {
      error ??= 'Le carnet n’a pas pu être enregistré sur cet appareil.';
      notifyListeners();
      return false;
    }
    contacts = next;
    notifyListeners();
    return true;
  }
}
