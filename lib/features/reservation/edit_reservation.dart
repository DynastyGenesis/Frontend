// Modification d'une réservation (PATCH /reservations/{id}).
//
// Le backend n'accepte la modification que tant que la réservation est
// « pending » (aucun livreur affecté) ; après, il répond 422. Seuls les
// champs modifiés sont envoyés. Ouvert depuis le détail d'une réservation.
import 'package:flutter/material.dart';

import '../../data/models/api_models.dart';
import '../../data/services/backend_api.dart';
import '../common/feature_controller.dart';
import '../common/slots_controller.dart';
import '../common/ui.dart';

class EditReservationController extends FeatureController {
  EditReservationController(this._api, this.pickup)
      : address = pickup.address,
        slots = SlotsController(_api, initialDate: pickup.windowStart?.toLocal());

  final BackendApi _api;
  final SlotsController slots;
  ApiPickup pickup;
  String address;

  bool get canEdit => pickup.status == 'pending';

  bool get _addressChanged =>
      address.trim().isNotEmpty && address.trim() != pickup.address;

  bool get hasChanges => _addressChanged || slots.selected != null;

  void setAddress(String value) {
    address = value;
    notifyListeners();
  }

  /// Renvoie la réservation mise à jour, ou null en cas d'échec.
  Future<ApiPickup?> save() async {
    if (!canEdit) {
      error = 'Cette réservation est déjà prise en charge par un livreur : '
          'elle ne peut plus être modifiée.';
      notifyListeners();
      return null;
    }
    if (!hasChanges) {
      error = 'Aucune modification à enregistrer.';
      notifyListeners();
      return null;
    }
    final updated = await run(() => _api.updateReservation(
          pickup.id,
          address: _addressChanged ? address.trim() : null,
          slot: slots.selected,
        ));
    if (updated != null) {
      pickup = updated;
      notifyListeners();
    }
    return updated;
  }

  @override
  void dispose() {
    slots.dispose();
    super.dispose();
  }
}

class EditReservationScreen extends StatefulWidget {
  const EditReservationScreen({super.key, required this.controller});
  final EditReservationController controller;

  @override
  State<EditReservationScreen> createState() => _EditReservationScreenState();
}

class _EditReservationScreenState extends State<EditReservationScreen> {
  late final _address = TextEditingController(text: widget.controller.address);

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final updated = await widget.controller.save();
    if (updated != null && mounted) {
      showMessage(context, 'Réservation modifiée.');
      Navigator.pop(context, updated);
    }
  }

  @override
  Widget build(BuildContext context) => FeatureScaffold(
        title: 'Modifier la réservation',
        body: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final c = widget.controller;
            return ListView(padding: const EdgeInsets.all(16), children: [
              if (c.error != null) ErrorBanner(message: c.error!),
              if (!c.canEdit)
                const Panel(
                    color: Color(0xFFFFF7EC),
                    child: Text(
                        'Un livreur a déjà été affecté : l’adresse et le créneau ne peuvent plus être modifiés. '
                        'Vous pouvez encore annuler tant que les colis ne sont pas collectés.',
                        style: TextStyle(fontSize: 12))),
              Panel(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Heading('Adresse de collecte'),
                    TextField(
                      controller: _address,
                      enabled: c.canEdit,
                      maxLength: 255,
                      onChanged: c.setAddress,
                      decoration: const InputDecoration(
                          hintText: 'Numéro, rue, ville, État'),
                    ),
                  ])),
              const SizedBox(height: 10),
              Panel(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Heading('Créneau de collecte'),
                    Text(
                        'Actuel : ${formatWindow(c.pickup.windowStart, c.pickup.windowEnd)}',
                        style: const TextStyle(fontSize: 12, color: fMuted)),
                    const SizedBox(height: 10),
                    if (c.canEdit)
                      SlotPicker(controller: c.slots)
                    else
                      const Text('Créneau verrouillé.',
                          style: TextStyle(fontSize: 12, color: fMuted)),
                  ])),
              const SizedBox(height: 16),
              ListenableBuilder(
                listenable: c.slots,
                builder: (context, _) => ActionButton(
                  label: 'Enregistrer',
                  busy: c.busy,
                  onPressed: c.canEdit && c.hasChanges ? _save : null,
                ),
              ),
            ]);
          },
        ),
      );
}
