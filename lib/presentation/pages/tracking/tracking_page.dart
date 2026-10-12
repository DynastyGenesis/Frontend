import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../presentation/widgets/primary_button.dart';

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});
  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  final controller = TextEditingController(text: 'BGO-248519');
  bool tracked = false;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
          child: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Suivre un envoi',
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.ink)),
        const SizedBox(height: 8),
        const Text('Entrez votre numéro de suivi barrelGo.',
            style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 22),
        TextField(
            controller: controller,
            decoration: const InputDecoration(
                labelText: 'Numéro de suivi', prefixIcon: Icon(Icons.search))),
        const SizedBox(height: 14),
        PrimaryButton(
            label: 'Rechercher',
            icon: Icons.location_searching,
            onPressed: () => setState(() => tracked = true)),
        if (tracked) ...[
          const SizedBox(height: 26),
          _TrackingResult(id: controller.text)
        ],
      ]));
}

class _TrackingResult extends StatelessWidget {
  final String id;
  const _TrackingResult({required this.id});
  @override
  Widget build(BuildContext context) => Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border)),
      child: Padding(
          padding: const EdgeInsets.all(20),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(id,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            const Text('En transit — livraison estimée le 10 oct. 2026',
                style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 24),
            const _Step(
                done: true,
                title: 'Colis pris en charge',
                date: '04 oct. • Lomé'),
            const _Step(
                done: true,
                title: 'Départ du centre de tri',
                date: '05 oct. • Lomé'),
            const _Step(
                done: false,
                title: 'Arrivée au centre de tri aux États-Unis',
                date: 'En cours'),
            const _Step(done: false, title: 'Livraison', date: 'Prévue')
          ])));
}

class _Step extends StatelessWidget {
  final bool done;
  final String title;
  final String date;
  const _Step({required this.done, required this.title, required this.date});
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: done ? AppColors.green : AppColors.muted),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(date,
              style: const TextStyle(color: AppColors.muted, fontSize: 12))
        ]))
      ]));
}
