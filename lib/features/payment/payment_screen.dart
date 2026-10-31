// NON ASSEMBLÉ. Écran de paiement d'une réservation.
import 'package:flutter/material.dart';

import '../common/ui.dart';
import 'payment_controller.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key, required this.controller, this.onPaid});
  final PaymentController controller;
  final VoidCallback? onPaid;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  Future<void> _pay() async {
    final ok = await widget.controller.pay();
    if (ok && mounted) widget.onPaid?.call();
  }

  @override
  Widget build(BuildContext context) => FeatureScaffold(
        title: 'Paiement',
        body: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final c = widget.controller;
            return ListView(padding: const EdgeInsets.all(16), children: [
              if (c.error != null)
                ErrorBanner(message: c.error!, onRetry: c.load),
              if (c.info != null)
                Panel(
                    color: const Color(0xFFEFF6FF),
                    child: Text(c.info!, style: const TextStyle(fontSize: 12))),
              if (c.stage == PaymentStage.paid)
                const Panel(
                    color: Color(0xFFE9F8F2),
                    child: Row(children: [
                      Icon(Icons.check_circle, color: fGreen),
                      SizedBox(width: 10),
                      Expanded(child: Text('Paiement confirmé. Merci !')),
                    ])),
              for (final parcel in c.parcels)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Panel(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                    Heading('Colis #${parcel.id} · ${parcel.weightKg} kg'),
                    if (c.quotes[parcel.id] == null)
                      const Text('Prix en cours de calcul…',
                          style: TextStyle(fontSize: 12, color: fMuted))
                    else ...[
                      LabeledLine('Prix du baril',
                          usd(c.quotes[parcel.id]!.barrelPrice)),
                      LabeledLine('Assurance',
                          usd(c.quotes[parcel.id]!.insuranceAmount)),
                      LabeledLine('Frais kilométriques',
                          usd(c.quotes[parcel.id]!.kmFee)),
                      LabeledLine(
                          'Péage', usd(c.quotes[parcel.id]!.tollFee)),
                      LabeledLine('Remises',
                          '- ${usd(c.quotes[parcel.id]!.discountTotal)}'),
                      LabeledLine(
                          'Total', usd(c.quotes[parcel.id]!.totalAmount)),
                    ],
                  ])),
                ),
              const SizedBox(height: 14),
              Panel(
                  child: LabeledLine('À payer', usd(c.total))),
              const SizedBox(height: 14),
              ActionButton(
                label: switch (c.stage) {
                  PaymentStage.confirming => 'Paiement en cours…',
                  PaymentStage.waitingServer => 'Validation…',
                  PaymentStage.paid => 'Payé',
                  PaymentStage.idle => 'Payer ${usd(c.total)}',
                },
                busy: c.busy || c.stage == PaymentStage.confirming ||
                    c.stage == PaymentStage.waitingServer,
                onPressed: c.stage == PaymentStage.paid || !c.quotesComplete
                    ? null
                    : _pay,
              ),
              const SizedBox(height: 8),
              const Text(
                  'Le paiement par carte est traité par Stripe. BarelGo ne voit ni ne conserve votre numéro de carte.',
                  style: TextStyle(fontSize: 11, color: fMuted)),
            ]);
          },
        ),
      );
}
