// NON ASSEMBLÉ. Liste « Mes réservations » et détail d'une réservation.
import 'package:flutter/material.dart';

import '../../core/status_mapping.dart';
import '../../data/models/api_models.dart';
import '../common/ui.dart';
import 'my_reservations_controller.dart';

Color pickupStatusColor(String status) => switch (status) {
      'collected' => fGreen,
      'cancelled' => fRed,
      'delayed' => fOrange,
      _ => fBlue,
    };

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({
    super.key,
    required this.controller,
    required this.onOpen,
    this.onNew,
  });

  final MyReservationsController controller;
  final void Function(ApiPickup pickup) onOpen;
  final VoidCallback? onNew;

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  static const _filters = <String?, String>{
    null: 'Toutes',
    'pending': 'En attente',
    'assigned': 'Assignées',
    'collected': 'Collectées',
    'cancelled': 'Annulées',
  };

  @override
  void initState() {
    super.initState();
    widget.controller.refresh();
  }

  @override
  Widget build(BuildContext context) => FeatureScaffold(
        title: 'Mes réservations',
        floatingActionButton: widget.onNew == null
            ? null
            : FloatingActionButton.extended(
                onPressed: widget.onNew,
                icon: const Icon(Icons.add),
                label: const Text('Nouvelle')),
        body: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final c = widget.controller;
            return RefreshIndicator(
              onRefresh: c.refresh,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                Wrap(spacing: 8, children: [
                  for (final entry in _filters.entries)
                    ChoiceChip(
                        label: Text(entry.value),
                        selected: c.statusFilter == entry.key,
                        onSelected: (_) => c.setFilter(entry.key)),
                ]),
                const SizedBox(height: 12),
                if (c.error != null)
                  ErrorBanner(message: c.error!, onRetry: c.refresh),
                if (c.busy && !c.loadedOnce)
                  const Center(child: CircularProgressIndicator()),
                if (c.loadedOnce && c.items.isEmpty)
                  const EmptyState(
                      text: 'Aucune réservation pour le moment.',
                      icon: Icons.calendar_month_outlined),
                for (final pickup in c.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => widget.onOpen(pickup),
                      child: Panel(
                          child: Row(children: [
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('Réservation #${pickup.id}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: fNavy)),
                              const SizedBox(height: 4),
                              Text(pickup.address,
                                  style: const TextStyle(
                                      fontSize: 12, color: fMuted)),
                              const SizedBox(height: 4),
                              Text(
                                  formatWindow(
                                      pickup.windowStart, pickup.windowEnd),
                                  style: const TextStyle(
                                      fontSize: 11, color: fMuted)),
                            ])),
                        Pill(pickupStatusLabel(pickup.status),
                            color: pickupStatusColor(pickup.status)),
                      ])),
                    ),
                  ),
                if (c.hasMore && c.loadedOnce)
                  TextButton(
                      onPressed: c.loadMore, child: const Text('Voir plus')),
              ]),
            );
          },
        ),
      );
}

class ReservationDetailScreen extends StatefulWidget {
  const ReservationDetailScreen({
    super.key,
    required this.controller,
    this.onPay,
    this.onEdit,
    this.onOpenParcel,
  });

  final ReservationDetailController controller;

  /// Ouvre le paiement de cette réservation (lib/features/payment).
  final void Function(ApiPickup pickup)? onPay;
  final void Function(ApiParcel parcel)? onOpenParcel;

  /// Ouvre la modification (adresse, créneau) ; renvoie la réservation mise à jour.
  final Future<ApiPickup?> Function(ApiPickup pickup)? onEdit;

  @override
  State<ReservationDetailScreen> createState() =>
      _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  @override
  Widget build(BuildContext context) => FeatureScaffold(
        title: 'Réservation #${widget.controller.pickup.id}',
        body: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final c = widget.controller;
            final p = c.pickup;
            return ListView(padding: const EdgeInsets.all(16), children: [
              if (c.error != null)
                ErrorBanner(message: c.error!, onRetry: c.load),
              Panel(
                  child: Column(children: [
                Row(children: [
                  const Expanded(child: Heading('Collecte')),
                  Pill(pickupStatusLabel(p.status),
                      color: pickupStatusColor(p.status)),
                ]),
                LabeledLine('Adresse', p.address),
                LabeledLine(
                    'Créneau', formatWindow(p.windowStart, p.windowEnd)),
              ])),
              if (c.awaitingReportAnswer) ...[
                const SizedBox(height: 12),
                Panel(
                    color: const Color(0xFFFFF6E8),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Heading('Nouveau créneau proposé'),
                      Text(
                          'Le livreur propose de décaler la collecte au ${formatWindow(p.windowStart, p.windowEnd)}.',
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                            child: ActionButton(
                                label: 'Refuser',
                                outline: true,
                                busy: c.busy,
                                onPressed: () => c.answerReport(accept: false))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: ActionButton(
                                label: 'Accepter',
                                busy: c.busy,
                                onPressed: () => c.answerReport(accept: true))),
                      ]),
                    ])),
              ],
              const SizedBox(height: 12),
              Panel(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                const Heading('Colis'),
                if (c.parcels.isEmpty)
                  const Text('Aucun colis.',
                      style: TextStyle(fontSize: 12, color: fMuted)),
                for (final parcel in c.parcels)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Colis #${parcel.id} · ${parcel.weightKg} kg'),
                    subtitle: Text(parcelStatusLabel(parcel.status)),
                    trailing: widget.onOpenParcel == null
                        ? null
                        : const Icon(Icons.chevron_right),
                    onTap: widget.onOpenParcel == null
                        ? null
                        : () => widget.onOpenParcel!(parcel),
                  ),
              ])),
              const SizedBox(height: 14),
              if (c.canPay && widget.onPay != null)
                ActionButton(
                    label: 'Payer cette réservation',
                    onPressed: () => widget.onPay!(p)),
              if (p.status == 'pending' && widget.onEdit != null) ...[
                ActionButton(
                    label: 'Modifier la réservation',
                    outline: true,
                    onPressed: () async {
                      final updated = await widget.onEdit!(p);
                      if (updated != null) await c.load();
                    }),
              ],
              if (c.canCancel) ...[
                const SizedBox(height: 10),
                ActionButton(
                    label: 'Annuler la réservation',
                    outline: true,
                    color: fRed,
                    busy: c.busy,
                    onPressed: () async {
                      final ok = await confirm(context, 'Annuler ?',
                          'La réservation sera annulée. Cette action est définitive.',
                          yes: 'Annuler la réservation');
                      if (ok) await c.cancel();
                    }),
              ],
            ]);
          },
        ),
      );
}
