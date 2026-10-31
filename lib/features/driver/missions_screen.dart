// NON ASSEMBLÉ. Missions du livreur : liste, détail, report, commissions.
import 'package:flutter/material.dart';

import '../../core/status_mapping.dart';
import '../../data/models/api_models.dart';
import '../common/slots_controller.dart';
import '../common/ui.dart';
import 'availability_controller.dart';
import 'commissions_controller.dart';
import 'missions_controller.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({
    super.key,
    required this.controller,
    this.availability,
    required this.onOpen,
    this.onCommissions,
  });

  final MissionsController controller;
  final AvailabilityController? availability;
  final void Function(ApiPickup mission) onOpen;
  final VoidCallback? onCommissions;

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.refresh();
    widget.availability?.startTracking();
  }

  @override
  void dispose() {
    widget.availability?.stopTracking(notify: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FeatureScaffold(
        title: 'Mes missions',
        actions: [
          if (widget.onCommissions != null)
            IconButton(
                tooltip: 'Mes commissions',
                onPressed: widget.onCommissions,
                icon: const Icon(Icons.receipt_long_outlined)),
        ],
        body: ListenableBuilder(
          listenable: Listenable.merge([widget.controller, widget.availability]),
          builder: (context, _) {
            final c = widget.controller;
            final a = widget.availability;
            return RefreshIndicator(
              onRefresh: c.refresh,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                if (a != null) Panel(
                    child: Column(children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(a.available
                        ? 'Vous êtes disponible'
                        : 'Vous êtes indisponible'),
                    subtitle: Text(
                        a.lastSentAt == null
                            ? 'Position non encore envoyée.'
                            : 'Position envoyée à ${formatDateTime(a.lastSentAt)}.',
                        style: const TextStyle(fontSize: 11)),
                    value: a.available,
                    onChanged: a.busy ? null : (v) => a.setAvailable(v),
                  ),
                  if (a.error != null) ErrorBanner(message: a.error!),
                ])),
                const SizedBox(height: 12),
                if (c.error != null)
                  ErrorBanner(message: c.error!, onRetry: c.refresh),
                if (c.busy && !c.loadedOnce)
                  const Center(child: CircularProgressIndicator()),
                if (c.loadedOnce && c.items.isEmpty)
                  const EmptyState(
                      text: 'Aucune mission pour le moment.',
                      icon: Icons.local_shipping_outlined),
                for (final mission in c.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => widget.onOpen(mission),
                      child: Panel(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                        Row(children: [
                          Expanded(
                              child: Text('Mission #${mission.id}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: fNavy))),
                          Pill(pickupStatusLabel(mission.status),
                              color: mission.status == 'delayed' ? fOrange : fBlue),
                        ]),
                        const SizedBox(height: 6),
                        Text(mission.address,
                            style: const TextStyle(fontSize: 12, color: fMuted)),
                        const SizedBox(height: 4),
                        Text(formatWindow(mission.windowStart, mission.windowEnd),
                            style: const TextStyle(fontSize: 11, color: fMuted)),
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

class MissionDetailScreen extends StatelessWidget {
  const MissionDetailScreen({
    super.key,
    required this.mission,
    required this.missions,
    required this.route,
    required this.slots,
    this.locationReady = true,
    this.onDone,
  });

  final ApiPickup mission;
  final MissionsController missions;
  final RouteEstimateController route;

  /// Créneaux proposés quand le livreur demande un report.
  final SlotsController slots;
  final bool locationReady;

  /// Appelé après une action qui change la mission (accepter, refuser, collecter, reporter).
  final VoidCallback? onDone;

  Future<void> _run(BuildContext context, Future<bool> Function() action,
      String success) async {
    final ok = await action();
    if (!context.mounted) return;
    if (ok) {
      showMessage(context, success);
      onDone?.call();
    }
  }

  Future<void> _report(BuildContext context) async {
    slots.load();
    final chosen = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Heading('Proposer un nouveau créneau'),
            const Text(
                'Le client devra accepter. Le report n’est possible qu’une seule fois.',
                style: TextStyle(fontSize: 12, color: fMuted)),
            const SizedBox(height: 12),
            SlotPicker(controller: slots),
            const SizedBox(height: 12),
            ListenableBuilder(
                listenable: slots,
                builder: (_, _) => ActionButton(
                    label: 'Envoyer la proposition',
                    onPressed: slots.selected == null
                        ? null
                        : () => Navigator.pop(ctx, true))),
          ]),
        ),
      ),
    );
    final slot = slots.selected;
    if (chosen == true && slot != null && context.mounted) {
      await _run(context, () => missions.report(mission, slot),
          'Proposition envoyée au client.');
    }
  }

  @override
  Widget build(BuildContext context) => FeatureScaffold(
        title: 'Mission #${mission.id}',
        body: ListenableBuilder(
          listenable: Listenable.merge([missions, route]),
          builder: (context, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (missions.error != null) ErrorBanner(message: missions.error!),
              Panel(
                  child: Column(children: [
                Row(children: [
                  const Expanded(child: Heading('Collecte')),
                  Pill(pickupStatusLabel(mission.status),
                      color: mission.status == 'delayed' ? fOrange : fBlue),
                ]),
                LabeledLine('Adresse', mission.address),
                LabeledLine(
                    'Créneau', formatWindow(mission.windowStart, mission.windowEnd)),
              ])),
              const SizedBox(height: 12),
                if (locationReady) Panel(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                const Heading('Trajet jusqu’au client'),
                if (route.estimate != null) ...[
                  LabeledLine('Distance',
                      '${route.estimate!.distanceMiles.toStringAsFixed(1)} miles'),
                  LabeledLine('Durée',
                      '${route.estimate!.durationMinutes.round()} min'),
                  LabeledLine('Frais kilométriques estimés',
                      usd(route.estimate!.estimatedFeeUsd)),
                ],
                if (route.error != null) ErrorBanner(message: route.error!),
                ActionButton(
                    label: 'Calculer le trajet',
                    outline: true,
                    busy: route.busy,
                    onPressed: route.load),
              ])),
              const SizedBox(height: 14),
              ActionButton(
                  label: 'Accepter la mission',
                  busy: missions.busy,
                  onPressed: () => _run(context,
                      () => missions.accept(mission), 'Mission acceptée.')),
              const SizedBox(height: 10),
                if (locationReady)
                ActionButton(
                  label: 'Confirmer la collecte',
                  outline: true,
                  busy: missions.busy,
                  onPressed: () => _run(
                    context,
                    () => missions.confirmCollection(mission),
                    'Collecte confirmée.'))
                else
                const Text(
                  'La confirmation de collecte demande la position de l’appareil (GPS indisponible ici).',
                  style: TextStyle(fontSize: 11, color: fMuted)),
              const SizedBox(height: 10),
              ActionButton(
                  label: 'Proposer un autre créneau',
                  outline: true,
                  color: fOrange,
                  onPressed: () => _report(context)),
              const SizedBox(height: 10),
              ActionButton(
                  label: 'Refuser la mission',
                  outline: true,
                  color: fRed,
                  busy: missions.busy,
                  onPressed: () async {
                    final ok = await confirm(context, 'Refuser ?',
                        'La mission sera proposée à un autre livreur.',
                        yes: 'Refuser');
                    if (ok && context.mounted) {
                      await _run(context, () => missions.decline(mission),
                          'Mission refusée.');
                    }
                  }),
              const SizedBox(height: 8),
              const Text(
                  'La collecte ne peut être confirmée qu’une fois arrivé sur place : gardez la localisation activée.',
                  style: TextStyle(fontSize: 11, color: fMuted)),
            ],
          ),
        ),
      );
}

