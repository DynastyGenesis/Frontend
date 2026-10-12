import 'package:flutter/material.dart';
import '../presentation/pages/home/ships_public_home_page.dart';
import 'package:flutter/foundation.dart';
import '../core/theme/app_theme.dart';
import '../presentation/pages/home/home_page.dart';
import '../presentation/pages/tracking/tracking_page.dart';
import '../presentation/pages/quote/quote_page.dart';
import '../presentation/pages/shipments/shipments_page.dart';
import '../presentation/pages/profile/profile_page.dart';
import '../presentation/pages/client_space/client_space_page.dart';
import '../presentation/pages/driver_space/driver_space_page.dart';

class BarrelGoApp extends StatelessWidget {
  final bool legacy;
  const BarrelGoApp({super.key, this.legacy = false});
  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'Ships4US',
      debugShowCheckedModeBanner: false,
      theme: legacy ? AppTheme.light() : shipsPublicTheme(),
      home: legacy ? const ClientShell() : const ShipsPublicHomePage());
}

class ClientShell extends StatefulWidget {
  const ClientShell({super.key});
  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  int index = 0;
  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        onOpenTracking: () => setState(() => index = 1),
        onOpenQuote: () => setState(() => index = 2),
        onOpenClient: _openClientSpace,
        onOpenDriver: _openDriverSpace,
      ),
      const TrackingPage(),
      const QuotePage(),
      const ShipmentsPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: kIsWeb
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (value) => setState(() => index = value),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Accueil',
                ),
                NavigationDestination(
                  icon: Icon(Icons.location_searching),
                  label: 'Suivi',
                ),
                NavigationDestination(
                  icon: Icon(Icons.request_quote_outlined),
                  label: 'Devis',
                ),
                NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  label: 'Envois',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  label: 'Profil',
                ),
              ],
            ),
    );
  }

  void _openClientSpace() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ClientSpacePage(
          startAsGuest: true,
          onOpenSection: (section) {
            Navigator.of(context).pop();
            setState(() => index = section);
          },
        ),
      ),
    );
  }

  void _openDriverSpace() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => DriverSpacePage(
          onOpenSection: (section) {
            Navigator.of(context).pop();
            setState(() => index = section);
          },
        ),
      ),
    );
  }
}
