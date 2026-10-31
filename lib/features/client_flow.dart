// Pont entre l'espace client existant et les écrans de lib/features.
//
// Actif seulement quand le backend est configuré (AppServices.instance non
// nul). En démonstration locale, rien ne change : [openClientBackendScreen]
// renvoie false et l'écran d'origine s'affiche.
import 'package:flutter/material.dart';

import '../data/app_services.dart';
import '../data/models/api_models.dart';
import 'account/account_controller.dart';
import 'account/account_screen.dart';
import 'disputes/disputes_controller.dart';
import 'disputes/disputes_screen.dart';
import 'notifications/notifications_controller.dart';
import 'notifications/notifications_screen.dart';
import 'notifications/notification_text.dart';
import 'payment/card_payment_launcher.dart';
import 'payment/payment_controller.dart';
import 'payment/payment_screen.dart';
import 'pricing/pricing_rules.dart';
import 'raffle/raffle_screen.dart';
import 'recipients/recipients_controller.dart';
import 'recipients/recipients_screen.dart';
import '../data/local/contacts_store.dart';
import 'reservation/edit_reservation.dart';
import 'reservation/my_reservations_controller.dart';
import 'reservation/my_reservations_screen.dart';
import 'reservation/reservation_controller.dart';
import 'reservation/reservation_screen.dart';
import 'shipments/shipments_controller.dart';
import 'shipments/shipments_screen.dart';
import '../presentation/pages/home/ships_public_home_page.dart';
import 'common/ui.dart';

/// Pages de la barre latérale remplacées par un écran branché au backend.
const backendClientPages = {
  'Mes colis',
  'Accueil',
  'Colis à recevoir',
  'En transit',
  'Livrés',
  'Détails du colis',
  'Suivi en temps réel',
  'Réservations',
  'Mes réservations',
  'Historique des réservations',
  'Notifications',
  'Mes informations',
  'Litiges',
  'Tarifs',
  'Tirage au sort',
  'Mes destinataires',
};

