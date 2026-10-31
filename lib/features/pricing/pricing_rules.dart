// NON ASSEMBLÉ. Grille de prix publique (GET /pricing/rules).
import 'package:flutter/material.dart';

import '../../data/services/backend_api.dart';
import '../common/feature_controller.dart';
import '../common/ui.dart';

/// Libellés français des réglages connus ; les autres clés sont affichées telles quelles.
const _labels = <String, (String, String)>{
  'barrel_price': ('Prix du baril', '\$'),
  'insurance_rate': ('Taux d’assurance', '%'),
  'discount_first_shipment': ('Remise premier envoi', '%'),
  'discount_self_dropoff': ('Remise dépôt par le client', '%'),
  'discount_delay_same_driver': ('Remise retard (même livreur)', '%'),
  'discount_delay_reassigned': ('Remise retard (livreur remplacé)', '%'),
  'discount_agent_delivery': ('Remise livraison par agent', '%'),
};

class PricingRulesController extends FeatureController {
  PricingRulesController(this._api);

  final BackendApi _api;
  Map<String, double> rules = {};

  Future<void> load() async {
    final result = await run(_api.pricingRules);
    if (result != null) {
      rules = result;
      notifyListeners();
    }
  }

  /// Réglages à montrer au public (la commission des livreurs reste interne).
  List<MapEntry<String, double>> get visible => [
        for (final e in rules.entries)
          if (_labels.containsKey(e.key)) e,
      ];
}

class PricingRulesScreen extends StatefulWidget {
  const PricingRulesScreen({super.key, required this.controller});
  final PricingRulesController controller;

  @override
  State<PricingRulesScreen> createState() => _PricingRulesScreenState();
}

class _PricingRulesScreenState extends State<PricingRulesScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  String _value(String key, double value) {
    final unit = _labels[key]!.$2;
    final text = value.toStringAsFixed(2).replaceAll('.', ',');
    return unit == '\$' ? '$text \$' : '$text %';
  }

  @override
  Widget build(BuildContext context) => FeatureScaffold(
        title: 'Tarifs',
        body: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final c = widget.controller;
            return ListView(padding: const EdgeInsets.all(16), children: [
              if (c.error != null) ErrorBanner(message: c.error!, onRetry: c.load),
              if (c.busy && c.rules.isEmpty)
                const Center(child: CircularProgressIndicator()),
              if (c.rules.isNotEmpty)
                Panel(
                    child: Column(children: [
                  for (final e in c.visible)
                    LabeledLine(_labels[e.key]!.$1, _value(e.key, e.value)),
                ])),
              const SizedBox(height: 10),
              const Text(
                  'Les frais kilométriques sont calculés après l’affectation d’un livreur.',
                  style: TextStyle(fontSize: 11, color: fMuted)),
            ]);
          },
        ),
      );
}