class CommissionsScreen extends StatefulWidget {
  const CommissionsScreen({super.key, required this.controller});
  final CommissionsController controller;

  @override
  State<CommissionsScreen> createState() => _CommissionsScreenState();
}

class _CommissionsScreenState extends State<CommissionsScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.refresh();
  }

  @override
  Widget build(BuildContext context) => FeatureScaffold(
        title: 'Mes commissions',
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
                if (c.cycles.isNotEmpty) ...[
                  const Heading('Cycles de facturation'),
                  for (final cycle in c.cycles)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Panel(
                          child: Row(children: [
                        Expanded(
                            child: Text(
                                '${formatDate(cycle.periodStart)} → ${formatDate(cycle.periodEnd)}')),
                        Text(usd(cycle.totalAmount),
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(width: 8),
                        Pill(cycle.status),
                      ])),
                    ),
                ],
                if (c.loadedOnce) ...[
                  const SizedBox(height: 8),
                  const Heading('Commissions par colis'),
                  if (c.commissions.isEmpty)
                    const EmptyState(
                        text: 'Aucune commission pour le moment.',
                        icon: Icons.receipt_long_outlined),
                  for (final item in c.commissions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Panel(
                          child: Row(children: [
                        Expanded(child: Text('Colis #${item.parcelId}')),
                        Text(usd(item.amount),
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                      ])),
                    ),
                ],
                if (c.hasMore)
                  TextButton(
                      onPressed: c.loadMore, child: const Text('Voir plus')),
                const SizedBox(height: 8),
                const Text(
                    'Montants dus à BarelGo sur vos livraisons. Ce ne sont pas des gains.',
                    style: TextStyle(fontSize: 11, color: fMuted)),
              ]),
            );
          },
        ),
      );
}
