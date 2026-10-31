import 'package:flutter/material.dart';
import '../data/app_services.dart';
import '../presentation/pages/client_space/ships_login_page.dart';
import '../presentation/pages/home/ships_public_home_page.dart';

class BarelGoApp extends StatelessWidget {
  /// `client` ou `driver` : rouvre directement la page de connexion pour finir
  /// une connexion Google.
  final String? resumeSpace;
  const BarelGoApp({super.key, this.resumeSpace});

  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'BarelGo',
      debugShowCheckedModeBanner: false,
      theme: shipsPublicTheme(),
      home: AppServices.instance == null
          ? const MissingConfigPage()
          : const ShipsPublicHomePage(),
      onGenerateInitialRoutes: resumeSpace == null
          ? null
          : (_) => [
                MaterialPageRoute<void>(
                    builder: (_) => const ShipsPublicHomePage()),
                MaterialPageRoute<void>(
                    builder: (_) => ShipsLoginPage(
                        driver: resumeSpace == 'driver', resumeSession: true)),
              ]);
}

typedef BarrelGoApp = BarelGoApp;

/// Affichée quand l'application est lancée sans les valeurs du backend.
class MissingConfigPage extends StatelessWidget {
  const MissingConfigPage({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.settings_outlined, size: 48),
              SizedBox(height: 16),
              Text('Configuration du backend manquante',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              SizedBox(height: 12),
              Text(
                'Lancez l’application avec API_BASE_URL, SUPABASE_URL et '
                'SUPABASE_PUBLISHABLE_KEY, par exemple :\n'
                'flutter run --dart-define-from-file=config/env.json\n'
                '(modèle : config/env.example.json).',
                textAlign: TextAlign.center,
              ),
            ]),
          ),
        ),
      );
}
