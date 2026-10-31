// NON ASSEMBLÉ. Choix d'un fichier (document de colis).
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';

class PickedDocument {
  const PickedDocument(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
}

/// Port pour choisir un fichier : remplaçable dans les tests.
abstract class FilePickerPort {
  Future<PickedDocument?> pick();
}

/// Implémentation réelle (file_selector, déjà dans le projet).
class FileSelectorPicker implements FilePickerPort {
  const FileSelectorPicker();

  @override
  Future<PickedDocument?> pick() async {
    final file = await openFile(acceptedTypeGroups: const [
      XTypeGroup(
        label: 'Documents',
        extensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      ),
    ]);
    if (file == null) return null;
    return PickedDocument(file.name, await file.readAsBytes());
  }
}

const maxDocumentBytes = 10 * 1024 * 1024;

/// Contrôle local avant envoi (le backend recontrôle le contenu).
String? validateDocument(String type, PickedDocument doc) {
  final ext = doc.name.split('.').last.toLowerCase();
  final allowed = type == 'proof_of_deposit'
      ? const ['pdf', 'jpg', 'jpeg', 'png', 'webp']
      : const ['pdf', 'jpg', 'jpeg', 'png'];
  if (!allowed.contains(ext)) {
    return 'Format non accepté. Formats possibles : ${allowed.join(', ')}.';
  }
  if (doc.bytes.isEmpty) return 'Ce fichier est vide.';
  if (doc.bytes.length > maxDocumentBytes) {
    return 'Le fichier dépasse la limite de 10 Mo.';
  }
  return null;
}
