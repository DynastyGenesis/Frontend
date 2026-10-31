// Écran « Nouvelle réservation » : colis, collecte, paiement, récapitulatif.
import 'package:flutter/material.dart';

import '../../data/models/api_models.dart';
import '../common/slots_controller.dart';
import '../common/ui.dart';
import '../recipients/recipients_controller.dart';
import '../recipients/recipients_screen.dart';
import 'reservation_controller.dart';

class ReservationScreen extends StatefulWidget {
  const ReservationScreen({
    super.key,
    required this.controller,
    required this.onCreated,
    this.recipients,
  });

  final ReservationController controller;

  /// Carnet de destinataires : propose de choisir un code déjà enregistré.
  final RecipientsController? recipients;

  /// Appelé quand la réservation et ses colis sont enregistrés.
  final void Function(ApiPickup pickup) onCreated;

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  int _step = 0;
  final _parcelsForm = GlobalKey<FormState>();
  final _collectForm = GlobalKey<FormState>();

  ReservationController get c => widget.controller;

  final _codeFields = <ParcelDraft, TextEditingController>{};

  TextEditingController _codeField(ParcelDraft d) =>
      _codeFields.putIfAbsent(d, () => TextEditingController(text: d.recipientCode));

  Future<void> _pickRecipient(ParcelDraft d) async {
    final contact = await pickRecipient(context, widget.recipients!);
    if (contact == null) return;
    d.recipientCode = contact.code;
    _codeField(d).text = contact.code;
    c.touch();
  }

  @override
  void dispose() {
    for (final field in _codeFields.values) {
      field.dispose();
    }
    super.dispose();
  }

  static const _titles = ['Colis', 'Collecte', 'Paiement', 'Récapitulatif'];

  Future<void> _next() async {
    if (_step == 0 && !(_parcelsForm.currentState?.validate() ?? false)) return;
    if (_step == 0 && c.created != null) {
      // Envoi interrompu : la collecte est déjà enregistrée, on reprend au récapitulatif.
      setState(() => _step = 3);
      return;
    }
    if (_step == 1) {
      if (!(_collectForm.currentState?.validate() ?? false)) return;
      if (c.slots.selected == null) {
        showMessage(context, 'Choisissez un créneau de collecte.');
        return;
      }
    }
    if (_step == 1) c.loadEstimate();
    if (_step < 3) {
      setState(() => _step++);
      return;
    }
    final pickup = await c.submit();
    if (pickup != null && mounted) widget.onCreated(pickup);
  }

