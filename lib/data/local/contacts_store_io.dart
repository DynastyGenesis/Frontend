import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<File> _file(String userId) async {
  final directory = await getApplicationSupportDirectory();
  return File('${directory.path}/BarelGo/contacts-$userId.json');
}

Future<String?> readContacts(String userId) async {
  final target = await _file(userId);
  return await target.exists() ? target.readAsString() : null;
}

Future<void> writeContacts(String userId, String value) async {
  final target = await _file(userId);
  await target.parent.create(recursive: true);
  final temporary = File('${target.path}.tmp');
  await temporary.writeAsString(value, flush: true);
  // Windows cannot rename over an existing file.
  await temporary.copy(target.path);
  await temporary.delete();
}
