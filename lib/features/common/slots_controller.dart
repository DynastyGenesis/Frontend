// NON ASSEMBLÉ. Choix d'un créneau de collecte (`GET /pickup-slots`).
// Le backend impose les créneaux : on renvoie exactement start/end reçus.
import 'package:flutter/material.dart';

import '../../data/models/api_models.dart';
import '../../data/services/backend_api.dart';
import 'feature_controller.dart';
import 'ui.dart';

class SlotsController extends FeatureController {
  SlotsController(this._api, {DateTime? initialDate})
      : date = initialDate ?? DateTime.now().add(const Duration(days: 1));

  final BackendApi _api;
  DateTime date;
  List<ApiSlot> slots = [];
  ApiSlot? selected;

  static String _format(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> load([DateTime? day]) async {
    if (day != null) date = day;
    selected = null;
    final result = await run(() => _api.pickupSlots(date: _format(date)));
    slots = result ?? [];
    notifyListeners();
  }

  void select(ApiSlot slot) {
    selected = slot;
    notifyListeners();
  }
}

/// Sélecteur de jour + créneaux. Appelle `controller.load()` au premier affichage.
class SlotPicker extends StatefulWidget {
  const SlotPicker({super.key, required this.controller});
  final SlotsController controller;

  @override
  State<SlotPicker> createState() => _SlotPickerState();
}

class _SlotPickerState extends State<SlotPicker> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      initialDate: widget.controller.date,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (day != null) await widget.controller.load(day);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          final c = widget.controller;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            OutlinedButton.icon(
              onPressed: _pickDay,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text('Jour : ${formatDate(c.date)}'),
            ),
            const SizedBox(height: 12),
            if (c.error != null)
              ErrorBanner(message: c.error!, onRetry: () => c.load()),
            if (c.busy && c.slots.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (c.slots.isEmpty && c.error == null)
              const Text('Aucun créneau disponible ce jour-là.',
                  style: TextStyle(fontSize: 12, color: fMuted)),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final slot in c.slots)
                ChoiceChip(
                  label: Text(formatWindow(slot.start, slot.end)),
                  selected: c.selected?.startIso == slot.startIso,
                  onSelected: (_) => c.select(slot),
                ),
            ]),
          ]);
        },
      );
}
