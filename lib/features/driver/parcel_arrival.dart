// Déclaration de l'arrivée d'un colis (POST /shipments/{id}/arrive).
//
// Réservée au livreur affecté à la réservation du colis ; le colis doit être
// « in_transit » (sinon 409). Le backend ne fournit pas au livreur la liste de
// ses colis collectés : il saisit le numéro inscrit sur l'étiquette.
import 'package:flutter/material.dart';

import '../../core/status_mapping.dart';
import '../../data/models/api_models.dart';
import '../../data/services/backend_api.dart';
import '../common/feature_controller.dart';
import '../common/ui.dart';

class ParcelArrivalController extends FeatureController {
  ParcelArrivalController(this._api);

  final BackendApi _api;

  /// Colis déclarés arrivés pendant cette session, le plus récent en premier.
  final List<ApiParcel> declared = [];

  /// Numéro saisi (« 42 », « #42 » ou « colis 42 »), ou null s'il est invalide.
  static int? parseNumber(String input) {
    final digits = RegExp(r'\d+').firstMatch(input)?.group(0);
    if (digits == null || digits.length > 18) return null;
    final value = int.tryParse(digits);
    return value != null && value > 0 ? value : null;
  }

  Future<ApiParcel?> declare(String input) async {
    final id = parseNumber(input);
    if (id == null) {
      error = 'Saisissez le numéro du colis indiqué sur l’étiquette.';
      notifyListeners();
      return null;
    }
    final parcel = await run(() => _api.markArrived(id));
    if (parcel != null) {
      declared.insert(0, parcel);
      notifyListeners();
    } else if (failure?.isConflict == true) {
      error = 'Le colis #$id n’est pas en transit : son arrivée ne peut pas être déclarée.';
      notifyListeners();
    } else if (failure?.statusCode == 403 || failure?.statusCode == 404) {
      error = 'Le colis #$id ne fait pas partie de vos missions.';
      notifyListeners();
    }
    return parcel;
  }
}

class ParcelArrivalScreen extends StatefulWidget {
  const ParcelArrivalScreen({super.key, required this.controller});
  final ParcelArrivalController controller;

  @override
  State<ParcelArrivalScreen> createState() => _ParcelArrivalScreenState();
}

class _ParcelArrivalScreenState extends State<ParcelArrivalScreen> {
  final _number = TextEditingController();

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = await confirm(context, 'Déclarer l’arrivée',
        'Le colis est-il bien arrivé à destination ? L’expéditeur et le destinataire seront prévenus.');
    if (!ok) return;
    final parcel = await widget.controller.declare(_number.text);
    if (parcel != null && mounted) {
      _number.clear();
      showMessage(context, 'Arrivée du colis #${parcel.id} enregistrée.');
    }
  }

  @override
  Widget build(BuildContext context) => FeatureScaffold(
        title: 'Arrivée d’un colis',
        body: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final c = widget.controller;
            return ListView(padding: const EdgeInsets.all(16), children: [
              if (c.error != null) ErrorBanner(message: c.error!),
              Panel(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Heading('Numéro du colis'),
                    const Text(
                        'Le numéro figure sur l’étiquette du colis. Seuls les colis en transit de vos missions peuvent être déclarés.',
                        style: TextStyle(fontSize: 12, color: fMuted)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _number,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          prefixText: '# ', hintText: 'Ex. 1042'),
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 12),
                    ActionButton(
                        label: 'Déclarer l’arrivée',
                        busy: c.busy,
                        onPressed: _submit),
                  ])),
              if (c.declared.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Heading('Déclarés aujourd’hui'),
                for (final p in c.declared)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Panel(
                        child: Row(children: [
                      const Icon(Icons.check_circle, color: fGreen),
                      const SizedBox(width: 10),
                      Expanded(child: Text('Colis #${p.id}')),
                      Pill(parcelStatusLabel(p.status), color: fGreen),
                    ])),
                  ),
              ],
            ]);
          },
        ),
      );
}