  @override
  Widget build(BuildContext context) => FeatureScaffold(
        title: 'Nouvelle réservation',
        body: ListenableBuilder(
          listenable: c,
          builder: (context, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _StepHeader(current: _step, titles: _titles),
              const SizedBox(height: 16),
              if (c.error != null) ErrorBanner(message: c.error!),
              if (_step == 0) _parcelsStep(),
              if (_step == 1) _collectStep(),
              if (_step == 2) _paymentStep(),
              if (_step == 3) _summaryStep(),
              const SizedBox(height: 16),
              Row(children: [
                if (_step == 3 && c.hasUnsentParcels) ...[
                  Expanded(
                      child: ActionButton(
                          label: 'Corriger les colis',
                          outline: true,
                          onPressed: () => setState(() => _step = 0))),
                  const SizedBox(width: 12),
                ] else if (_step > 0 && !c.locked) ...[
                  Expanded(
                      child: ActionButton(
                          label: 'Précédent',
                          outline: true,
                          onPressed: () => setState(() => _step--))),
                  const SizedBox(width: 12),
                ],
                Expanded(
                    child: ActionButton(
                        label: _step == 3
                            ? (c.created == null
                                ? 'Confirmer la réservation'
                                : 'Reprendre l’envoi')
                            : 'Suivant',
                        busy: c.busy,
                        onPressed: _next)),
              ]),
            ],
          ),
        ),
      );

  Widget _parcelsStep() => Form(
        key: _parcelsForm,
        child: Column(children: [
          for (var i = 0; i < c.drafts.length; i++) _parcelCard(i),
          if (!c.locked || c.hasUnsentParcels)
            TextButton.icon(
                onPressed: c.addParcel,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un colis')),
        ]),
      );

  Widget _parcelCard(int i) {
    final d = c.drafts[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Heading('Colis ${i + 1}')),
          if (c.drafts.length > 1 && !c.parcelLocked(i))
            IconButton(
                tooltip: 'Retirer ce colis',
                onPressed: () => c.removeParcel(i),
                icon: const Icon(Icons.delete_outline)),
        ]),
        TextFormField(
          controller: _codeField(d),
          enabled: !c.parcelLocked(i),
          decoration: const InputDecoration(
              labelText: 'Code du destinataire',
              helperText:
                  'Le destinataire le trouve dans Mon compte. Il doit avoir un compte BarelGo.',
              helperMaxLines: 2,
              border: OutlineInputBorder(),
              isDense: true),
          onChanged: (v) {
            d.recipientCode = v;
            c.touch();
          },
          validator: c.validateRecipient,
        ),
        if (widget.recipients != null && !c.parcelLocked(i))
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
                onPressed: () => _pickRecipient(d),
                icon: const Icon(Icons.contacts_outlined, size: 18),
                label: const Text('Choisir dans mes destinataires')),
          ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: d.weightText,
          enabled: !c.parcelLocked(i),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
              labelText: 'Poids (kg)',
              border: OutlineInputBorder(),
              isDense: true),
          onChanged: (v) => d.weightText = v,
          validator: c.validateWeight,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Je dépose le colis moi-même',
              style: TextStyle(fontSize: 13)),
          subtitle: const Text('Une remise s’applique sur le prix.',
              style: TextStyle(fontSize: 11)),
          value: d.selfDropoff,
          onChanged: c.parcelLocked(i)
              ? null
              : (v) {
                  d.selfDropoff = v;
                  c.touch();
                },
        ),
      ])),
    );
  }

  Widget _collectStep() => Form(
        key: _collectForm,
        child: Panel(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Heading('Où et quand collecter ?'),
          TextFormField(
            initialValue: c.address,
            enabled: !c.locked,
            maxLength: 255,
            decoration: const InputDecoration(
                labelText: 'Adresse de collecte aux États-Unis',
                border: OutlineInputBorder(),
                isDense: true),
            onChanged: (v) => c.address = v,
            validator: c.validateAddress,
          ),
          const SizedBox(height: 8),
          if (c.locked)
            Text('Créneau : ${formatWindow(c.slots.selected?.start, c.slots.selected?.end)}')
          else
            SlotPicker(controller: c.slots),
        ])),
      );

  Widget _paymentStep() => Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Heading('Qui paie ?'),
        const Text(
            'Le paiement se fait en ligne, après la collecte de vos colis.',
            style: TextStyle(fontSize: 12, color: fMuted)),
        RadioGroup<bool>(
          groupValue: c.recipientPays,
          onChanged: (v) {
            if (c.locked || (v == true && !c.canRecipientPay)) return;
            c.setRecipientPays(v ?? false);
          },
          child: Column(children: [
            RadioListTile<bool>(
              contentPadding: EdgeInsets.zero,
              title: const Text('Moi (expéditeur)'),
              value: false,
              enabled: !c.locked,
            ),
            RadioListTile<bool>(
              contentPadding: EdgeInsets.zero,
              title: const Text('Le destinataire'),
              subtitle: c.canRecipientPay
                  ? null
                  : const Text('Possible seulement avec un seul destinataire.',
                      style: TextStyle(fontSize: 11)),
              value: true,
              enabled: !c.locked && c.canRecipientPay,
            ),
          ]),
        ),
      ]));

  Widget _summaryStep() {
    final estimate = c.estimate;
    return Column(children: [
      Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Heading('Récapitulatif'),
        LabeledLine('Adresse de collecte', c.address.trim()),
        LabeledLine('Créneau',
            formatWindow(c.slots.selected?.start, c.slots.selected?.end)),
        LabeledLine('Nombre de colis', '${c.drafts.length}'),
        LabeledLine('Payeur', c.recipientPays ? 'Le destinataire' : 'Vous'),
      ])),
      const SizedBox(height: 12),
      Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Heading('Prix estimé'),
        if (estimate == null)
          const Text('Estimation indisponible pour le moment.',
              style: TextStyle(fontSize: 12, color: fMuted))
        else ...[
          LabeledLine('Prix du baril', usd(estimate.barrelPrice)),
          LabeledLine('Assurance', usd(estimate.insuranceAmount)),
          LabeledLine('Remise estimée', '- ${usd(estimate.estimatedDiscount)}'),
          LabeledLine('Total par colis (hors frais kilométriques)',
              usd(estimate.estimatedTotal)),
          if (c.drafts.length > 1)
            LabeledLine('Total pour ${c.drafts.length} colis',
                usd(c.estimatedTotal ?? 0)),
          if (estimate.note.isNotEmpty)
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(estimate.note,
                    style: const TextStyle(fontSize: 11, color: fMuted))),
        ],
      ])),
    ]);
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.current, required this.titles});
  final int current;
  final List<String> titles;

  @override
  Widget build(BuildContext context) => Wrap(spacing: 14, runSpacing: 8, children: [
        for (var i = 0; i < titles.length; i++)
          Row(mainAxisSize: MainAxisSize.min, children: [
            CircleAvatar(
                radius: 12,
                backgroundColor: i <= current ? fBlue : const Color(0xFFEEF2F8),
                child: Text('${i + 1}',
                    style: TextStyle(
                        fontSize: 11,
                        color: i <= current ? Colors.white : fMuted))),
            const SizedBox(width: 6),
            Text(titles[i],
                style: TextStyle(
                    fontSize: 11, color: i == current ? fBlue : fMuted)),
          ]),
      ]);
}
