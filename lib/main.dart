import 'package:flutter/material.dart';
import 'app/app.dart';
import 'data/app_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppServices.initialize();
  runApp(BarelGoApp(resumeSpace: AppServices.oauthReturnSpace));
}
