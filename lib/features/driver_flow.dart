import 'package:flutter/material.dart';

import '../data/app_services.dart';
import '../data/models/api_models.dart';
import '../presentation/pages/home/ships_public_home_page.dart';
import 'account/account_controller.dart';
import 'account/account_screen.dart';
import 'common/slots_controller.dart';
import 'common/ui.dart';
import 'driver/availability_controller.dart';
import 'driver/commissions_controller.dart';
import 'driver/missions_controller.dart';
import 'driver/missions_screen.dart';
import 'driver/parcel_arrival.dart';
import 'notifications/notifications_controller.dart';
import 'notifications/notification_text.dart';
import 'notifications/notifications_screen.dart';
import 'raffle/raffle_screen.dart';

const backendDriverPages = {
  'Tableau de bord',
  'Missions disponibles',
  'Mes missions',
  'Arrivée d’un colis',
  'Historique',
  'Commissions',
  'Notifications',
  'Mon profil',
  'Tirage au sort',
};

bool openDriverBackendScreen(BuildContext context, String page) {
  final services = AppServices.instance;
  if (services == null || !backendDriverPages.contains(page)) return false;

  final navigator = Navigator.of(context);
  final api = services.api;

  if (page == 'Notifications') {
    navigator.push(MaterialPageRoute<void>(
      builder: (_) => NotificationsScreen(
        controller: NotificationsController(api),
        onOpen: (target, _) {
          if (target == NotificationTarget.mission) {
            openDriverBackendScreen(context, 'Mes missions');
          }
        },
      ),
    ));
    return true;
  }

  if (page == 'Mon profil') {
    navigator.push(MaterialPageRoute<void>(
      builder: (_) => AccountScreen(
        controller: AccountController(api),
        onLogout: () {
          services.auth.signOut();
          navigator.pushAndRemoveUntil(
            MaterialPageRoute<void>(
                builder: (_) => const ShipsPublicHomePage()),
            (_) => false,
          );
        },
      ),
    ));
    return true;
  }

  if (page == 'Tirage au sort') {
    navigator.push(MaterialPageRoute<void>(
      builder: (_) => RaffleScreen(
        controller: RaffleController(api,
            currentUserId: services.auth.session?.userId ?? ''),
        onOpenAccount: () => navigator.push(MaterialPageRoute<void>(
          builder: (_) => AccountScreen(controller: AccountController(api)),
        )),
      ),
    ));
    return true;
  }

  if (page == 'Arrivée d’un colis') {
    navigator.push(MaterialPageRoute<void>(
      builder: (_) => ParcelArrivalScreen(
        controller: ParcelArrivalController(api),
      ),
    ));
    return true;
  }

  if (page == 'Commissions') {
    navigator.push(MaterialPageRoute<void>(
      builder: (_) => CommissionsScreen(
        controller: CommissionsController(api),
      ),
    ));
    return true;
  }

  if (page == 'Historique') {
    navigator.push(MaterialPageRoute<void>(
      builder: (_) => const FeatureScaffold(
        title: 'Historique des missions',
        body: EmptyState(
          text: 'Le backend ne fournit pas encore l’historique des missions terminées.',
          icon: Icons.history,
        ),
      ),
    ));
    return true;
  }

  final missions = MissionsController(api);
  final slots = SlotsController(api);
  final availability = AvailabilityController(api, services.location);

  Route<void> detail(ApiPickup pickup) => MaterialPageRoute<void>(
        builder: (_) => MissionDetailScreen(
          mission: pickup,
          missions: missions,
          route: RouteEstimateController(api, pickup.id),
          slots: slots,
          locationReady: services.hasLocation,
          onDone: navigator.pop,
        ),
      );
  navigator.push(MaterialPageRoute<void>(
    builder: (_) => MissionsScreen(
      controller: missions,
      availability: services.hasLocation ? availability : null,
      onOpen: (pickup) => navigator.push(detail(pickup)),
      onCommissions: () => navigator.push(MaterialPageRoute<void>(
        builder: (_) => CommissionsScreen(
          controller: CommissionsController(api),
        ),
      )),
    ),
  ));
  return true;
}

class DriverBackendMenuScreen extends StatelessWidget {
  const DriverBackendMenuScreen({super.key});

  static const pages = <String, IconData>{
    'Missions disponibles': Icons.inventory_2_outlined,
    'Mes missions': Icons.local_shipping_outlined,
    'Arrivée d’un colis': Icons.where_to_vote_outlined,
    'Historique': Icons.history,
    'Commissions': Icons.receipt_long_outlined,
    'Notifications': Icons.notifications_outlined,
    'Tirage au sort': Icons.emoji_events_outlined,
    'Mon profil': Icons.person_outline,
  };

  @override
  Widget build(BuildContext context) => FeatureScaffold(
        title: 'Espace livreur',
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final entry in pages.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Panel(
                  child: ListTile(
                    leading: Icon(entry.value, color: fBlue),
                    title: Text(entry.key),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => openDriverBackendScreen(context, entry.key),
                  ),
                ),
              ),
          ],
        ),
      );
}