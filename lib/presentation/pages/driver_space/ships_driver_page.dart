import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:url_launcher/url_launcher.dart';
import '../client_space/account/account_components.dart';
import '../client_space/account/document_export.dart';
import '../home/ships_public_home_page.dart';
import 'driver_models.dart';

Future<T?> driverDialog<T>(
    {required BuildContext context, required WidgetBuilder builder}) async {
  final route = DialogRoute<T>(context: context, builder: builder);
  final result = await Navigator.of(context, rootNavigator: true).push(route);
  await route.completed;
  return result;
}

class ShipsDriverPage extends StatefulWidget {
  const ShipsDriverPage({super.key});
  @override
  State<ShipsDriverPage> createState() => _DriverState();
}

class _DriverState extends State<ShipsDriverPage> {
  final session = DriverSession();
  final scroll = ScrollController();
  String page = 'Tableau de bord', query = '', filter = 'Toutes';
  DriverMission? selected;
  static const menu = {
    'Tableau de bord': Icons.dashboard_outlined,
    'Missions disponibles': Icons.inventory_2_outlined,
    'Mes missions': Icons.local_shipping_outlined,
    'Historique': Icons.task_alt,
    'Mes revenus': Icons.account_balance_wallet_outlined,
    'Notifications': Icons.notifications_outlined,
    'Mon profil': Icons.person_outline,
    'Aide & Support': Icons.headset_mic_outlined
  };
  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  void go(String next) {
    setState(() {
      page = next;
      query = '';
      filter = 'Toutes';
    });
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  void open(DriverMission m) {
    selected = m;
    go('Détails de la mission');
  }

  void logout() => Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ShipsPublicHomePage()),
      (_) => false);
  String money(double n) => '${n.toStringAsFixed(2).replaceAll('.', ',')} \$';
  Widget photo(String name, {double size = 72}) => ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset('assets/images/client_$name.png',
          width: size, height: size, fit: BoxFit.cover));
  Widget badge(DriverMission m) => ach(m.status,
      color: m.stage == MissionStage.delivered
          ? const Color(0xFF17A46B)
          : m.stage == MissionStage.available
              ? const Color(0xFFF39B1D)
              : accountBlue);
  Widget heading(String title, String subtitle) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        at(title, size: 27, bold: true),
        ag(6),
        at(subtitle, size: 12, color: accountMuted),
        ag(20)
      ]);
  Widget nav({bool drawer = false}) => Container(
      width: 222,
      color: accountNavy,
      child: SafeArea(
          child: Column(children: [
        Padding(
            padding: const EdgeInsets.all(20),
            child: Image.asset('assets/images/client_logo.png')),
        Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: ach('ESPACE LIVREUR', color: Colors.lightBlueAccent)),
        Expanded(
            child: ListView(
                children: menu.entries
                    .map((e) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 3),
                        child: Material(
                            color: page == e.key ||
                                    page == 'Détails de la mission' &&
                                        e.key == 'Mes missions'
                                ? accountBlue
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            child: ListTile(
                                leading: Icon(e.value,
                                    color: Colors.white, size: 23),
                                title: at(e.key, size: 12, color: Colors.white),
                                onTap: () {
                                  if (drawer) Navigator.pop(context);
                                  go(e.key);
                                }))))
                    .toList())),
        Padding(
            padding: const EdgeInsets.all(14),
            child: Material(
                type: MaterialType.transparency,
                child: ListTile(
                    leading: const Icon(Icons.logout, color: Colors.white),
                    title: at('Se déconnecter', color: Colors.white, size: 12),
                    onTap: logout)))
      ])));
  @override
  Widget build(BuildContext context) => Theme(
      data: shipsPublicTheme(),
      child: LayoutBuilder(builder: (context, c) {
        final desktop = c.maxWidth >= 1000;
        return Scaffold(
            backgroundColor: const Color(0xFFF3F7FD),
            drawer: desktop ? null : Drawer(child: nav(drawer: true)),
            appBar: desktop
                ? null
                : AppBar(
                    title: const Text('Ships4US · Livreur',
                        style: TextStyle(fontSize: 16)),
                    actions: [
                        IconButton(
                            tooltip: 'Notifications',
                            onPressed: () => go('Notifications'),
                            icon: const Icon(Icons.notifications_outlined))
                      ]),
            body: Row(children: [
              if (desktop) nav(),
              Expanded(
                  child: Column(children: [
                if (desktop)
                  Container(
                      height: 72,
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(children: [
                        Expanded(
                            child: at(
                                'Votre espace de livraison · ${session.zone}',
                                size: 12,
                                color: accountMuted)),
                        IconButton(
                            tooltip: 'Notifications',
                            onPressed: () => go('Notifications'),
                            icon: Badge(
                                label: Text(
                                    '${session.notifications.length - session.read.length}'),
                                child: const Icon(Icons.notifications_outlined,
                                    color: accountNavy))),
                        const SizedBox(width: 20),
                        CircleAvatar(
                            backgroundImage: const AssetImage(
                                'assets/images/client_driver.png'),
                            radius: 20),
                        const SizedBox(width: 10),
                        Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              at(session.name, bold: true, size: 12),
                              at('Livreur partenaire',
                                  size: 10, color: accountMuted)
                            ]),
                        IconButton(
                            tooltip: 'Mon profil',
                            onPressed: () => go('Mon profil'),
                            icon: const Icon(Icons.expand_more))
                      ])),
                Expanded(
                    child: SingleChildScrollView(
                        controller: scroll,
                        padding: EdgeInsets.all(desktop ? 24 : 16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              at('Accueil  ›  Espace livreur  ›  $page',
                                  size: 10, color: accountMuted),
                              ag(18),
                              content(
                                  desktop ? c.maxWidth - 270 : c.maxWidth - 32)
                            ])))
              ]))
            ]),
            bottomNavigationBar: desktop
                ? null
                : NavigationBar(
                    selectedIndex: mobileIndex(),
                    onDestinationSelected: (i) => go([
                          'Tableau de bord',
                          'Missions disponibles',
                          'Mes missions',
                          'Historique',
                          'Mon profil'
                        ][i]),
                    destinations: const [
                        NavigationDestination(
                            icon: Icon(Icons.dashboard_outlined),
                            label: 'Accueil'),
                        NavigationDestination(
                            icon: Icon(Icons.inventory_2_outlined),
                            label: 'Missions'),
                        NavigationDestination(
                            icon: Icon(Icons.local_shipping_outlined),
                            label: 'En cours'),
                        NavigationDestination(
                            icon: Icon(Icons.task_alt), label: 'Historique'),
                        NavigationDestination(
                            icon: Icon(Icons.person_outline), label: 'Profil')
                      ]));
      }));
  int mobileIndex() =>
      {
        'Tableau de bord': 0,
        'Missions disponibles': 1,
        'Mes missions': 2,
        'Détails de la mission': 2,
        'Historique': 3,
        'Mon profil': 4
      }[page] ??
      0;
  Widget content(double width) {
    switch (page) {
      case 'Tableau de bord':
        return dashboard(width);
      case 'Missions disponibles':
      case 'Mes missions':
      case 'Historique':
        return list(width);
      case 'Détails de la mission':
        return details(width);
      case 'Mes revenus':
        return earnings();
      case 'Notifications':
        return notifications();
      case 'Mon profil':
        return profile();
      default:
        return support();
    }
  }

  Widget stats(double width) {
    final values = [
      (
        'Disponibles',
        '${session.local.where((m) => m.stage == MissionStage.available).length}',
        Icons.inventory_2_outlined
      ),
      (
        'En cours',
        '${session.local.where((m) => m.active).length}',
        Icons.local_shipping_outlined
      ),
      (
        'Livrées',
        '${session.local.where((m) => m.stage == MissionStage.delivered).length}',
        Icons.task_alt
      ),
      (
        'Revenus',
        money(session.earnings),
        Icons.account_balance_wallet_outlined
      )
    ];
    return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: values
            .map((v) => SizedBox(
                width: width >= 800 ? (width - 36) / 4 : (width - 12) / 2,
                child: ap(Row(children: [
                  Icon(v.$3, color: accountBlue, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        at(v.$1, size: 11, color: accountMuted),
                        ag(5),
                        at(v.$2, size: 22, bold: true)
                      ]))
                ]))))
            .toList());
  }

  Widget dashboard(double width) {
    final active = session.local.where((m) => m.active).toList();
    final available =
        session.local.where((m) => m.stage == MissionStage.available).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      heading('Bonjour ${session.name.split(' ').first} !',
          'Organisez vos missions et accompagnez chaque colis jusqu’à sa remise.'),
      ap(
          Row(children: [
            const Icon(Icons.local_shipping_outlined,
                color: Colors.white, size: 40),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  at('Chaque livraison compte.',
                      size: 22, bold: true, color: Colors.white),
                  ag(6),
                  at('Collectez, suivez votre trajet et confirmez la remise du colis.',
                      size: 12, color: Colors.white)
                ])),
            if (width > 700)
              ab('Voir les missions', () => go('Missions disponibles'),
                  color: const Color(0xFFF97316))
          ]),
          color: accountBlue,
          pad: 24),
      ag(18),
      stats(width),
      ag(18),
      ac(
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ah('Mes missions en cours', Icons.local_shipping_outlined,
                trailing: TextButton(
                    onPressed: () => go('Mes missions'),
                    child: const Text('Voir tout'))),
            ag(12),
            if (active.isEmpty) ap(at('Aucune mission en cours.')),
            ...active.map(missionTile),
            ag(14),
            ah('À proximité', Icons.location_on_outlined),
            ag(12),
            ...available.take(2).map(missionTile)
          ]),
          Column(children: [
            availability(),
            ag(14),
            ap(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ah('Votre journée', Icons.calendar_today_outlined),
              ag(16),
              al('Zone de service',
                  session.zone == 'Togo' ? 'Lomé et environs' : 'New York'),
              al('Véhicule', session.vehicle),
              al(
                  'Prochaine étape',
                  active.isEmpty
                      ? 'Choisir une mission'
                      : 'Collecte à préparer'),
              ag(14),
              SizedBox(
                  width: double.infinity,
                  child: ab('Consulter mon historique', () => go('Historique'),
                      outline: true))
            ])),
            ag(14),
            accountHelp(() => go('Aide & Support')),
            ag(14),
            ap(at(
                'Mode démonstration : missions et revenus fictifs. Les actions restent dans cette session.',
                size: 11,
                color: accountMuted))
          ]),
          width,
          flex: 68)
    ]);
  }

  Widget availability() =>
      ap(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.circle, color: Color(0xFF17A46B), size: 12),
          const SizedBox(width: 8),
          Expanded(
              child: at(
                  session.available
                      ? 'Vous êtes disponible'
                      : 'Vous êtes indisponible',
                  bold: true)),
          Switch(
              value: session.available,
              onChanged: (v) => setState(() => session.available = v),
              activeTrackColor: accountBlue)
        ]),
        ag(8),
        at('Activez votre disponibilité pour accepter de nouvelles missions.',
            size: 11, color: accountMuted),
        ag(14),
        DropdownButtonFormField<String>(
            initialValue: session.zone,
            isExpanded: true,
            decoration: const InputDecoration(
                labelText: 'Zone de service', isDense: true),
            items: ['Togo', 'États-Unis']
                .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s,
                        style: const TextStyle(
                            fontFamily: 'Open Sans', fontSize: 12))))
                .toList(),
            onChanged: (s) => setState(() => session.zone = s!))
      ]));
  Widget missionTile(DriverMission m) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ap(LayoutBuilder(
          builder: (_, c) =>
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  photo(m.image, size: 64),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        at(m.product, bold: true),
                        ag(4),
                        at(m.id, size: 10, color: accountBlue),
                        ag(6),
                        at(m.slot, size: 10, color: accountMuted)
                      ])),
                  if (c.maxWidth > 450)
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          badge(m),
                          ag(8),
                          at(money(m.fee), bold: true, size: 17)
                        ])
                ]),
                ag(12),
                at('${m.pickup}  →  ${m.destination}',
                    size: 11, color: accountMuted),
                ag(12),
                Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (c.maxWidth <= 450) badge(m),
                      at('${m.weight.toString().replaceAll('.', ',')} kg · ${m.client}',
                          size: 11),
                      if (m.incident != null)
                        ach('Incident signalé', color: Colors.orange),
                      ab('Voir la mission', () => open(m),
                          outline: true, icon: Icons.arrow_forward)
                    ])
              ]))));
  Widget list(double width) {
    final all = session.local
        .where((m) => page == 'Missions disponibles'
            ? m.stage == MissionStage.available
            : page == 'Historique'
                ? m.stage == MissionStage.delivered
                : m.active)
        .where((m) => '${m.id} ${m.product} ${m.client} ${m.destination}'
            .toLowerCase()
            .contains(query.toLowerCase()))
        .where((m) => filter == 'Toutes' || m.status == filter)
        .toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      heading(
          page,
          page == 'Missions disponibles'
              ? 'Choisissez une mission dans votre zone de service.'
              : page == 'Historique'
                  ? 'Retrouvez les missions terminées et leurs preuves de remise.'
                  : 'Suivez vos collectes et vos livraisons en cours.'),
      availability(),
      ag(14),
      TextField(
          onChanged: (s) => setState(() => query = s),
          decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Rechercher une mission, un colis ou un client',
              isDense: true)),
      ag(12),
      if (page == 'Mes missions')
        Wrap(
            spacing: 8,
            children: ['Toutes', 'Acceptée', 'Colis collecté', 'En livraison']
                .map((s) => ChoiceChip(
                    label: Text(s),
                    selected: filter == s,
                    onSelected: (_) => setState(() => filter = s)))
                .toList()),
      ag(14),
      if (all.isEmpty)
        ap(Column(children: [
          const Icon(Icons.inventory_2_outlined, color: accountMuted, size: 40),
          ag(12),
          at('Aucune mission à afficher.'),
          ag(8),
          at('Vérifiez votre zone de service ou votre recherche.',
              size: 11, color: accountMuted)
        ])),
      ...all.map(missionTile)
    ]);
  }

  Future<void> external(Uri uri) async {
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
          mounted)
        accountNotice(
            context, 'Cette action n’est pas disponible sur cet appareil.');
    } catch (e) {
      if (mounted) accountNotice(context, 'Impossible d’ouvrir cette action.');
    }
  }

  void advance(DriverMission m) {
    if (!session.available && m.stage == MissionStage.available) {
      accountNotice(
          context, 'Activez votre disponibilité pour accepter une mission.');
      return;
    }
    setState(() {
      if (m.advance())
        session.notifications.insert(0, '${m.id} : ${m.status.toLowerCase()}.');
      session.read.clear();
    });
  }

  Future<void> report(DriverMission m) async {
    String reason = 'Destinataire absent';
    final note = TextEditingController();
    final ok = await driverDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, update) => AlertDialog(
                    title: const Text('Signaler un incident'),
                    content: SizedBox(
                        width: 400,
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          DropdownButtonFormField<String>(
                              initialValue: reason,
                              isExpanded: true,
                              items: [
                                'Destinataire absent',
                                'Adresse introuvable',
                                'Colis endommagé',
                                'Retard de trajet',
                                'Autre'
                              ]
                                  .map((s) => DropdownMenuItem(
                                      value: s, child: Text(s)))
                                  .toList(),
                              onChanged: (s) => update(() => reason = s!)),
                          ag(14),
                          TextField(
                              controller: note,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                  labelText: 'Précisions (facultatif)'))
                        ])),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Annuler')),
                      FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Enregistrer l’incident'))
                    ])));
    if (ok == true && mounted) {
      setState(() =>
          m.incident = '$reason${note.text.isEmpty ? '' : ' · ${note.text}'}');
      accountNotice(context,
          'Incident enregistré localement. Aucun message n’a été envoyé.');
    }
    note.dispose();
  }

  Future<void> proof(DriverMission m) async {
    final recipient = TextEditingController();
    final form = GlobalKey<FormState>();
    bool confirmed = false;
    Uint8List? photoBytes;
    String? fileName;
    final ok = await driverDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, update) => AlertDialog(
                    title: const Text('Confirmer la livraison'),
                    content: SizedBox(
                        width: 430,
                        child: SingleChildScrollView(
                            child: Form(
                                key: form,
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      at(m.id, bold: true),
                                      ag(12),
                                      TextFormField(
                                          controller: recipient,
                                          decoration: const InputDecoration(
                                              labelText:
                                                  'Nom de la personne qui reçoit'),
                                          validator: (s) => s == null ||
                                                  s.trim().isEmpty
                                              ? 'Indiquez le nom du réceptionnaire.'
                                              : null),
                                      ag(14),
                                      ab(
                                          fileName ??
                                              'Ajouter une photo (facultatif)',
                                          () async {
                                        try {
                                          final f = await openFile(
                                              acceptedTypeGroups: [
                                                const XTypeGroup(
                                                    label: 'Photo',
                                                    extensions: [
                                                      'jpg',
                                                      'jpeg',
                                                      'png'
                                                    ],
                                                    uniformTypeIdentifiers: [
                                                      'public.jpeg',
                                                      'public.png'
                                                    ])
                                              ]);
                                          if (f == null) return;
                                          final b = await f.readAsBytes();
                                          final error = ClientDocuments()
                                              .validateFile(f.name, b);
                                          if (!ctx.mounted || !mounted) return;
                                          if (error != null) {
                                            accountNotice(context, error);
                                            return;
                                          }
                                          update(() {
                                            photoBytes = b;
                                            fileName = f.name;
                                          });
                                        } catch (e) {
                                          if (mounted)
                                            accountNotice(context,
                                                'Photo indisponible. Réessayez.');
                                        }
                                      },
                                          outline: true,
                                          icon: Icons.camera_alt_outlined),
                                      ag(12),
                                      CheckboxListTile(
                                          contentPadding: EdgeInsets.zero,
                                          value: confirmed,
                                          onChanged: (v) =>
                                              update(() => confirmed = v!),
                                          title: at(
                                              'Je confirme avoir remis le colis à cette personne.',
                                              size: 12)),
                                      at('Preuve enregistrée uniquement dans cette démonstration.',
                                          size: 10, color: accountMuted)
                                    ])))),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Annuler')),
                      FilledButton(
                          onPressed: () {
                            if (form.currentState!.validate() && confirmed)
                              Navigator.pop(ctx, true);
                            else if (!confirmed)
                              accountNotice(
                                  context, 'Confirmez la remise du colis.');
                          },
                          child: const Text('Valider la livraison'))
                    ])));
    if (ok == true && mounted) {
      setState(() {
        m.complete(recipient.text, confirmed, photo: photoBytes);
        session.notifications.insert(0, '${m.id} : livraison confirmée.');
        session.read.clear();
      });
      accountNotice(context,
          'Livraison confirmée. Votre historique et vos revenus sont actualisés.');
    }
    recipient.dispose();
  }

  Widget timeline(DriverMission m) => Column(
          children: List.generate(4, (i) {
        final done = m.stage.index > i;
        return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(children: [
              CircleAvatar(
                  radius: 16,
                  backgroundColor: done ? const Color(0xFF17A46B) : accountTint,
                  child: Icon(
                      done
                          ? Icons.check
                          : [
                              Icons.assignment_turned_in_outlined,
                              Icons.inventory_2_outlined,
                              Icons.local_shipping_outlined,
                              Icons.home_outlined
                            ][i],
                      size: 18,
                      color: done ? Colors.white : accountMuted)),
              const SizedBox(width: 14),
              Expanded(
                  child: at(
                      [
                        'Mission acceptée',
                        'Collecte confirmée',
                        'Trajet démarré',
                        'Colis remis'
                      ][i],
                      bold: done,
                      color: done ? accountNavy : accountMuted)),
              if (m.stage.index == i + 1 && m.stage != MissionStage.delivered)
                ach('En cours', color: accountBlue)
            ]));
      }));
  Widget details(double width) {
    final m = selected!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextButton.icon(
          onPressed: () => go(m.stage == MissionStage.delivered
              ? 'Historique'
              : m.stage == MissionStage.available
                  ? 'Missions disponibles'
                  : 'Mes missions'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Retour aux missions')),
      heading('Détails de la mission', '${m.id} · ${m.slot}'),
      ac(
          Column(children: [
            ap(Row(children: [
              photo(m.image, size: 95),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    at(m.product, bold: true, size: 18),
                    ag(8),
                    badge(m),
                    ag(8),
                    at('Poids : ${m.weight} kg · Quantité : 1',
                        size: 11, color: accountMuted)
                  ]))
            ])),
            ag(14),
            ap(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ah('Itinéraire de la mission', Icons.route_outlined),
              ag(16),
              al('Collecte', m.pickup),
              al('Destination', m.destination),
              ag(16),
              Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: accountTint,
                      borderRadius: BorderRadius.circular(8)),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined,
                                  color: accountBlue, size: 34),
                              SizedBox(width: 24),
                              Icon(Icons.more_horiz,
                                  color: accountBlue, size: 40),
                              SizedBox(width: 24),
                              Icon(Icons.local_shipping,
                                  color: accountBlue, size: 40),
                              SizedBox(width: 24),
                              Icon(Icons.more_horiz,
                                  color: accountBlue, size: 40),
                              SizedBox(width: 24),
                              Icon(Icons.location_on,
                                  color: Colors.orange, size: 34)
                            ]),
                        ag(12),
                        at(
                            m.zone == 'Togo'
                                ? 'Lomé · trajet local'
                                : 'New York · collecte locale',
                            bold: true),
                        ag(8),
                        at('Itinéraire indicatif · aucune géolocalisation en direct',
                            size: 10, color: accountMuted)
                      ])),
              ag(14),
              ab(
                  'Ouvrir l’itinéraire',
                  () => external(Uri.https('www.google.com', '/maps/dir/', {
                        'api': '1',
                        'origin': m.pickup,
                        'destination': m.destination
                      })),
                  outline: true,
                  icon: Icons.map_outlined)
            ])),
            ag(14),
            ap(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ah('Parcours du colis', Icons.local_shipping_outlined),
              ag(8),
              timeline(m),
              if (m.stage != MissionStage.delivered)
                SizedBox(
                    width: double.infinity,
                    child: ab(
                        [
                          'Accepter la mission',
                          'Confirmer la collecte',
                          'Démarrer la livraison',
                          'Confirmer la livraison'
                        ][m.stage.index],
                        () => m.stage == MissionStage.transit
                            ? proof(m)
                            : advance(m),
                        icon: Icons.arrow_forward)),
              if (m.stage == MissionStage.delivered) ...[
                ach('Livraison terminée'),
                ag(12),
                al('Remis à', m.recipient ?? m.client),
                al(
                    'Confirmation',
                    m.completedAt == null
                        ? m.slot
                        : '${m.completedAt!.day}/${m.completedAt!.month}/${m.completedAt!.year}'),
                if (m.proof != null) ...[
                  ag(12),
                  Image.memory(m.proof!,
                      height: 180,
                      errorBuilder: (_, e, s) => at('Photo indisponible'))
                ]
              ]
            ]))
          ]),
          Column(children: [
            ap(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ah('Votre rémunération', Icons.account_balance_wallet_outlined),
              ag(16),
              at(money(m.fee), bold: true, size: 30, color: accountBlue),
              ag(8),
              at('≈ ${(m.fee * 600).round()} FCFA · conversion indicative',
                  size: 10, color: accountMuted),
              ag(10),
              at('Créditée dans le relevé de démonstration après confirmation de la livraison.',
                  size: 11, color: accountMuted)
            ])),
            ag(14),
            ap(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ah('Contact destinataire', Icons.person_outline),
              ag(16),
              at(m.client, bold: true),
              ag(6),
              at(m.phone, size: 12, color: accountMuted),
              ag(16),
              ab(
                  'Appeler',
                  () => external(
                      Uri(scheme: 'tel', path: m.phone.replaceAll(' ', ''))),
                  outline: true,
                  icon: Icons.call_outlined)
            ])),
            ag(14),
            if (m.active)
              ap(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ah('Un problème ?', Icons.warning_amber_outlined),
                    ag(12),
                    if (m.incident != null) ...[
                      at(m.incident!, size: 11),
                      ag(10)
                    ],
                    ab('Signaler un incident', () => report(m),
                        outline: true, color: Colors.orange)
                  ])),
            ag(14),
            accountHelp(() => go('Aide & Support'))
          ]),
          width,
          flex: 67)
    ]);
  }

  Widget earnings() {
    final completed = session.missions
        .where((m) => m.stage == MissionStage.delivered)
        .toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      heading('Mes revenus',
          'Consultez les gains associés à vos livraisons terminées.'),
      ap(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        at('Total des missions livrées', size: 12),
        ag(8),
        at(money(session.earnings), size: 34, bold: true, color: accountBlue),
        ag(8),
        at('${completed.length} missions · données de démonstration',
            size: 11, color: accountMuted),
        ag(14),
        ab('Télécharger le relevé', () => statement(completed),
            outline: true, icon: Icons.download)
      ])),
      ag(18),
      ...completed.map((m) => ap(ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.task_alt, color: Color(0xFF17A46B)),
          title: at(m.id, bold: true),
          subtitle: at(m.product, size: 11, color: accountMuted),
          trailing: at('+ ${money(m.fee)}',
              bold: true, color: const Color(0xFF17A46B)),
          onTap: () => open(m)))),
      ag(14),
      at('Aucun paiement réel ni retrait n’est effectué dans cette version.',
          size: 11, color: accountMuted)
    ]);
  }

  Future<void> statement(List<DriverMission> rows) async {
    try {
      final s =
          'Relevé de démonstration Ships4US\nMission;Produit;Revenu USD\n${rows.map((m) => '${m.id};${m.product};${m.fee.toStringAsFixed(2)}').join('\n')}\nTotal;;${session.earnings.toStringAsFixed(2)}';
      final ok = await saveDocumentBytes(
          Uint8List.fromList([239, 187, 191, ...utf8.encode(s)]),
          'Ships4US-releve-livreur.csv',
          'text/csv');
      if (ok && mounted) accountNotice(context, 'Relevé enregistré.');
    } catch (e) {
      if (mounted)
        accountNotice(context, 'Impossible d’enregistrer le relevé.');
    }
  }

  Widget notifications() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        heading('Notifications',
            'Vos missions et les informations de votre activité.'),
        ab(
            'Tout marquer comme lu',
            () => setState(() => session.read
                .addAll(List.generate(session.notifications.length, (i) => i))),
            outline: true),
        ag(14),
        ...session.notifications.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ap(
                ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.notifications_outlined,
                        color: accountBlue),
                    title: at(e.value,
                        size: 13, bold: !session.read.contains(e.key)),
                    trailing: session.read.contains(e.key)
                        ? null
                        : const Icon(Icons.circle, color: Colors.red, size: 9),
                    onTap: () => setState(() => session.read.add(e.key))),
                color:
                    session.read.contains(e.key) ? Colors.white : accountTint)))
      ]);
  Widget profile() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        heading(
            'Mon profil', 'Vos coordonnées et vos informations de livraison.'),
        ap(Column(children: [
          const CircleAvatar(
              radius: 42,
              backgroundImage: AssetImage('assets/images/client_driver.png')),
          ag(14),
          at(session.name, bold: true, size: 22),
          ach('Livreur partenaire'),
          ag(20),
          al('Téléphone', session.phone),
          al('Véhicule', session.vehicle),
          al('Zone', session.zone),
          ag(16),
          ab('Modifier mon profil', editProfile,
              outline: true, icon: Icons.edit_outlined)
        ])),
        ag(16),
        availability(),
        ag(16),
        accountHelp(() => go('Aide & Support')),
        ag(16),
        ab('Se déconnecter', logout, outline: true, icon: Icons.logout)
      ]);
  Future<void> editProfile() async {
    final name = TextEditingController(text: session.name),
        phone = TextEditingController(text: session.phone),
        vehicle = TextEditingController(text: session.vehicle);
    final form = GlobalKey<FormState>();
    final ok = await driverDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: const Text('Modifier mon profil'),
                content: SizedBox(
                    width: 420,
                    child: Form(
                        key: form,
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          for (final entry in [
                            ('Nom complet', name),
                            ('Téléphone', phone),
                            ('Véhicule / immatriculation', vehicle)
                          ])
                            Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: TextFormField(
                                    controller: entry.$2,
                                    decoration:
                                        InputDecoration(labelText: entry.$1),
                                    validator: (s) =>
                                        s == null || s.trim().isEmpty
                                            ? 'Champ obligatoire'
                                            : null))
                        ]))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Annuler')),
                  FilledButton(
                      onPressed: () {
                        if (form.currentState!.validate())
                          Navigator.pop(ctx, true);
                      },
                      child: const Text('Enregistrer'))
                ]));
    if (ok == true && mounted)
      setState(() {
        session.name = name.text.trim();
        session.phone = phone.text.trim();
        session.vehicle = vehicle.text.trim();
      });
    name.dispose();
    phone.dispose();
    vehicle.dispose();
  }

  Widget support() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        heading('Aide & Support',
            'Un accompagnement pour vos collectes et livraisons.'),
        ...{
          'Comment accepter une mission ?':
              'Activez votre disponibilité, sélectionnez votre zone puis ouvrez Missions disponibles. Vérifiez les adresses et acceptez la mission.',
          'Comment confirmer une livraison ?':
              'Confirmez la collecte, démarrez le trajet, puis indiquez le nom de la personne qui reçoit le colis et confirmez sa remise. Une photo peut être ajoutée.',
          'Que faire si le destinataire est absent ?':
              'Utilisez Signaler un incident dans les détails de la mission. Le signalement est conservé localement dans cette démonstration.',
          'Où consulter mes gains ?':
              'Mes revenus présente les missions terminées. Le relevé peut être téléchargé ; il ne déclenche aucun paiement réel.'
        }.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ap(ExpansionTile(title: at(e.key, bold: true), children: [
              Padding(
                  padding: const EdgeInsets.all(12),
                  child: at(e.value, size: 12, color: accountMuted))
            ])))),
        ag(12),
        ap(at(
            'Cet espace est une démonstration locale. La connexion, l’affectation réelle des missions, le suivi GPS et l’envoi des incidents seront reliés aux services de l’entreprise.',
            size: 12,
            color: accountMuted))
      ]);
}
