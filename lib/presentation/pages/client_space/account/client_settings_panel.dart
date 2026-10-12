import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'account_components.dart';

class ClientSettingsPanel extends StatefulWidget {
  final ClientAccount account;
  final String principal;
  final VoidCallback payments, support, logout;
  const ClientSettingsPanel(
      {super.key,
      required this.account,
      required this.principal,
      required this.payments,
      required this.support,
      required this.logout});
  @override
  State<ClientSettingsPanel> createState() => _SettingsState();
}

class _SettingsState extends State<ClientSettingsPanel> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.account.name),
      email = TextEditingController(text: widget.account.email),
      phone = TextEditingController(text: widget.account.phone);
  late String country = widget.account.country;
  String tab = 'Profil';
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    super.dispose();
  }

  void change(VoidCallback fn) {
    setState(fn);
    widget.account.changed();
  }

  Future<void> photo() async {
    try {
      final f = await openFile(acceptedTypeGroups: [
        const XTypeGroup(
            label: 'Photo',
            extensions: ['jpg', 'jpeg', 'png'],
            uniformTypeIdentifiers: ['public.jpeg', 'public.png'])
      ]);
      if (f == null) return;
      final bytes = await f.readAsBytes();
      if (!mounted) return;
      final error = ClientDocuments().validateFile(f.name, bytes);
      if (error != null) {
        accountNotice(context, error);
        return;
      }
      change(() => widget.account.avatar = bytes);
    } catch (e) {
      if (mounted) {
        accountNotice(context, 'Cette photo n’a pas pu être ajoutée.');
      }
    }
  }

  Future<void> address(bool collection) async {
    final ctl = TextEditingController(
        text: collection ? widget.account.collection : widget.account.address);
    final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: Text(collection
                    ? 'Adresse de collecte'
                    : 'Adresse de livraison'),
                content: TextField(
                    controller: ctl,
                    maxLines: 3,
                    decoration:
                        const InputDecoration(labelText: 'Adresse complète')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Annuler')),
                  FilledButton(
                      onPressed: () {
                        if (ctl.text.trim().isNotEmpty) {
                          Navigator.pop(ctx, true);
                        }
                      },
                      child: const Text('Enregistrer'))
                ]));
    if (ok == true && mounted) {
      change(() {
        if (collection) {
          widget.account.collection = ctl.text.trim();
        } else {
          widget.account.address = ctl.text.trim();
        }
      });
    }
    ctl.dispose();
  }

  void security() => showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
              title: const Text('Sécurité du compte'),
              content: const Text(
                  'Le changement de mot de passe et la double authentification seront disponibles avec la connexion sécurisée. Cette version présente le parcours client en démonstration.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Compris'))
              ]));
  Widget field(String label, TextEditingController ctl, {bool mail = false}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        at(label, size: 11),
        ag(7),
        TextFormField(
            controller: ctl,
            style: const TextStyle(fontSize: 12, color: accountNavy),
            decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(14)),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Champ obligatoire'
                : mail && !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v)
                    ? 'Adresse e-mail invalide'
                    : null)
      ]);
  Widget pair(Widget a, Widget b) => LayoutBuilder(
      builder: (_, c) => c.maxWidth > 450
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: a),
              const SizedBox(width: 16),
              Expanded(child: b)
            ])
          : Column(children: [a, ag(), b]));
  Widget select(String label, String value, List<String> options,
          ValueChanged<String> fn) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        at(label, size: 11),
        ag(7),
        DropdownButtonFormField<String>(
            initialValue: value,
            isExpanded: true,
            style: const TextStyle(
                fontFamily: "Open Sans", fontSize: 11, color: accountNavy),
            decoration: const InputDecoration(
                isDense: true, border: OutlineInputBorder()),
            items: options
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (s) => change(() => fn(s!)))
      ]);
  Widget toggle(
          String title, String subtitle, bool value, ValueChanged<bool> fn) =>
      Row(children: [
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              at(title, size: 12),
              at(subtitle, size: 10, color: accountMuted)
            ])),
        Switch(
            value: value,
            onChanged: (v) => change(() => fn(v)),
            activeThumbColor: Colors.white,
            activeTrackColor: accountBlue)
      ]);
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, c) {
        final a = widget.account;
        final profile = ap(Form(
            key: form,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ah('Informations personnelles', Icons.person_outline),
              ag(12),
              Row(children: [
                ClipOval(
                    child: a.avatar == null
                        ? Image.asset(
                            'assets/images/client_settings_avatar.jpg',
                            width: 76,
                            height: 76,
                            fit: BoxFit.cover)
                        : Image.memory(a.avatar!,
                            width: 76,
                            height: 76,
                            fit: BoxFit.cover,
                            errorBuilder: (_, e, s) =>
                                const Icon(Icons.person, size: 76))),
                const SizedBox(width: 18),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  ab('Changer la photo', photo,
                      outline: true, icon: Icons.camera_alt_outlined),
                  ag(7),
                  at('JPG ou PNG · 10 Mo maximum',
                      size: 10, color: accountMuted)
                ])
              ]),
              ag(12),
              pair(field('Nom complet', name),
                  field('Adresse e-mail', email, mail: true)),
              ag(10),
              pair(
                  field('Téléphone', phone),
                  select(
                      'Pays',
                      country,
                      ['Togo', 'États-Unis', 'Bénin', 'Ghana'],
                      (s) => country = s)),
              ag(12),
              Wrap(spacing: 10, runSpacing: 8, children: [
                ab('Enregistrer les modifications', () {
                  if (form.currentState!.validate()) {
                    a.saveProfile(
                        newName: name.text.trim(),
                        newEmail: email.text.trim(),
                        newPhone: phone.text.trim(),
                        newCountry: country);
                    accountNotice(
                        context, 'Profil enregistré pour cette session.');
                  }
                }, icon: Icons.save_outlined),
                ab(
                    'Annuler',
                    () => setState(() {
                          name.text = a.name;
                          email.text = a.email;
                          phone.text = a.phone;
                          country = a.country;
                        }),
                    outline: true)
              ])
            ])));
        final addresses =
            ap(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ah('Mes adresses', Icons.location_on_outlined,
              trailing: TextButton(
                  onPressed: () => address(true),
                  child: at('+ Ajouter', color: accountBlue, size: 11))),
          ag(12),
          pair(
              ap(
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                              child: at('Adresse de livraison',
                                  bold: true, size: 12)),
                          ach('Principale')
                        ]),
                        ag(10),
                        at(a.address, size: 11),
                        ag(12),
                        ab('Modifier', () => address(false), outline: true)
                      ]),
                  color: const Color(0xFFF8FBFF)),
              ap(
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        at('Adresse de collecte', bold: true, size: 12),
                        ag(10),
                        at(a.collection, size: 11),
                        ag(7),
                        at('Ajoutez les précisions de collecte.',
                            size: 10, color: accountMuted),
                        ag(8),
                        ab('Compléter', () => address(true), outline: true)
                      ]),
                  color: const Color(0xFFF8FBFF)))
        ]));
        final preferences =
            ap(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ah('Préférences', Icons.tune),
          ag(16),
          pair(
              select('Langue', a.language, ['Français'], (s) => a.language = s),
              select('Devise d’affichage', a.currency, ['USD', 'FCFA'],
                  (s) => a.currency = s)),
          ag(10),
          select(
              'Fuseau horaire',
              a.timezone,
              ['Africa/Lomé · UTC+0', 'America/New York · UTC−4'],
              (s) => a.timezone = s),
          ag(8),
          at('Préférences conservées pendant cette session.',
              size: 10, color: accountMuted)
        ]));
        final securityCard =
            ap(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ah('Sécurité du compte', Icons.verified_user_outlined),
          ag(12),
          Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  at('Mot de passe', size: 12),
                  at('••••••••••••', size: 11, color: accountMuted)
                ])),
            ab('Modifier', security, outline: true)
          ]),
          const Divider(height: 30),
          toggle('Double authentification', 'Non activée', false,
              (_) => security()),
          ag(10),
          ap(
              Row(children: [
                const Icon(Icons.lock_outline, color: accountBlue, size: 20),
                const SizedBox(width: 10),
                Expanded(
                    child: at(
                        'Ne partagez jamais vos identifiants ou codes de sécurité.',
                        size: 10,
                        color: accountBlue))
              ]),
              color: accountTint,
              pad: 12)
        ]));
        final notifications =
            ap(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ah('Notifications', Icons.notifications_outlined),
          ag(12),
          toggle('Suivi des colis', 'Recevoir les mises à jour de livraison',
              a.shipmentAlerts, (v) => a.shipmentAlerts = v),
          toggle('Paiements et factures', 'Être informé de vos transactions',
              a.paymentAlerts, (v) => a.paymentAlerts = v),
          toggle('Offres et promotions', 'Recevoir nos offres et actualités',
              a.promotions, (v) => a.promotions = v)
        ]));
        final payment =
            ap(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ah('Moyen de paiement principal', Icons.credit_card),
          ag(10),
          Row(children: [
            Container(
                color: accountNavy,
                padding: const EdgeInsets.all(9),
                child: at('VISA', bold: true, size: 19, color: Colors.white)),
            const SizedBox(width: 10),
            Expanded(child: at(widget.principal, size: 12)),
            ach('Principal')
          ]),
          ag(12),
          SizedBox(
              width: double.infinity,
              child: ab('Gérer mes moyens de paiement', widget.payments,
                  outline: true))
        ]));
        final left = Column(children: [
          if (tab == 'Profil') ...[profile, ag(), addresses, ag(), preferences],
          if (tab == 'Adresses') addresses,
          if (tab == 'Notifications') notifications,
          if (tab == 'Sécurité') securityCard,
          if (tab == 'Paiements') payment
        ]);
        final right = Column(children: [
          securityCard,
          ag(),
          notifications,
          ag(),
          payment,
          ag(),
          accountHelp(widget.support)
        ]);
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.settings_outlined, color: accountBlue, size: 34),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  at('Paramètres du compte', bold: true, size: 27),
                  at('Gérez vos informations, vos préférences et la sécurité de votre compte.',
                      size: 12, color: accountMuted)
                ])),
            TextButton(
                onPressed: widget.support,
                child: at('ⓘ Aide', color: accountBlue))
          ]),
          ag(12),
          SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                  children: [
                'Profil',
                'Adresses',
                'Notifications',
                'Sécurité',
                'Paiements'
              ]
                      .map((s) => Container(
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color: tab == s
                                          ? accountBlue
                                          : Colors.transparent,
                                      width: 3))),
                          child: TextButton(
                              onPressed: () => setState(() => tab = s),
                              child: at(s,
                                  color: tab == s ? accountBlue : accountMuted,
                                  bold: tab == s))))
                      .toList())),
          ag(12),
          ac(left, right, c.maxWidth, flex: 62),
          ag(12),
          Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 30,
              runSpacing: 10,
              children: [
                ab('Se déconnecter', widget.logout,
                    outline: true, icon: Icons.logout),
                ab('Supprimer mon compte', () async {
                  final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                              title: const Text(
                                  'Effacer les données de démonstration ?'),
                              content: const Text(
                                  'Les informations de cette session seront réinitialisées. Aucun compte réel n’est supprimé.'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Annuler')),
                                FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Réinitialiser'))
                              ]));
                  if (ok == true) {
                    a.reset();
                    widget.logout();
                  }
                }, outline: true, color: Colors.red)
              ])
        ]);
      });
}
