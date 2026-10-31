// NON ASSEMBLÉ. Écran des notifications.
import 'package:flutter/material.dart';

import '../../data/models/api_models.dart';
import '../common/ui.dart';
import 'notification_text.dart';
import 'notifications_controller.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.controller, this.onOpen});
  final NotificationsController controller;

  /// Reçoit la cible (réservation, colis, litige, mission) et son identifiant.
  final void Function(NotificationTarget target, int id)? onOpen;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.refresh();
  }

  IconData _icon(NotificationTarget target) => switch (target) {
        NotificationTarget.parcel => Icons.local_shipping_outlined,
        NotificationTarget.reservation => Icons.calendar_month_outlined,
        NotificationTarget.dispute => Icons.gavel_outlined,
        NotificationTarget.mission => Icons.assignment_outlined,
        NotificationTarget.none => Icons.notifications_outlined,
      };

  @override
  Widget build(BuildContext context) => FeatureScaffold(
        title: 'Notifications',
        body: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final c = widget.controller;
            return RefreshIndicator(
              onRefresh: c.refresh,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                if (c.error != null)
                  ErrorBanner(message: c.error!, onRetry: c.refresh),
                if (c.busy && !c.loadedOnce)
                  const Center(child: CircularProgressIndicator()),
                if (c.loadedOnce && c.items.isEmpty)
                  const EmptyState(
                      text: 'Aucune notification.',
                      icon: Icons.notifications_none),
                for (final ApiNotification n in c.items) _tile(n),
                if (c.hasMore && c.loadedOnce)
                  TextButton(
                      onPressed: c.loadMore, child: const Text('Voir plus')),
              ]),
            );
          },
        ),
      );

  Widget _tile(ApiNotification n) {
    final view = describeNotification(n);
    final id = view.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Panel(
          color: n.isRead ? Colors.white : const Color(0xFFEAF4FF),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(_icon(view.target), color: fBlue),
            title: Text(view.title,
                style: TextStyle(
                    fontWeight: n.isRead ? FontWeight.w400 : FontWeight.w700)),
            subtitle: Text(view.body),
            trailing: n.isRead
                ? null
                : const Icon(Icons.circle, size: 9, color: fRed),
            onTap: widget.onOpen == null ||
                    id == null ||
                    view.target == NotificationTarget.none
                ? null
                : () => widget.onOpen!(view.target, id),
          )),
    );
  }
}
