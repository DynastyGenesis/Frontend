// NON ASSEMBLÉ. Liste des litiges et formulaire d'ouverture.
import 'package:flutter/material.dart';

import '../../data/models/api_models_extra.dart';
import '../common/ui.dart';
import 'disputes_controller.dart';

Color disputeStatusColor(String status) => switch (status) {
      'resolved' => fGreen,
      'rejected' => fRed,
      'under_review' => fOrange,
      _ => fBlue,
    };

class DisputesScreen extends StatefulWidget {
  const DisputesScreen({super.key, required this.controller});
  final DisputesController controller;

  @override
  State<DisputesScreen> createState() => _DisputesScreenState();
}

class _DisputesScreenState extends State<DisputesScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.refresh();
  }

  @override
  Widget build(BuildContext context) => FeatureScaffold(
        title: 'Mes litiges',
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
                      text: 'Aucun litige ouvert.',
                      icon: Icons.verified_outlined),
                for (final d in c.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Panel(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                      Row(children: [
                        Expanded(
                            child: Text('${d.typeLabel} · colis #${d.parcelId}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: fNavy))),
                        Pill(d.statusLabel, color: disputeStatusColor(d.status)),
                      ]),
                      if (d.description != null && d.description!.isNotEmpty)
                        Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(d.description!,
                                style: const TextStyle(fontSize: 12))),
                      if (d.resolutionNote != null)
                        Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text('Réponse : ${d.resolutionNote}',
                                style: const TextStyle(
                                    fontSize: 12, color: fMuted))),
                    ])),
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

/// Feuille « Signaler un problème » pour un colis. Renvoie vrai si le litige est ouvert.
Future<bool> showOpenDisputeSheet(
  BuildContext context,
  DisputesController controller, {
  required int parcelId,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: _DisputeForm(controller: controller, parcelId: parcelId),
    ),
  );
  return result == true;
}

class _DisputeForm extends StatefulWidget {
  const _DisputeForm({required this.controller, required this.parcelId});
  final DisputesController controller;
  final int parcelId;

  @override
  State<_DisputeForm> createState() => _DisputeFormState();
}

class _DisputeFormState extends State<_DisputeForm> {
  String? _type;
  final _description = TextEditingController();

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final c = widget.controller;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Heading('Signaler un problème'),
              if (c.error != null) ErrorBanner(message: c.error!),
              DropdownButtonFormField<String>(
                initialValue: _type,
                isExpanded: true,
                decoration: const InputDecoration(
                    labelText: 'Type de problème',
                    border: OutlineInputBorder(),
                    isDense: true),
                items: [
                  for (final entry in disputeTypes.entries)
                    DropdownMenuItem(value: entry.key, child: Text(entry.value)),
                ],
                onChanged: (v) => setState(() => _type = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                maxLines: 4,
                maxLength: 2000,
                decoration: const InputDecoration(
                    labelText: 'Décrivez le problème (facultatif)',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              ActionButton(
                label: 'Envoyer le signalement',
                busy: c.busy,
                onPressed: _type == null
                    ? null
                    : () async {
                        final ok = await c.open(
                            parcelId: widget.parcelId,
                            type: _type!,
                            description: _description.text);
                        if (ok && context.mounted) Navigator.pop(context, true);
                      },
              ),
            ]),
          );
        },
      );
}
