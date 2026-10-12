import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/quote_service.dart';
import '../../widgets/primary_button.dart';

class QuotePage extends StatefulWidget {
  const QuotePage({super.key});

  @override
  State<QuotePage> createState() => _QuotePageState();
}

class _QuotePageState extends State<QuotePage> {
  static const _togoToUsa = 'Togo → États-Unis';
  static const _usaToTogo = 'États-Unis → Togo';

  final from = TextEditingController();
  final to = TextEditingController();
  final weight = TextEditingController();
  String route = _togoToUsa;
  String service = 'Express';
  bool loading = false;

  bool get _isTogoToUsa => route == _togoToUsa;

  @override
  void dispose() {
    from.dispose();
    to.dispose();
    weight.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (from.text.isEmpty || to.text.isEmpty || weight.text.isEmpty) return;
    setState(() => loading = true);
    final msg = await QuoteService().requestQuote(
      from: from.text,
      to: to.text,
      weight: double.tryParse(weight.text) ?? 0,
      service: service,
      direction: route,
    );
    if (mounted) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Demander un devis',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Expédiez entre le Togo et les États-Unis, dans les deux sens.',
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 22),
            DropdownButtonFormField<String>(
              initialValue: route,
              decoration: const InputDecoration(
                labelText: 'Sens de l’expédition',
                prefixIcon: Icon(Icons.swap_horiz),
              ),
              items: const [
                DropdownMenuItem(value: _togoToUsa, child: Text(_togoToUsa)),
                DropdownMenuItem(value: _usaToTogo, child: Text(_usaToTogo)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => route = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: from,
              decoration: InputDecoration(
                labelText: _isTogoToUsa
                    ? 'Ville de départ au Togo'
                    : 'Ville de départ aux États-Unis',
                hintText: _isTogoToUsa ? 'Ex. Lomé' : 'Ex. New York',
                prefixIcon: const Icon(Icons.trip_origin),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: to,
              decoration: InputDecoration(
                labelText: _isTogoToUsa
                    ? 'Ville d’arrivée aux États-Unis'
                    : 'Ville d’arrivée au Togo',
                hintText: _isTogoToUsa ? 'Ex. New York' : 'Ex. Lomé',
                prefixIcon: const Icon(Icons.place_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: weight,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Poids (kg)',
                prefixIcon: Icon(Icons.scale_outlined),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: service,
              decoration: const InputDecoration(labelText: 'Service'),
              items: const [
                DropdownMenuItem(value: 'Express', child: Text('Express')),
                DropdownMenuItem(value: 'Standard', child: Text('Standard')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => service = value);
              },
            ),
            const SizedBox(height: 18),
            loading
                ? const Center(child: CircularProgressIndicator())
                : PrimaryButton(
                    label: 'Envoyer ma demande',
                    icon: Icons.send_outlined,
                    onPressed: submit,
                  ),
          ],
        ),
      );
}
