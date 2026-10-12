import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';

Future<bool> saveDocumentBytes(
    Uint8List bytes, String name, String mime) async {
  final location = await getSaveLocation(suggestedName: name);
  if (location == null) return false;
  await XFile.fromData(bytes, mimeType: mime, name: name).saveTo(location.path);
  return true;
}