/// Ouvre l'écran backend correspondant à [page]. Renvoie false (sans rien
/// faire) si le backend n'est pas configuré ou si la page n'est pas concernée.
bool openClientBackendScreen(
  BuildContext context,
  String page, {
  CardPaymentLauncher? launcher,
}) {
  final services = AppServices.instance;
  if (services == null || !backendClientPages.contains(page)) return false;
  final cardLauncher = launcher ?? services.launcher;
  final navigator = Navigator.of(context);
  final api = services.api;
  final currentUserId = services.auth.session?.userId ?? '';

  Route<void> shipmentDetail(ApiParcel parcel) => MaterialPageRoute<void>(
        builder: (_) => ShipmentDetailScreen(
          controller: ShipmentDetailController(api, parcel,
              currentUserId: currentUserId),
          onReportProblem: (selected) => showOpenDisputeSheet(
              context, DisputesController(api),
              parcelId: selected.id),
        ),
      );

  Route<void> detail(ApiPickup pickup) => MaterialPageRoute<void>(
        builder: (_) => ReservationDetailScreen(
          controller: ReservationDetailController(api, pickup),
          onPay: cardLauncher is UnavailableCardPaymentLauncher
              ? null
              : (p) => navigator.push(MaterialPageRoute(
                    builder: (_) => PaymentScreen(
                      controller: PaymentController(api, cardLauncher, p),
                      onPaid: navigator.pop,
                    ),
                  )),
          onEdit: (p) => navigator.push<ApiPickup>(MaterialPageRoute(
            builder: (_) => EditReservationScreen(
                controller: EditReservationController(api, p)),
          )),
          onOpenParcel: (parcel) => navigator.push(shipmentDetail(parcel)),
        ),
      );

  RecipientsController recipients() => RecipientsController(
      ContactsStore(currentUserId),
      currentUserId: currentUserId);

  Route<void> create() => MaterialPageRoute<void>(
        builder: (_) => ReservationScreen(
          recipients: recipients(),
          controller: ReservationController(api,
              currentUserId: services.auth.session?.userId ?? ''),
          onCreated: (pickup) => navigator.pushReplacement(detail(pickup)),
        ),
      );

  void openNotification(NotificationTarget target, int id) async {
    try {
      switch (target) {
        case NotificationTarget.reservation:
          navigator.push(detail(await api.reservation(id)));
        case NotificationTarget.parcel:
          final status = await api.shipmentStatus(id);
          navigator.push(shipmentDetail(status.parcel));
        case NotificationTarget.dispute:
          navigator.push(MaterialPageRoute<void>(
            builder: (_) => DisputesScreen(
              controller: DisputesController(api),
            ),
          ));
        case NotificationTarget.mission:
        case NotificationTarget.none:
          break;
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d’ouvrir cette notification.')),
        );
      }
    }
  }

  if (page == 'Réservations') {
    navigator.push(create());
  } else if (page == 'Mes réservations' ||
      page == 'Historique des réservations') {
    navigator.push(MaterialPageRoute<void>(
      builder: (_) => MyReservationsScreen(
        controller: MyReservationsController(api),
        onOpen: (pickup) => navigator.push(detail(pickup)),
        onNew: () => navigator.push(create()),
      ),
    ));
  } else if (page == 'Notifications') {
    navigator.push(MaterialPageRoute<void>(
      builder: (_) => NotificationsScreen(
        controller: NotificationsController(api),
        onOpen: openNotification,
      ),
    ));
  } else if (page == 'Litiges') {
    navigator.push(MaterialPageRoute<void>(
      builder: (_) => DisputesScreen(
        controller: DisputesController(api),
      ),
    ));
  } else if (page == 'Mes destinataires') {
    navigator.push(MaterialPageRoute<void>(
      builder: (_) => RecipientsScreen(controller: recipients()),
    ));
  } else if (page == 'Tarifs') {
    navigator.push(MaterialPageRoute<void>(
      builder: (_) => PricingRulesScreen(controller: PricingRulesController(api)),
    ));
  } else if (page == 'Tirage au sort') {
    navigator.push(MaterialPageRoute<void>(
      builder: (_) => RaffleScreen(
        controller: RaffleController(api, currentUserId: currentUserId),
        onOpenAccount: () => navigator.push(MaterialPageRoute<void>(
          builder: (_) => AccountScreen(controller: AccountController(api)),
        )),
      ),
    ));
  } else if (page == 'Mes informations') {
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
  } else {
    final controller = ShipmentsController(api);
    if (page == 'Colis à recevoir') controller.role = 'recipient';
    if (page == 'En transit') controller.status = 'in_transit';
    if (page == 'Livrés') controller.status = 'delivered';
    navigator.push(MaterialPageRoute<void>(
      builder: (_) => ShipmentsScreen(
        controller: controller,
        onOpen: (parcel) => navigator.push(shipmentDetail(parcel)),
      ),
    ));
  }
  return true;
}

class ClientBackendMenuScreen extends StatelessWidget {
  const ClientBackendMenuScreen({super.key});

  static const pages = <String, IconData>{
    'Mes colis': Icons.inventory_2_outlined,
    'Colis à recevoir': Icons.move_to_inbox_outlined,
    'En transit': Icons.local_shipping_outlined,
    'Livrés': Icons.task_alt,
    'Réservations': Icons.add_box_outlined,
    'Mes destinataires': Icons.people_outline,
    'Mes réservations': Icons.calendar_month_outlined,
    'Notifications': Icons.notifications_outlined,
    'Litiges': Icons.gavel_outlined,
    'Tarifs': Icons.sell_outlined,
    'Tirage au sort': Icons.emoji_events_outlined,
    'Mes informations': Icons.person_outline,
  };

  @override
  Widget build(BuildContext context) => FeatureScaffold(
        title: 'Espace client',
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
                    onTap: () => openClientBackendScreen(context, entry.key),
                  ),
                ),
              ),
          ],
        ),
      );
}
