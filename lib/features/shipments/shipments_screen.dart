// NON ASSEMBLÉ. Liste des colis et détail avec suivi, documents et litige.
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/status_mapping.dart';
import '../../data/models/api_models.dart';
import '../../data/models/api_models_extra.dart';
import '../common/ui.dart';
import 'shipments_controller.dart';

Color parcelStatusColor(String status) => switch (status) {
      'delivered' => fGreen,
      'cancelled' => fRed,
      'delayed_reassigned' => fOrange,
      'reserved' => fOrange,
      _ => fBlue,
    };

class ShipmentsScreen extends StatefulWidget {
  const ShipmentsScreen({super.key, required this.controller, required this.onOpen});
  final ShipmentsController controller;
  final void Function(ApiParcel parcel) onOpen;

  @override
  State<ShipmentsScreen> createState() => _ShipmentsScreenState();
}

class _ShipmentsScreenState extends State<ShipmentsScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.refresh();
  }

  @override
  Widget build(BuildContext context) => FeatureScaffold(
        title: 'Mes colis',
        body: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final c = widget.controller;
            return RefreshIndicator(
              onRefresh: c.refresh,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                Wrap(spacing: 8, children: [
                  ChoiceChip(
                      label: const Text('Tous'),
                      selected: c.role == null,
                      onSelected: (_) => c.setFilters(status: c.status)),
                  ChoiceChip(
                      label: const Text('Envoyés'),
                      selected: c.role == 'sender',
                      onSelected: (_) =>
                          c.setFilters(role: 'sender', status: c.status)),
                  ChoiceChip(
                      label: const Text('À recevoir'),
                      selected: c.role == 'recipient',
                      onSelected: (_) =>
                          c.setFilters(role: 'recipient', status: c.status)),
                ]),
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: [
                  for (final status in const [
                    null,
                    'reserved',
                    'in_transit',
                    'arrived',
                    'delivered',
                  ])
                    ChoiceChip(
                        label: Text(
                            status == null ? 'Tous statuts' : parcelStatusLabel(status)),
                        selected: c.status == status,
                        onSelected: (_) =>
                            c.setFilters(role: c.role, status: status)),
                ]),
                const SizedBox(height: 12),
                if (c.error != null)
                  ErrorBanner(message: c.error!, onRetry: c.refresh),
                if (c.busy && !c.loadedOnce)
                  const Center(child: CircularProgressIndicator()),
                if (c.loadedOnce && c.items.isEmpty)
                  const EmptyState(
                      text: 'Aucun colis pour le moment.',
                      icon: Icons.view_in_ar_outlined),
                for (final parcel in c.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      onTap: () => widget.onOpen(parcel),
                      child: Panel(
                          child: Row(children: [
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('Colis #${parcel.id}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: fNavy)),
                              const SizedBox(height: 4),
                              Text('${parcel.weightKg} kg · Réservation #${parcel.pickupId}',
                                  style: const TextStyle(
                                      fontSize: 12, color: fMuted)),
                            ])),
                        Pill(parcelStatusLabel(parcel.status),
                            color: parcelStatusColor(parcel.status)),
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

class ShipmentDetailScreen extends StatefulWidget {
  const ShipmentDetailScreen({
    super.key,
    required this.controller,
    this.onReportProblem,
  });

  final ShipmentDetailController controller;

  /// Ouvre le formulaire de litige (lib/features/disputes) pour ce colis.
  final void Function(ApiParcel parcel)? onReportProblem;

  @override
  State<ShipmentDetailScreen> createState() => _ShipmentDetailScreenState();
}

class _ShipmentDetailScreenState extends State<ShipmentDetailScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  Future<void> _open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) showMessage(context, 'Impossible d’ouvrir ce document.');
    }
  }

  @override
  Widget build(BuildContext context) => FeatureScaffold(
        title: 'Colis #${widget.controller.parcel.id}',
        body: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final c = widget.controller;
            final p = c.parcel;
            return ListView(padding: const EdgeInsets.all(16), children: [
              if (c.error != null)
                ErrorBanner(message: c.error!, onRetry: c.load),
              Panel(
                  child: Column(children: [
                Row(children: [
                  const Expanded(child: Heading('Colis')),
                  Pill(c.statusLabel, color: parcelStatusColor(p.status)),
                ]),
                LabeledLine('Poids', '${p.weightKg} kg'),
                LabeledLine('Réservation', '#${p.pickupId}'),
                LabeledLine('Vous êtes', c.isRecipient ? 'Destinataire' : 'Expéditeur'),
                LabeledLine('Dépôt par l’expéditeur', p.selfDropoff ? 'Oui' : 'Non'),
              ])),
              const SizedBox(height: 12),
              Panel(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                const Heading('Historique du suivi'),
                if (c.history.isEmpty)
                  const Text('Aucune étape enregistrée.',
                      style: TextStyle(fontSize: 12, color: fMuted)),
                for (final entry in c.history)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.check_circle_outline, color: fBlue),
                    title: Text(parcelStatusLabel(entry.status)),
                    subtitle: Text(formatDateTime(entry.createdAt) +
                        (entry.note == null ? '' : '\n${entry.note}')),
                  ),
              ])),
              const SizedBox(height: 12),
              Panel(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                const Heading('Documents'),
                if (c.documents.isEmpty)
                  const Text('Aucun document pour ce colis.',
                      style: TextStyle(fontSize: 12, color: fMuted)),
                for (final doc in c.documents)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.description_outlined, color: fBlue),
                    title: Text(doc.label),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: () => _open(doc.url),
                  ),
                const SizedBox(height: 8),
                for (final type in documentTypes.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ActionButton(
                        label: 'Ajouter : ${type.value}',
                        outline: true,
                        busy: c.busy,
                        onPressed: () async {
                          final ok = await c.addDocument(type.key);
                          if (ok && context.mounted) {
                            showMessage(context, 'Document envoyé.');
                          }
                        }),
                  ),
              ])),
              const SizedBox(height: 14),
              if (c.canConfirmDelivery)
                ActionButton(
                    label: c.isRecipient
                        ? 'J’ai bien reçu le colis'
                        : 'Confirmer la livraison',
                    busy: c.busy,
                    onPressed: () async {
                      final ok = await confirm(
                          context,
                          'Confirmer ?',
                          c.isRecipient
                              ? 'Vous confirmez avoir reçu ce colis.'
                              : 'Vous confirmez que le colis a été livré au destinataire.');
                      if (ok) await c.confirmDelivery();
                    }),
              if (widget.onReportProblem != null) ...[
                const SizedBox(height: 10),
                ActionButton(
                    label: 'Signaler un problème',
                    outline: true,
                    color: fOrange,
                    onPressed: () => widget.onReportProblem!(p)),
              ],
            ]);
          },
        ),
      );
}
