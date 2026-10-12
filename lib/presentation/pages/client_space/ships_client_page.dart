import 'package:flutter/material.dart';
import 'account/account_components.dart';
import 'account/client_documents_panel.dart';
import 'account/client_settings_panel.dart';
import '../home/ships_public_home_page.dart';

const blue = Color(0xFF005BF3),
    navy = Color(0xFF08264C),
    muted = Color(0xFF73849B);

class ShipsClientPage extends StatefulWidget {
  const ShipsClientPage({super.key});
  @override
  State<ShipsClientPage> createState() => _ShipsState();
}

class _ShipsState extends State<ShipsClientPage> {
  final account = ClientAccount();
  final documents = ClientDocuments();
  @override
  void initState() {
    super.initState();
    account.addListener(syncAccount);
  }

  void syncAccount() {
    if (mounted) {
      setState(() {
        name = account.name;
        phone = account.phone;
        address = account.address;
      });
    }
  }

  @override
  void dispose() {
    account.removeListener(syncAccount);
    account.dispose();
    documents.dispose();
    super.dispose();
  }

  void logout() {
    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ShipsPublicHomePage()),
        (_) => false);
  }

  String page = 'Colis à recevoir',
      filter = 'Tous',
      query = '',
      principal = 'Visa •••• 4242';
  int selected = 1, step = 0, notification = 0;
  double balance = 125.50;
  final form = GlobalKey<FormState>();
  final inputs = <String, String>{};
  final read = <int>{};
  final prefs = [true, false, true];
  final methods = [
    'Visa •••• 4242',
    'Mastercard •••• 5678',
    'MTN Mobile Money •••• 3120',
    'Wave +228 97 65 43 21'
  ];
  final products = <Map<String, String>>[
    {
      'name': 'iPhone 15 Pro',
      'ref': 'SHP-2026-001',
      'weight': '0,5 kg',
      'category': 'Électronique',
      'date': '10 oct. 2026',
      'image': 'phone',
      'price': '980,00',
      'status': 'En attente de collecte'
    },
    {
      'name': 'Chaussures Nike Air Force 1',
      'ref': 'SHP-2026-002',
      'weight': '1,2 kg',
      'category': 'Vêtements & Accessoires',
      'date': '12 oct. 2026',
      'image': 'shoes',
      'price': '98,00',
      'status': 'En transit'
    },
    {
      'name': 'MacBook Air',
      'ref': 'SHP-2026-003',
      'weight': '1,8 kg',
      'category': 'Informatique',
      'date': '14 oct. 2026',
      'image': 'laptop',
      'price': '1 250,00',
      'status': 'Préparé'
    },
    {
      'name': 'Sac à main',
      'ref': 'SHP-2026-004',
      'weight': '0,8 kg',
      'category': 'Mode',
      'date': '16 oct. 2026',
      'image': 'bag',
      'price': '210,00',
      'status': 'En attente de collecte'
    },
    {
      'name': 'Baskets Nike',
      'ref': 'SHP-2026-005',
      'weight': '1,0 kg',
      'category': 'Sport',
      'date': '18 oct. 2026',
      'image': 'shoes',
      'price': '75,00',
      'status': 'Livré'
    }
  ];
  static const menu = <String, IconData>{
    'Accueil': Icons.home_outlined,
    'Colis à recevoir': Icons.view_in_ar_outlined,
    'En transit': Icons.local_shipping_outlined,
    'Livrés': Icons.check_box_outlined,
    'Réservations': Icons.calendar_month_outlined,
    'Portefeuille': Icons.account_balance_wallet_outlined,
    'Documents': Icons.description_outlined,
    'Notifications': Icons.notifications_outlined,
    'Paramètres': Icons.settings_outlined
  };
  void go(String s) => setState(() {
        page = s;
        filter = 'Tous';
        query = '';
      });
  Widget t(String s,
          {double size = 13, bool bold = false, Color color = navy}) =>
      Text(s,
          style: TextStyle(
              fontSize: size,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: color));
  Widget gap([double v = 14]) => SizedBox(height: v);
  Widget ico(IconData i, {Color color = blue, double size = 21}) =>
      Icon(i, color: color, size: size);
  Widget card(Widget child, {Color color = Colors.white, double pad = 20}) =>
      Container(
          width: double.infinity,
          padding: EdgeInsets.all(pad),
          decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEAF0F7))),
          child: Material(type: MaterialType.transparency, child: child));
  Widget btn(String s, VoidCallback action, {bool outline = false}) => SizedBox(
      height: 38,
      child: outline
          ? OutlinedButton(
              onPressed: action, child: t(s, size: 10, bold: true, color: blue))
          : FilledButton(
              onPressed: action,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Flexible(
                    child: Text(s,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10))),
                const SizedBox(width: 12),
                const Icon(Icons.arrow_forward, size: 15)
              ])));
  Widget badge(String s) {
    final c = s.contains('Livr') || s == 'Activée' || s == 'Réussi'
        ? const Color(0xFF1AA879)
        : s.contains('Prépar')
            ? const Color(0xFF8A50DB)
            : s.contains('attente')
                ? const Color(0xFFEA9B35)
                : blue;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: c.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(7)),
        child: t('◉  $s', size: 10, bold: true, color: c));
  }

  Widget photo(String s, {double size = 90}) => ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset('assets/images/client_$s.png',
          width: size, height: size, fit: BoxFit.cover));
  Widget line(String a, String b) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Expanded(child: t(a, size: 11, color: muted)),
        Flexible(child: t(b, size: 11, bold: true))
      ]));
  Widget heading(String a, String b, IconData i) => Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(children: [
        ico(i, size: 38),
        const SizedBox(width: 16),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              t(a, size: 25, bold: true),
              gap(4),
              t(b, size: 12, color: muted)
            ]))
      ]));
  Widget columns(Widget a, Widget b, double w) => w > 820
      ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 73, child: a),
          const SizedBox(width: 18),
          Expanded(flex: 27, child: b)
        ])
      : Column(children: [a, gap(18), b]);
  String get active =>
      ['Détails du colis', 'Suivi en temps réel'].contains(page)
          ? 'En transit'
          : ['Mes réservations', 'Historique des réservations'].contains(page)
              ? 'Réservations'
              : [
                  'Moyens de paiement',
                  'Historique des transactions',
                  'Ajouter un moyen de paiement'
                ].contains(page)
                  ? 'Portefeuille'
                  : page == 'Mes informations'
                      ? 'Paramètres'
                      : page;
  Widget sidebar({bool drawer = false}) => Container(
      width: 222,
      height: double.infinity,
      color: navy,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 22),
      child: SingleChildScrollView(
          child: Column(children: [
        Image.asset('assets/images/client_logo.png', width: 180),
        gap(26),
        ...menu.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Material(
                color: active == e.key ? blue : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: ListTile(
                    dense: true,
                    visualDensity: const VisualDensity(vertical: -1),
                    minLeadingWidth: 24,
                    leading: ico(e.value, color: Colors.white, size: 24),
                    title: t(e.key, size: 12, color: Colors.white),
                    trailing: e.key == 'Notifications'
                        ? CircleAvatar(
                            radius: 9,
                            backgroundColor: Colors.red,
                            child: t('${3 - read.where((i) => i < 3).length}',
                                size: 10, color: Colors.white))
                        : null,
                    onTap: () {
                      if (drawer) Navigator.pop(context);
                      go(e.key);
                    })))),
        gap(55),
        ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
                ['Documents', 'Paramètres'].contains(page)
                    ? 'assets/images/client_account_promo.png'
                    : 'assets/images/client_promo.png',
                width: 185,
                fit: BoxFit.cover)),
        gap(18)
      ])));
  @override
  Widget build(BuildContext context) => Theme(
      data: ThemeData(
          useMaterial3: true,
          fontFamily: 'Open Sans',
          colorScheme: ColorScheme.fromSeed(seedColor: blue, primary: blue),
          scaffoldBackgroundColor: const Color(0xFFF4F8FD),
          filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7)))),
          outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFC9D9EF)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7))))),
      child: LayoutBuilder(builder: (context, b) {
        final desktop = b.maxWidth >= 1000;
        return Scaffold(
            drawer: desktop
                ? null
                : Drawer(backgroundColor: navy, child: sidebar(drawer: true)),
            body: Row(children: [
              if (desktop) sidebar(),
              Expanded(
                  child: Column(children: [
                Container(
                    height: 72,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                            bottom: BorderSide(color: Color(0xFFEAF0F7)))),
                    child: Row(children: [
                      if (Navigator.of(context).canPop())
                        IconButton(
                            tooltip: 'Accueil public',
                            onPressed: () => Navigator.of(context).pop(),
                            icon: ico(Icons.arrow_back, color: navy)),
                      if (!desktop)
                        Builder(
                            builder: (context) => IconButton(
                                tooltip: 'Menu',
                                icon: ico(Icons.menu),
                                onPressed: () =>
                                    Scaffold.of(context).openDrawer())),
                      Expanded(
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 515),
                                  child: TextField(
                                      onChanged: (s) =>
                                          setState(() => query = s),
                                      decoration: InputDecoration(
                                          isDense: true,
                                          hintText:
                                              'Rechercher un colis, une référence…',
                                          hintStyle: const TextStyle(
                                              fontSize: 11, color: muted),
                                          prefixIcon: ico(Icons.search),
                                          filled: true,
                                          fillColor: const Color(0xFFF8FAFE),
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(9),
                                              borderSide: BorderSide.none)))))),
                      const SizedBox(width: 18),
                      IconButton(
                          tooltip: 'Notifications',
                          onPressed: () => go('Notifications'),
                          icon: Badge(
                              label: Text(
                                  '${3 - read.where((i) => i < 3).length}'),
                              child: ico(Icons.notifications_outlined,
                                  color: navy))),
                      if (b.maxWidth > 600) ...[
                        const SizedBox(width: 18),
                        InkWell(
                            onTap: () => go('Paramètres'),
                            child: Row(children: [
                              CircleAvatar(
                                  backgroundColor: const Color(0xFFD8E5F3),
                                  child: ico(Icons.person, color: navy)),
                              const SizedBox(width: 10),
                              Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    t(name, size: 11, bold: true),
                                    t('Client', size: 10)
                                  ]),
                              const SizedBox(width: 18),
                              ico(Icons.expand_more, color: navy, size: 18)
                            ]))
                      ]
                    ])),
                Expanded(
                    child: SingleChildScrollView(
                        padding: EdgeInsets.all(desktop ? 24 : 16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              t('⌂  Accueil   ›   $page',
                                  size: 10, color: muted),
                              gap(10),
                              content(b.maxWidth - (desktop ? 270 : 32))
                            ])))
              ]))
            ]));
      }));
  Widget support() => card(
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          ico(Icons.headset_mic_outlined, size: 34),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                t('Besoin d’aide ?', bold: true),
                gap(4),
                t('Notre équipe est disponible 7j/7', size: 11, color: muted)
              ]))
        ]),
        gap(20),
        SizedBox(
            width: double.infinity,
            child: btn('Contacter le support', () => go('Aide & Support')))
      ]),
      color: const Color(0xFFEAF4FF));
  Widget tabs(List<String> list) => Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Wrap(
          spacing: 9,
          runSpacing: 8,
          children: list
              .map((s) => ChoiceChip(
                  label:
                      t(s, size: 11, color: filter == s ? Colors.white : muted),
                  selected: filter == s,
                  showCheckmark: false,
                  selectedColor: blue,
                  backgroundColor: Colors.white,
                  side: BorderSide.none,
                  onSelected: (_) => setState(() => filter = s)))
              .toList()));
  Widget content(double w) {
    switch (page) {
      case 'Accueil':
        return home(w);
      case 'Détails du colis':
        return details(w);
      case 'Suivi en temps réel':
        return tracking(w);
      case 'Réservations':
        return reservation(w);
      case 'Mes réservations':
      case 'Historique des réservations':
        return reservations(w);
      case 'Portefeuille':
        return wallet(w);
      case 'Moyens de paiement':
        return payments(w);
      case 'Ajouter un moyen de paiement':
        return addPayment();
      case 'Historique des transactions':
        return Column(children: [
          heading(page, 'Consultez toutes vos opérations financières.',
              Icons.history),
          card(transactions()),
          gap(),
          btn('Retour au portefeuille', () => go('Portefeuille'), outline: true)
        ]);
      case 'Paramètres de paiement':
        return settings(w);
      case 'Paramètres':
        return ClientSettingsPanel(
            account: account,
            principal: principal,
            payments: () => go('Moyens de paiement'),
            support: () => go('Aide & Support'),
            logout: logout);
      case 'Notifications':
        return notifications(w);
      case 'Documents':
        return ClientDocumentsPanel(
            store: documents,
            account: account,
            support: () => go('Aide & Support'),
            openParcel: (ref) {
              selected = products.indexWhere((p) => p['ref'] == ref);
              if (selected < 0) selected = 0;
              go('Détails du colis');
            });
      case 'Mes informations':
        return profile();
      case 'Aide & Support':
        return help();
      default:
        return parcels(w);
    }
  }

  Widget tile(int i, {bool delivered = false, bool reserved = false}) {
    final p = products[i];
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: card(pad: 16, LayoutBuilder(builder: (context, c) {
          final info =
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            t(p['name']!, bold: true),
            gap(6),
            t('Réf. : ${p['ref']}', size: 10, color: muted),
            gap(6),
            t('♙  Poids estimé : ${p['weight']}', size: 11, color: muted),
            gap(6),
            t('◇  Catégorie : ${p['category']}', size: 10, color: muted),
            gap(14),
            t('♧  New York, USA ${delivered || reserved ? ' →  Lomé, Togo' : ''}',
                size: 10, color: muted)
          ]);
          final actions =
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            badge(delivered
                ? 'Livré'
                : reserved
                    ? p['status']!
                    : i == 2
                        ? 'Préparé'
                        : 'En attente de collecte'),
            gap(16),
            t('▦  ${delivered ? 'Livraison le' : 'Collecte prévue'} : ${p['date']}',
                size: 10, color: muted),
            gap(16),
            btn('Voir détails', () {
              selected = i;
              go('Détails du colis');
            }, outline: delivered)
          ]);
          return c.maxWidth < 540
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    photo(p['image']!, size: 76),
                    const SizedBox(width: 14),
                    Expanded(child: info)
                  ]),
                  gap(),
                  actions
                ])
              : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  photo(p['image']!),
                  const SizedBox(width: 16),
                  Expanded(child: info),
                  actions
                ]);
        })));
  }

  Widget journey({bool delivered = false}) => Column(
          children: List.generate(5, (i) {
        const titles = [
          'Réservation',
          'Collecte aux États-Unis',
          'En transit',
          'Arrivée au Togo',
          'Livraison finale'
        ];
        const subtitles = [
          'Colis enregistré avec succès',
          'Prise en charge par le transporteur',
          'Suivi en temps réel',
          'Dédouanement et acheminement',
          'À votre domicile ou point relais'
        ];
        return IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(children: [
            CircleAvatar(
                radius: 18,
                backgroundColor: delivered || i == 0
                    ? const Color(0xFFDFF7EB)
                    : i == 1
                        ? blue
                        : const Color(0xFFEAF0F8),
                child: ico(
                    delivered || i == 0
                        ? Icons.check
                        : [
                            Icons.check,
                            Icons.local_shipping_outlined,
                            Icons.flight,
                            Icons.view_in_ar_outlined,
                            Icons.home
                          ][i],
                    size: 19,
                    color: delivered || i == 0
                        ? const Color(0xFF1AA879)
                        : i == 1
                            ? Colors.white
                            : muted)),
            if (i < 4)
              Expanded(
                  child: Container(width: 2, color: const Color(0xFFEAF0F7)))
          ]),
          const SizedBox(width: 12),
          Expanded(
              child: Padding(
                  padding: const EdgeInsets.only(bottom: 27),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        t('${i + 1}. ${titles[i]}',
                            size: 11, bold: true, color: i < 2 ? blue : muted),
                        gap(5),
                        t(subtitles[i], size: 10, color: muted)
                      ])))
        ]));
      }));
  Widget parcels(double w) {
    final delivered = page == 'Livrés', transit = page == 'En transit';
    final list = List.generate(delivered ? 5 : 4, (i) => i)
        .where((i) =>
            (!transit || products[i]['status'] == 'En transit') &&
            (query.isEmpty ||
                '${products[i]['name']} ${products[i]['ref']}'
                    .toLowerCase()
                    .contains(query.toLowerCase())) &&
            (filter == 'Tous' ||
                filter == 'Livrés' && delivered ||
                filter == 'En cours' && transit ||
                filter == 'En attente' && !delivered && !transit))
        .toList();
    return columns(
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          heading(
              page,
              delivered
                  ? 'Tous vos colis livrés avec succès. Consultez les détails et l’historique de chaque livraison.'
                  : transit
                      ? 'Suivez vos colis en route vers Lomé, en temps réel.'
                      : 'Voici la liste de vos colis en attente de collecte aux États-Unis. Suivez leur état et préparez les documents nécessaires.',
              menu[page] ?? Icons.view_in_ar_outlined),
          if (!delivered && !transit) gap(18),
          if (delivered || transit)
            tabs(['Tous', delivered ? 'Livrés' : 'En cours', 'En attente']),
          if (list.isEmpty)
            card(t('Aucun colis ne correspond à votre recherche.')),
          ...list.map((i) => tile(i, delivered: delivered))
        ]),
        Column(children: [
          card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            t(
                delivered
                    ? 'Livraison(s) réussie(s)'
                    : 'Total des colis à recevoir',
                bold: true),
            gap(10),
            t(delivered ? '8' : '4', size: 30, bold: true),
            gap(8),
            t(
                delivered
                    ? 'Vous avez 8 colis livrés au total.'
                    : 'Voir tous les colis  →',
                size: 11,
                color: blue)
          ])),
          gap(),
          card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            t('Suivi de votre parcours', bold: true),
            gap(16),
            journey(delivered: delivered)
          ])),
          gap(),
          support()
        ]),
        w);
  }

  Widget home(double w) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        heading(
            'Bonjour Koffi !',
            'Voici un aperçu de vos colis et de vos dernières activités.',
            Icons.home_outlined),
        Wrap(
            spacing: 14,
            runSpacing: 12,
            children: [
              'Total colis|5',
              'En transit|2',
              'Livrés|8',
              'En attente|4'
            ]
                .map((s) => SizedBox(
                    width: w > 800 ? (w - 42) / 4 : (w - 14) / 2,
                    child: card(Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          t(s.split('|')[0], color: muted),
                          gap(),
                          t(s.split('|')[1], size: 26, bold: true)
                        ]))))
                .toList()),
        gap(20),
        card(
            Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    t('Vos colis en toute sécurité',
                        size: 22, bold: true, color: Colors.white),
                    gap(8),
                    t('États-Unis  →  Togo', color: Colors.white),
                    gap(18),
                    btn('Nouvelle réservation', () => go('Réservations'))
                  ])),
              ico(Icons.flight_takeoff, color: Colors.white, size: 65)
            ]),
            color: navy),
        gap(22),
        columns(
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              t('Derniers colis', bold: true, size: 17),
              gap(),
              tile(1),
              tile(0)
            ]),
            Column(children: [
              card(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    t('Prochaines étapes', bold: true),
                    gap(),
                    journey()
                  ])),
              gap(),
              support()
            ]),
            w)
      ]);
  Widget details(double w) {
    final p = products[selected];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      btn('Retour à la liste', () => go('Colis à recevoir'), outline: true),
      gap(),
      columns(
          Column(children: [
            card(
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 24, runSpacing: 20, children: [
                photo(p['image']!, size: 190),
                SizedBox(
                    width: w > 820 ? 320 : 260,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          t(p['name']!, size: 20, bold: true),
                          gap(),
                          t('${p['price']} \$',
                              size: 22, bold: true, color: blue),
                          gap(5),
                          t('Référence : ${p['ref']}', color: muted),
                          gap(),
                          line('Catégorie', p['category']!),
                          line('Poids estimé', p['weight']!),
                          gap(),
                          t('Caractéristiques', bold: true),
                          gap(8),
                          t(
                              selected == 1
                                  ? '✓ Marque : Nike\n✓ Modèle : Air Force 1\n✓ Couleur : Blanc / Noir\n✓ Pointure : 42 (EU)\n✓ État : Neuf'
                                  : '✓ Quantité : 1\n✓ État : Neuf\n✓ Emballage sécurisé',
                              size: 12,
                              color: muted)
                        ]))
              ]),
              gap(22),
              card(
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        t('Ce produit est ${p['status']!.toLowerCase()}',
                            bold: true, color: blue),
                        gap(5),
                        t('Arrivée estimée : ${p['date']}',
                            size: 11, color: muted)
                      ]),
                  color: const Color(0xFFEFF6FF))
            ])),
            gap(),
            card(
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              t('Historique du suivi', bold: true, color: blue),
              gap(20),
              journey(),
              btn('Voir le suivi en temps réel',
                  () => go('Suivi en temps réel'))
            ]))
          ]),
          Column(children: [
            card(
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              t('Détails du colis', bold: true),
              gap(),
              line('N° de colis', p['ref']!),
              line('Poids estimé', p['weight']!),
              line('Dimensions', '30 × 20 × 15 cm'),
              line('Devise', 'USD'),
              line('Prix du produit', '${p['price']} \$'),
              line('Frais de transport', '24,00 \$'),
              gap(),
              badge('Colis sécurisé'),
              gap(20),
              btn('Suivre mon colis', () => go('Suivi en temps réel')),
              gap(10),
              btn('Voir la facture', () => receipt(p), outline: true)
            ])),
            gap(),
            support()
          ]),
          w)
    ]);
  }

  Widget map() => ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: Image.asset('assets/images/client_map.png',
          width: double.infinity, fit: BoxFit.cover));
  Widget tracking(double w) => Column(children: [
        heading(
            'Détails du colis',
            'Suivez en temps réel votre colis et consultez toutes les informations liées à la livraison.',
            Icons.location_on_outlined),
        columns(
            Column(children: [
              tile(selected, reserved: true),
              card(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      ico(Icons.location_on_outlined),
                      const SizedBox(width: 10),
                      Expanded(child: t('Suivi en temps réel', bold: true)),
                      badge(products[selected]['status']!)
                    ]),
                    gap(),
                    map(),
                    gap(24),
                    journey(),
                    Wrap(spacing: 10, runSpacing: 10, children: [
                      btn(
                          'Voir sur Google Maps',
                          () => dialog(
                              'New York → Lomé',
                              Column(children: [
                                map(),
                                gap(),
                                t('Trajet illustratif de la maquette. Le suivi GPS n’est pas connecté.',
                                    size: 11, color: muted)
                              ]))),
                      btn('Contacter le transporteur',
                          () => contact('Jean Koffi'),
                          outline: true),
                      btn('Voir la facture', () => receipt(products[selected]),
                          outline: true),
                      btn('Signaler un problème',
                          () => contact('Signaler un problème'),
                          outline: true)
                    ])
                  ]))
            ]),
            Column(children: [
              card(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    t('Informations sur le transporteur', bold: true),
                    gap(20),
                    Row(children: [
                      photo('driver', size: 55),
                      const SizedBox(width: 14),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            t('Jean Koffi', bold: true),
                            gap(5),
                            t('Chauffeur partenaire', size: 11, color: muted),
                            gap(6),
                            t('★  4.8 (124 avis)', size: 11)
                          ])
                    ]),
                    gap(),
                    btn(
                        'Voir le profil complet',
                        () => dialog(
                            'Jean Koffi',
                            Column(children: [
                              photo('driver', size: 100),
                              gap(),
                              t('Chauffeur partenaire Ships4US', bold: true),
                              line('Évaluation', '4.8 · 124 avis'),
                              line('Trajet', 'New York → Lomé')
                            ])),
                        outline: true)
                  ])),
              gap(),
              card(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    t('Détails de la livraison', bold: true),
                    gap(),
                    line('De', 'New York, USA'),
                    line('Vers', 'Lomé, Togo'),
                    line('Distance estimée', '6 780 km'),
                    line('Durée estimée', '5 jours'),
                    line('Mode de transport', 'Avion + camion')
                  ])),
              gap(),
              documentCard()
            ]),
            w)
      ]);
  Widget field(String s, {bool number = false}) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
          key: ValueKey(s),
          minLines: s == 'Description' ? 3 : 1,
          maxLines: s == 'Description' ? 3 : 1,
          initialValue: inputs[s],
          keyboardType: number ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
              labelText: s,
              labelStyle: const TextStyle(fontSize: 12),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(7)),
              isDense: true),
          onSaved: (v) => inputs[s] = v ?? '',
          validator: (v) => v == null || v.trim().isEmpty
              ? 'Champ obligatoire'
              : number && (double.tryParse(v.replaceAll(',', '.')) ?? 0) <= 0
                  ? 'Saisissez un poids valide'
                  : null));
  Widget reservation(double w) => Column(children: [
        heading(
            'Réservations',
            'Planifiez l’enlèvement de vos colis et suivez vos réservations en toute simplicité.',
            Icons.calendar_month_outlined),
        columns(
            Column(children: [
              card(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    t('Nouvelle réservation', size: 17, bold: true),
                    gap(6),
                    t('Remplissez les informations pour réserver l’enlèvement de votre colis.',
                        size: 11, color: muted),
                    gap(25),
                    Wrap(
                        spacing: 16,
                        runSpacing: 10,
                        children: List.generate(
                            4,
                            (i) =>
                                Row(mainAxisSize: MainAxisSize.min, children: [
                                  CircleAvatar(
                                      radius: 14,
                                      backgroundColor: step == i
                                          ? blue
                                          : const Color(0xFFEEF2F8),
                                      child: t('${i + 1}',
                                          size: 11,
                                          color: step == i
                                              ? Colors.white
                                              : muted)),
                                  const SizedBox(width: 7),
                                  t(
                                      [
                                        'Informations colis',
                                        'Lieu de collecte',
                                        'Destination',
                                        'Récapitulatif'
                                      ][i],
                                      size: 10,
                                      color: step == i ? blue : muted)
                                ]))),
                    gap(25),
                    Form(
                        key: form,
                        child: Column(children: [
                          if (step == 0) ...[
                            LayoutBuilder(builder: (context, bounds) {
                              final fields = [
                                field('Type de colis'),
                                field('Poids estimé (kg)', number: true),
                                field('Catégorie')
                              ];
                              return bounds.maxWidth > 540
                                  ? Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                          Expanded(child: fields[0]),
                                          const SizedBox(width: 14),
                                          Expanded(child: fields[1]),
                                          const SizedBox(width: 14),
                                          Expanded(child: fields[2])
                                        ])
                                  : Column(children: fields);
                            }),
                            field('Description')
                          ],
                          if (step == 1) ...[
                            field('Adresse de collecte aux États-Unis'),
                            field('Ville de collecte'),
                            field('Téléphone expéditeur'),
                            field('Date de collecte souhaitée')
                          ],
                          if (step == 2) ...[
                            field('Nom du destinataire'),
                            field('Téléphone destinataire'),
                            field('Adresse de livraison à Lomé')
                          ],
                          if (step == 3) ...[
                            ...inputs.entries.map((e) => line(e.key, e.value)),
                            line('Frais de transport estimés', '24,00 \$'),
                            gap(),
                            t('Paiement de démonstration · aucun débit réel.',
                                size: 11, color: muted)
                          ],
                          gap(),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (step > 0) ...[
                                  btn('Précédent', () {
                                    form.currentState!.save();
                                    setState(() => step--);
                                  }, outline: true),
                                  const SizedBox(width: 12)
                                ],
                                btn(
                                    step == 3
                                        ? 'Confirmer la réservation'
                                        : 'Suivant', () {
                                  if (!form.currentState!.validate()) return;
                                  form.currentState!.save();
                                  if (step < 3) {
                                    setState(() => step++);
                                  } else {
                                    setState(() {
                                      products.add({
                                        'name': inputs['Description']!,
                                        'ref':
                                            'SHP-2026-${(products.length + 1).toString().padLeft(3, '0')}',
                                        'weight':
                                            '${inputs['Poids estimé (kg)']} kg',
                                        'category': inputs['Catégorie']!,
                                        'date': inputs[
                                            'Date de collecte souhaitée']!,
                                        'image': 'bag',
                                        'price': '24,00',
                                        'status': 'En attente de collecte'
                                      });
                                      step = 0;
                                      inputs.clear();
                                    });
                                    go('Mes réservations');
                                    notice(
                                        'Réservation confirmée pour cette session de démonstration.');
                                  }
                                })
                              ])
                        ]))
                  ])),
              gap(),
              card(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(spacing: 20, runSpacing: 10, children: [
                      t('Mes réservations récentes', bold: true),
                      btn('Voir toutes les réservations',
                          () => go('Mes réservations'),
                          outline: true)
                    ]),
                    gap(),
                    ...List.generate(
                        3,
                        (i) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: ico(Icons.view_in_ar_outlined),
                            title:
                                t('RES-2026-00${48 - i}', bold: true, size: 12),
                            subtitle:
                                t(products[i]['name']!, size: 10, color: muted),
                            trailing: badge(products[i]['status']!),
                            onTap: () {
                              selected = i;
                              go('Mes réservations');
                            }))
                  ]))
            ]),
            Column(children: [
              support(),
              gap(),
              card(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    t('Avantages de la réservation', bold: true),
                    gap(20),
                    ...[
                      'Enlèvement à domicile',
                      'Suivi en temps réel',
                      'Tarifs transparents',
                      'Assurance incluse'
                    ].map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 22),
                        child: Row(children: [
                          ico(Icons.verified_outlined),
                          const SizedBox(width: 12),
                          Expanded(child: t(s, size: 12))
                        ])))
                  ])),
              gap(),
              card(Column(children: [
                t('Statistiques des réservations', bold: true),
                line('Total', '${12 + products.length - 5}'),
                line('En cours', '4'),
                line('Livrées', '7'),
                line('Annulées', '1')
              ]))
            ]),
            w)
      ]);
  Widget reservations(double w) => Column(children: [
        heading(
            page,
            'Consultez l’historique et le statut de toutes vos réservations de colis.',
            Icons.calendar_month_outlined),
        columns(
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              tabs(['Tous', 'En cours', 'Livrées', 'Annulées']),
              Wrap(spacing: 10, runSpacing: 10, children: [
                btn('Nouvelle réservation', () => go('Réservations')),
                btn('Historique des réservations',
                    () => go('Historique des réservations'),
                    outline: true)
              ]),
              gap(),
              ...List.generate(products.length, (i) => i)
                  .where((i) =>
                      filter == 'Tous' ||
                      filter == 'Livrées' && products[i]['status'] == 'Livré' ||
                      filter == 'En cours' && products[i]['status'] != 'Livré')
                  .map((i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: card(InkWell(
                          onTap: () => setState(() => selected = i),
                          child: Row(children: [
                            photo(products[i]['image']!, size: 80),
                            const SizedBox(width: 16),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  t(products[i]['name']!, bold: true),
                                  gap(6),
                                  t('RES-2026-00${48 - i}',
                                      size: 10, color: blue),
                                  gap(8),
                                  t('New York, USA  →  Lomé, Togo',
                                      size: 10, color: muted),
                                  gap(8),
                                  badge(products[i]['status']!)
                                ])),
                            ico(Icons.chevron_right)
                          ])))))
            ]),
            card(
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              t('Détails de la réservation', bold: true),
              gap(),
              photo(products[selected]['image']!),
              gap(),
              t(products[selected]['name']!, bold: true),
              gap(),
              badge(products[selected]['status']!),
              gap(),
              line('Date de réservation', '05 oct. 2026 à 14:20'),
              line('Collecte prévue', products[selected]['date']!),
              line('Destination', 'Lomé, Togo'),
              gap(),
              t('Parcours de votre colis', bold: true),
              gap(),
              journey(),
              btn('Voir la facture', () => receipt(products[selected]))
            ])),
            w)
      ]);
  Widget transactions() => Column(
      children: List.generate(
          6,
          (i) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ico(
                  i % 3 == 0
                      ? Icons.account_balance_wallet_outlined
                      : Icons.view_in_ar_outlined,
                  size: 18),
              title: t(
                  [
                    'Rechargement par Mobile Money',
                    'Réservation colis #RES-2026-0048',
                    'Réservation colis #RES-2026-0047',
                    'Frais de transport',
                    'Rechargement par carte bancaire',
                    'Remboursement réservation'
                  ][i],
                  size: 11),
              subtitle:
                  t('${7 - i} oct. 2026  ·  10:45', size: 10, color: muted),
              trailing: t(
                  [
                    '+ 50,00 \$',
                    '− 98,00 \$',
                    '− 1 250,00 \$',
                    '− 24,00 \$',
                    '+ 100,00 \$',
                    '+ 75,00 \$'
                  ][i],
                  size: 11,
                  bold: true,
                  color: i == 0 || i > 3 ? const Color(0xFF1AA879) : navy),
              onTap: () => dialog(
                  'Détails de la transaction',
                  Column(children: [
                    line('Référence', 'TXN-2026100${7 - i}-4567'),
                    line('Date', '${7 - i} oct. 2026 à 10:45'),
                    line('Moyen de paiement', principal),
                    line('Statut', 'Réussi · Démonstration'),
                    gap(),
                    btn('Voir le reçu', () {
                      Navigator.pop(context);
                      receipt(products[1]);
                    })
                  ])))));
  Widget wallet(double w) => Column(children: [
        heading(
            'Mon portefeuille',
            'Gérez vos fonds, suivez vos transactions et rechargez votre compte.',
            Icons.account_balance_wallet_outlined),
        columns(
            Column(children: [
              card(Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 20,
                  runSpacing: 20,
                  children: [
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          t('Solde disponible', color: muted),
                          gap(8),
                          t('${balance.toStringAsFixed(2).replaceAll('.', ',')} \$',
                              size: 28, bold: true),
                          t('≈ ${(balance * 600).round()} FCFA',
                              size: 11, color: muted)
                        ]),
                    Wrap(spacing: 10, runSpacing: 10, children: [
                      btn('Recharger', () => money(false)),
                      btn('Retirer', () => money(true), outline: true),
                      btn('Historique', () => go('Historique des transactions'),
                          outline: true)
                    ])
                  ])),
              gap(),
              Wrap(spacing: 12, runSpacing: 10, children: [
                btn('Mes moyens de paiement', () => go('Moyens de paiement'),
                    outline: true),
                btn('Mes coupons', coupons, outline: true),
                btn('Paramètres de paiement',
                    () => go('Paramètres de paiement'),
                    outline: true)
              ]),
              gap(22),
              card(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                          child: t('Dernières transactions',
                              bold: true, size: 16)),
                      TextButton(
                          onPressed: () => go('Historique des transactions'),
                          child: t('Voir tout l’historique  →',
                              size: 10, color: blue))
                    ]),
                    gap(),
                    transactions()
                  ]))
            ]),
            Column(children: [
              card(
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        t('Solde disponible', color: Colors.white),
                        gap(),
                        t('${balance.toStringAsFixed(2)} \$',
                            size: 28, bold: true, color: Colors.white),
                        gap(20),
                        btn('Recharger', () => money(false))
                      ]),
                  color: blue),
              gap(),
              card(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    t('Aperçu du portefeuille', bold: true),
                    line('Total dépôts', '175,00 \$'),
                    line('Total dépenses', '123,50 \$')
                  ])),
              gap(),
              card(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    t('Moyens de paiement', bold: true),
                    gap(),
                    line('Mobile Money (TMoney)', '+228 90 12 34 56'),
                    line('Carte bancaire', '•••• 4242'),
                    gap(),
                    btn('Gérer mes moyens de paiement',
                        () => go('Moyens de paiement'),
                        outline: true)
                  ])),
              gap(),
              support()
            ]),
            w)
      ]);
  Widget logo(String s) => Container(
      width: 60,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: s.startsWith('Visa')
              ? const Color(0xFF182D86)
              : s.startsWith('MTN')
                  ? Colors.amber
                  : const Color(0xFFEDF5FF),
          borderRadius: BorderRadius.circular(5)),
      child: t(
          s.startsWith('Visa')
              ? 'VISA'
              : s.startsWith('Master')
                  ? '●●'
                  : s.startsWith('MTN')
                      ? 'MTN'
                      : s.startsWith('Wave')
                          ? 'Wave'
                          : 'PayPal',
          size: s.startsWith('Visa') ? 20 : 12,
          bold: true,
          color: s.startsWith('Visa') ? Colors.white : blue));
  Widget methodList() => Column(
      children: methods
          .map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: card(
                  Row(children: [
                    logo(m),
                    const SizedBox(width: 15),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          t(m, size: 12, bold: true),
                          gap(6),
                          t(
                              m.startsWith('Visa')
                                  ? 'Expire le 12/2028'
                                  : 'Compte de paiement enregistré',
                              size: 10,
                              color: muted)
                        ])),
                    PopupMenuButton<String>(
                        icon: ico(Icons.more_vert, size: 18),
                        onSelected: (s) => setState(() {
                              if (s == 'principal') {
                                principal = m;
                              } else {
                                methods.remove(m);
                                if (principal == m) {
                                  principal =
                                      methods.isEmpty ? '' : methods.first;
                                }
                              }
                            }),
                        itemBuilder: (_) => [
                              const PopupMenuItem(
                                  value: 'principal',
                                  child: Text('Définir comme principal')),
                              const PopupMenuItem(
                                  value: 'delete', child: Text('Supprimer'))
                            ]),
                    if (MediaQuery.sizeOf(context).width > 600)
                      badge(m == principal ? 'Principal' : 'Activée')
                  ]),
                  pad: 16)))
          .toList());
  Widget payments(double w) => Column(children: [
        heading(
            'Moyens de paiement',
            'Gérez vos moyens de paiement pour régler vos réservations en toute sécurité.',
            Icons.account_balance_wallet_outlined),
        columns(
            Column(children: [
              card(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(spacing: 18, runSpacing: 12, children: [
                      t('Mes moyens de paiement', bold: true),
                      btn('Ajouter un moyen de paiement',
                          () => go('Ajouter un moyen de paiement'))
                    ]),
                    gap(22),
                    methodList(),
                    card(
                        t('Paiements sécurisés\nVos moyens de paiement sont protégés.',
                            size: 11, color: blue),
                        color: const Color(0xFFEFF6FF))
                  ])),
              gap(),
              card(transactions())
            ]),
            Column(children: [
              card(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    t('Solde du portefeuille', bold: true),
                    gap(),
                    t('${balance.toStringAsFixed(2)} \$', size: 26, bold: true),
                    gap(),
                    btn('Recharger mon compte', () => money(false))
                  ])),
              gap(),
              card(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    t('Actions rapides', bold: true),
                    gap(),
                    ...[
                      'Historique des transactions',
                      'Documents',
                      'Paramètres'
                    ].map((s) => ListTile(
                        title: t(s, size: 12),
                        trailing: ico(Icons.chevron_right),
                        onTap: () => go(s)))
                  ])),
              gap(),
              support()
            ]),
            w)
      ]);
  Widget addPayment() => Column(children: [
        heading(
            'Ajouter un moyen de paiement',
            'Choisissez le type de moyen de paiement à ajouter.',
            Icons.credit_card),
        card(Column(
            children: [
          'Carte bancaire',
          'Mobile Money',
          'Compte PayPal',
          'Compte bancaire'
        ]
                .map((s) => ListTile(
                    leading: ico(Icons.credit_card),
                    title: t(s, bold: true),
                    subtitle: t(
                        s == 'Mobile Money'
                            ? 'MTN, Moov, TMoney, Wave'
                            : 'Ajouter un compte de démonstration',
                        size: 11,
                        color: muted),
                    trailing: ico(Icons.chevron_right),
                    onTap: () => newMethod(s)))
                .toList())),
        gap(),
        btn('Retour aux moyens de paiement', () => go('Moyens de paiement'),
            outline: true)
      ]);
  Widget settings(double w) => Column(children: [
        heading(
            'Paramétrage des moyens de paiement',
            'Gérez vos moyens de paiement et vos préférences de paiement en toute sécurité.',
            Icons.settings),
        columns(
            Column(children: [
              card(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    t('Moyen de paiement principal', bold: true),
                    gap(),
                    line('Choisi pour vos prochaines transactions', principal),
                    gap(),
                    btn('Changer', () => go('Moyens de paiement'),
                        outline: true)
                  ])),
              gap(),
              card(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    t('Mes moyens de paiement', bold: true),
                    gap(),
                    methodList(),
                    btn('Ajouter un moyen de paiement',
                        () => go('Ajouter un moyen de paiement'))
                  ])),
              gap(),
              card(ListTile(
                  leading: ico(Icons.person_outline),
                  title: t('Mes informations', bold: true),
                  trailing: ico(Icons.chevron_right),
                  onTap: () => go('Mes informations')))
            ]),
            Column(children: [
              card(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    t('Sécurité des paiements', bold: true),
                    gap(),
                    ...[
                      'Chiffrement SSL/TLS',
                      'Authentification 3D Secure',
                      'Protection contre la fraude',
                      'Conformité PCI DSS'
                    ].map((s) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        child: t('✓  $s',
                            size: 12, color: const Color(0xFF1AA879))))
                  ])),
              gap(),
              card(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    t('Paramètres de paiement', bold: true),
                    gap(),
                    ...List.generate(
                        3,
                        (i) => SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: t(
                                [
                                  'Autoriser les paiements en ligne',
                                  'Paiements automatiques',
                                  'Notifications de paiement'
                                ][i],
                                size: 12,
                                color: blue),
                            value: prefs[i],
                            onChanged: (v) => setState(() => prefs[i] = v)))
                  ])),
              gap(),
              support()
            ]),
            w)
      ]);
  static const titles = [
    'Colis en transit',
    'Paiement confirmé',
    'Nouveau message',
    'Promotion spéciale',
    'Mise à jour de la plateforme',
    'Colis livré',
    'Frais de service'
  ];
  static const types = [
    'Colis',
    'Paiements',
    'Colis',
    'Promotions',
    'Système',
    'Colis',
    'Paiements'
  ];
  Widget notifications(double w) => Column(children: [
        heading(
            'Notifications',
            'Restez informé de l’évolution de vos colis et de toutes les actualités de la plateforme.',
            Icons.notifications_outlined),
        columns(
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              tabs(['Tous', 'Colis', 'Paiements', 'Système', 'Promotions']),
              ...List.generate(7, (i) => i)
                  .where((i) => filter == 'Tous' || filter == types[i])
                  .map((i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: card(
                          ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFEAF3FF),
                                  child: ico([
                                    Icons.local_shipping_outlined,
                                    Icons.credit_card,
                                    Icons.chat_outlined,
                                    Icons.card_giftcard,
                                    Icons.info_outline,
                                    Icons.check_circle_outline,
                                    Icons.percent
                                  ][i])),
                              title: t(titles[i], bold: true),
                              subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: t(
                                      i == 0
                                          ? 'Votre colis #SHP-2026-002 est actuellement en transit vers Lomé. Il sera livré dans 2 jours.'
                                          : 'Consultez les détails de cette notification.',
                                      size: 11,
                                      color: muted)),
                              trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (i < 3 && !read.contains(i))
                                      const Icon(Icons.circle,
                                          color: Colors.red, size: 7),
                                    ico(Icons.chevron_right, size: 18)
                                  ]),
                              onTap: () => setState(() {
                                    notification = i;
                                    read.add(i);
                                  })),
                          color: notification == i
                              ? const Color(0xFFEAF4FF)
                              : Colors.white)))
            ]),
            card(
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              t(titles[notification], size: 20, bold: true),
              gap(10),
              badge(types[notification]),
              gap(22),
              t(
                  notification == 0
                      ? 'Votre colis #SHP-2026-002 est actuellement en transit vers Lomé. Il sera livré dans 2 jours.'
                      : 'Notification de démonstration : ${titles[notification].toLowerCase()}.',
                  size: 12,
                  color: muted),
              gap(24),
              if (types[notification] == 'Colis') ...[
                t('Suivi de l’acheminement', bold: true),
                gap(),
                journey(),
                btn('Voir le suivi complet', () {
                  selected = 1;
                  go('Suivi en temps réel');
                })
              ],
              if (types[notification] == 'Paiements')
                btn('Voir mes transactions',
                    () => go('Historique des transactions')),
              if (types[notification] == 'Promotions')
                btn('Voir la promotion', coupons)
            ])),
            w)
      ]);
  Widget documentCard() =>
      card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        t('Documents', bold: true),
        gap(),
        ...[
          'Facture commerciale',
          'Bon d’expédition',
          'Pièce d’identité (si nécessaire)'
        ].map((s) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: ico(Icons.description_outlined),
            title: t(s, size: 11),
            subtitle: t('Document de démonstration', size: 10, color: muted),
            trailing: ico(Icons.visibility_outlined, size: 17),
            onTap: () => receipt(products[selected], title: s)))
      ]));
  String name = 'Koffi Mensah',
      phone = '+228 90 12 34 56',
      address = 'Lomé, Togo';
  Widget profile() => Column(children: [
        heading(
            'Mes informations',
            'Gérez vos informations personnelles et vos coordonnées.',
            Icons.person_outline),
        card(Column(children: [
          const CircleAvatar(
              radius: 38,
              backgroundColor: Color(0xFFEAF3FF),
              child: Icon(Icons.person, size: 50, color: navy)),
          gap(),
          t(name, size: 20, bold: true),
          line('Adresse e-mail', 'koffi.mensah@email.com'),
          line('Téléphone', phone),
          line('Adresse de livraison', address),
          gap(),
          btn('Modifier mes informations', editProfile)
        ]))
      ]);
  Widget help() => Column(children: [
        heading(
            'Aide & Support',
            'Une question ? Notre équipe est là pour vous aider.',
            Icons.headset_mic_outlined),
        card(Column(children: [
          ExpansionTile(
              title: t('Comment réserver un enlèvement ?', bold: true),
              children: [
                Padding(
                    padding: const EdgeInsets.all(16),
                    child: t(
                        'Ouvrez Réservations, indiquez les informations du colis, le lieu de collecte et le destinataire, puis confirmez.'))
              ]),
          ExpansionTile(
              title: t('Comment suivre mon colis ?', bold: true),
              children: [
                Padding(
                    padding: const EdgeInsets.all(16),
                    child: t(
                        'Ouvrez En transit puis Voir détails pour consulter les étapes et la carte.'))
              ]),
          ExpansionTile(
              title: t('Comment recharger mon portefeuille ?', bold: true),
              children: [
                Padding(
                    padding: const EdgeInsets.all(16),
                    child: t(
                        'Ouvrez Portefeuille puis Recharger et sélectionnez votre montant.'))
              ]),
          gap(),
          btn('Contacter le support', () => contact('Support Ships4US'))
        ]))
      ]);
  void notice(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  Future<void> dialog(String title, Widget body) => showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
              title: t(title, size: 18, bold: true),
              content: SingleChildScrollView(
                  child: SizedBox(width: 420, child: body)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fermer'))
              ]));
  void receipt(Map<String, String> p, {String title = 'Facture commerciale'}) =>
      dialog(
          title,
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            t('Ships4US · Document de démonstration', bold: true),
            gap(20),
            line('Client', name),
            line('Référence', p['ref']!),
            line('Produit', p['name']!),
            line('Prix du produit', '${p['price']} \$'),
            line('Frais de transport', '24,00 \$'),
            line('Destination', 'Lomé, Togo'),
            gap(),
            t('Ce reçu illustre la maquette. Aucun paiement réel n’a été effectué.',
                size: 11, color: muted)
          ]));
  void coupons() => dialog(
      'Mes coupons',
      Column(children: [
        badge('Promotion spéciale'),
        gap(),
        t('10 % de réduction sur vos prochains envois vers le Togo.',
            bold: true),
        gap(),
        t('Code : TOGO10 · Offre de démonstration', color: blue)
      ]));
  void contact(String title) {
    final key = GlobalKey<FormState>();
    String message = '';
    dialog(
        title,
        Form(
            key: key,
            child: Column(children: [
              t('Décrivez votre demande. Le message reste dans cette démonstration.',
                  size: 12, color: muted),
              gap(),
              TextFormField(
                  maxLines: 4,
                  decoration: const InputDecoration(
                      labelText: 'Votre message', border: OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Écrivez un message'
                      : null,
                  onSaved: (v) => message = v!),
              gap(),
              btn('Enregistrer la demande', () {
                if (!key.currentState!.validate()) return;
                key.currentState!.save();
                Navigator.pop(context);
                notice('Demande enregistrée pour cette session : $message');
              })
            ])));
  }

  void money(bool withdraw) {
    final key = GlobalKey<FormState>();
    String amount = '';
    dialog(
        withdraw ? 'Retirer des fonds' : 'Recharger mon compte',
        Form(
            key: key,
            child: Column(children: [
              t('Opération simulée pour reproduire le parcours client.',
                  size: 12, color: muted),
              gap(),
              TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Montant en USD',
                      border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  onSaved: (v) => amount = v!,
                  validator: (v) {
                    final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                    return n == null || !n.isFinite || n <= 0
                        ? 'Saisissez un montant valide'
                        : withdraw && n > balance
                            ? 'Solde insuffisant'
                            : null;
                  }),
              gap(),
              btn('Confirmer', () {
                if (!key.currentState!.validate()) return;
                key.currentState!.save();
                setState(() => balance += (withdraw ? -1 : 1) *
                    double.parse(amount.replaceAll(',', '.')));
                Navigator.pop(context);
                notice('Opération simulée effectuée.');
              })
            ])));
  }

  void newMethod(String type) {
    final key = GlobalKey<FormState>();
    String value = '';
    dialog(
        type,
        Form(
            key: key,
            child: Column(children: [
              t('Utilisez uniquement des coordonnées fictives pour cette démonstration.',
                  size: 11, color: muted),
              gap(),
              TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'Libellé du compte / 4 derniers chiffres',
                      border: OutlineInputBorder()),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Champ obligatoire'
                      : null,
                  onSaved: (v) => value = v!),
              gap(),
              btn('Ajouter', () {
                if (!key.currentState!.validate()) return;
                key.currentState!.save();
                setState(() => methods.add('$type · $value'));
                Navigator.pop(context);
                go('Moyens de paiement');
              })
            ])));
  }

  void editProfile() {
    final key = GlobalKey<FormState>();
    String n = name, p = phone, a = address;
    dialog(
        'Modifier mes informations',
        Form(
            key: key,
            child: Column(children: [
              TextFormField(
                  initialValue: n,
                  decoration: const InputDecoration(labelText: 'Nom complet'),
                  onSaved: (v) => n = v!,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Champ obligatoire'
                      : null),
              gap(),
              TextFormField(
                  initialValue: p,
                  decoration: const InputDecoration(labelText: 'Téléphone'),
                  onSaved: (v) => p = v!),
              gap(),
              TextFormField(
                  initialValue: a,
                  decoration:
                      const InputDecoration(labelText: 'Adresse de livraison'),
                  onSaved: (v) => a = v!),
              gap(),
              btn('Enregistrer', () {
                if (!key.currentState!.validate()) return;
                key.currentState!.save();
                setState(() {
                  name = n;
                  phone = p;
                  address = a;
                });
                Navigator.pop(context);
              })
            ])));
  }
}
