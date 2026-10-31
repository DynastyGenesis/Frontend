import 'package:flutter/material.dart';
import '../client_space/ships_login_page.dart';

const publicBlue = Color(0xFF005BF3);
const publicNavy = Color(0xFF08264C);
const publicMuted = Color(0xFF64748B);
const publicTint = Color(0xFFF1F7FE);

ThemeData shipsPublicTheme() => ThemeData(
      useMaterial3: true,
      fontFamily: 'Open Sans',
      colorScheme: ColorScheme.fromSeed(
          seedColor: publicBlue, primary: publicBlue, surface: Colors.white),
      scaffoldBackgroundColor: Colors.white,
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
              backgroundColor: publicBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7)))),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
              foregroundColor: publicNavy,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              side: const BorderSide(color: publicNavy),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7)))),
      inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
    );

class ShipsPublicHomePage extends StatefulWidget {
  const ShipsPublicHomePage({super.key});
  @override
  State<ShipsPublicHomePage> createState() => _ShipsPublicHomePageState();
}

class _ShipsPublicHomePageState extends State<ShipsPublicHomePage> {
  final scroll = ScrollController();
  final servicesKey = GlobalKey(),
      stepsKey = GlobalKey(),
      aboutKey = GlobalKey();
  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  void jump(GlobalKey key) {
    final target = key.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(target,
          duration: const Duration(milliseconds: 450), curve: Curves.easeInOut);
    }
  }

  void login() => Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const ShipsLoginPage()));
  void driver() => Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => const ShipsLoginPage(driver: true)));
  Widget text(String s,
          {double size = 14, bool bold = false, Color color = publicNavy}) =>
      Text(s,
          style: TextStyle(
              fontSize: size,
              height: 1.5,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: color));
  Widget gap([double size = 18]) => SizedBox(height: size);
  Widget clientButton() => FilledButton.icon(
      onPressed: login,
      icon: const Icon(Icons.person, size: 17),
      label: const Text('Se connecter — Client',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)));
  Widget driverButton() => OutlinedButton(
      onPressed: driver,
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.local_shipping_outlined, size: 17),
        SizedBox(width: 9),
        Text('Compte livreur',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ]));
  Widget brand() => Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.view_in_ar, size: 39, color: publicBlue),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text.rich(
              TextSpan(children: [
                TextSpan(text: 'Barel', style: TextStyle(color: publicNavy)),
                TextSpan(
                    text: 'Go', style: TextStyle(color: Color(0xFFF97316)))
              ]),
              style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1)),
          text('Vos colis, notre priorité', size: 9, color: publicMuted)
        ])
      ]);
  Widget panel(Widget child, {Color color = Colors.white}) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE0EAF6))),
      child: child);
  Widget section(Widget child, {Color color = Colors.white, GlobalKey? key}) =>
      Container(
          key: key,
          color: color,
          width: double.infinity,
          child: Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 40),
                      child: child))));
  Widget title(String s, String sub) => Column(children: [
        text(s, size: 30, bold: true),
        gap(7),
        Container(width: 42, height: 3, color: const Color(0xFFF97316)),
        gap(12),
        text(sub, size: 13, color: publicMuted),
        gap(28)
      ]);
  @override
  Widget build(BuildContext context) => Theme(
      data: shipsPublicTheme(),
      child: Scaffold(body: LayoutBuilder(builder: (context, b) {
        final wide = b.maxWidth >= 1200;
        return Column(children: [
          Container(
              decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFE7EFF8)))),
              child: Center(
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1360),
                      child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          child: wide
                              ? Row(children: [
                                  brand(),
                                  const Spacer(),
                                  ...navigation(),
                                  const SizedBox(width: 18),
                                  clientButton(),
                                  const SizedBox(width: 12),
                                  driverButton()
                                ])
                              : Row(children: [
                                  brand(),
                                  const Spacer(),
                                  PopupMenuButton<String>(
                                      tooltip: 'Menu',
                                      icon: const Icon(Icons.menu,
                                          color: publicNavy),
                                      onSelected: (value) {
                                        switch (value) {
                                          case 'services':
                                            jump(servicesKey);
                                            break;
                                          case 'steps':
                                            jump(stepsKey);
                                            break;
                                          case 'about':
                                            jump(aboutKey);
                                            break;
                                          case 'client':
                                            login();
                                            break;
                                          case 'driver':
                                            driver();
                                            break;
                                          default:
                                            scroll.animateTo(0,
                                                duration: const Duration(
                                                    milliseconds: 300),
                                                curve: Curves.easeInOut);
                                        }
                                      },
                                      itemBuilder: (_) => const [
                                            PopupMenuItem(
                                                value: 'home',
                                                child: Text('Accueil')),
                                            PopupMenuItem(
                                                value: 'services',
                                                child: Text('Nos services')),
                                            PopupMenuItem(
                                                value: 'steps',
                                                child:
                                                    Text('Comment ça marche')),
                                            PopupMenuItem(
                                                value: 'about',
                                                child: Text('À propos')),
                                            PopupMenuItem(
                                                value: 'client',
                                                child: Text(
                                                    'Se connecter — Client')),
                                            PopupMenuItem(
                                                value: 'driver',
                                                child: Text('Compte livreur'))
                                          ])
                                ]))))),
          Expanded(
              child: SingleChildScrollView(
                  controller: scroll,
                  child: Column(children: [
                    hero(wide),
                    services(),
                    steps(),
                    about(),
                    footer()
                  ])))
        ]);
      })));
  List<Widget> navigation() => [
        TextButton(
            onPressed: () => scroll.animateTo(0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut),
            child: text('Accueil', size: 11, bold: true, color: publicBlue)),
        TextButton(
            onPressed: () => jump(servicesKey),
            child: text('Nos services', size: 11)),
        TextButton(
            onPressed: () => jump(stepsKey),
            child: text('Comment ça marche', size: 11)),
        TextButton(
            onPressed: () => jump(aboutKey), child: text('À propos', size: 11))
      ];
  Widget hero(bool wide) {
    final copy =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      text('EXPÉDITION ÉTATS-UNIS → TOGO',
          size: 11, bold: true, color: publicBlue),
      gap(18),
      Text.rich(
          const TextSpan(children: [
            TextSpan(
                text: 'Vos colis des\nÉtats-Unis au Togo,\n',
                style: TextStyle(color: publicNavy)),
            TextSpan(
                text: 'en toute simplicité.',
                style: TextStyle(color: publicBlue))
          ]),
          style: TextStyle(
              fontSize: wide ? 43 : 31,
              height: 1.15,
              fontWeight: FontWeight.w700,
              letterSpacing: -1)),
      gap(22),
      text(
          'Collecte, transport et livraison : BarelGo vous accompagne à chaque étape de votre envoi.',
          size: 16,
          color: publicMuted),
      gap(26),
      Wrap(spacing: 12, runSpacing: 12, children: [
        clientButton(),
        OutlinedButton(
            onPressed: () => jump(servicesKey),
            child: const Text('Découvrir nos services  →',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)))
      ]),
      gap(28),
      Wrap(spacing: 24, runSpacing: 12, children: [
        benefit(Icons.location_on_outlined, 'Suivi de vos colis'),
        benefit(Icons.people_outline, 'Accompagnement'),
        benefit(Icons.local_shipping_outlined, 'Livraison au Togo')
      ])
    ]);
    final image = ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.asset('assets/images/public_home_hero.png',
            fit: BoxFit.cover, width: double.infinity));
    return section(
        wide
            ? Row(children: [
                Expanded(child: copy),
                const SizedBox(width: 32),
                Expanded(child: image)
              ])
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [copy, gap(30), image]),
        color: publicTint);
  }

  Widget benefit(IconData icon, String s) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: publicBlue, size: 20),
        const SizedBox(width: 7),
        text(s, size: 11, bold: true)
      ]);
  Widget services() => section(
      Column(children: [
        title('Nos services',
            'Des solutions pour vous accompagner de la collecte à la livraison.'),
        LayoutBuilder(builder: (context, b) {
          final count = b.maxWidth > 900
              ? 4
              : b.maxWidth > 580
                  ? 2
                  : 1;
          return Wrap(
              spacing: 18,
              runSpacing: 18,
              children: List.generate(4, (i) {
                const headings = [
                  'Collecte aux États-Unis',
                  'Transport international',
                  'Suivi des colis',
                  'Livraison au Togo'
                ];
                const descriptions = [
                  'Organisez l’enlèvement de vos colis auprès de vos expéditeurs.',
                  'Acheminez vos colis des États-Unis vers le Togo.',
                  'Consultez l’avancement de vos envois depuis votre espace client.',
                  'Préparez la réception de vos colis à destination.'
                ];
                const icons = [
                  Icons.view_in_ar_outlined,
                  Icons.flight_takeoff,
                  Icons.location_on_outlined,
                  Icons.local_shipping_outlined
                ];
                return SizedBox(
                    width: (b.maxWidth - 18 * (count - 1)) / count,
                    child: panel(Column(children: [
                      CircleAvatar(
                          radius: 30,
                          backgroundColor: publicTint,
                          child: Icon(icons[i], size: 33, color: publicBlue)),
                      gap(18),
                      text(headings[i], bold: true, size: 14),
                      gap(8),
                      text(descriptions[i], size: 12, color: publicMuted)
                    ])));
              }));
        })
      ]),
      key: servicesKey);
  Widget steps() => section(
      Column(children: [
        title('Comment ça marche ?',
            'Un parcours simple, de la collecte à la réception.'),
        LayoutBuilder(builder: (context, b) {
          final count = b.maxWidth > 850
              ? 4
              : b.maxWidth > 580
                  ? 2
                  : 1;
          return Wrap(
              spacing: 24,
              runSpacing: 24,
              children: List.generate(4, (i) {
                const headings = [
                  'Connectez-vous',
                  'Réservez la collecte',
                  'Suivez votre envoi',
                  'Recevez votre colis'
                ];
                const descriptions = [
                  'Accédez à votre espace client',
                  'Renseignez votre colis et les adresses',
                  'Consultez les étapes du transport',
                  'Finalisez la livraison au Togo'
                ];
                const icons = [
                  Icons.person_outline,
                  Icons.calendar_month_outlined,
                  Icons.view_in_ar_outlined,
                  Icons.local_shipping_outlined
                ];
                return SizedBox(
                    width: (b.maxWidth - 24 * (count - 1)) / count,
                    child: Column(children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                                radius: 15,
                                backgroundColor: publicBlue,
                                child: Text('${i + 1}',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 12))),
                            const SizedBox(width: 15),
                            CircleAvatar(
                                radius: 27,
                                backgroundColor: Colors.white,
                                child:
                                    Icon(icons[i], color: publicBlue, size: 29))
                          ]),
                      gap(16),
                      text('${i + 1}. ${headings[i]}', bold: true),
                      gap(6),
                      text(descriptions[i], size: 12, color: publicMuted)
                    ]));
              }));
        })
      ]),
      color: publicTint,
      key: stepsKey);
  Widget about() => section(LayoutBuilder(builder: (context, b) {
        final company =
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          text('À PROPOS DE BARELGO', size: 11, bold: true, color: publicBlue),
          gap(14),
          text('Un lien entre vos expéditeurs\net vos destinataires.',
              size: 28, bold: true),
          gap(16),
          text(
              'BarelGo simplifie l’envoi de colis entre les États-Unis et le Togo. Notre équipe vous accompagne pour organiser la collecte, suivre le transport et préparer la livraison.',
              size: 14,
              color: publicMuted),
          gap(22),
          ...[
            'Un parcours clair',
            'Une équipe à votre écoute',
            'Un suivi centralisé'
          ].map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: benefit(Icons.check_circle, s)))
        ]);
        final accounts = panel(
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          text('Accédez à votre espace', size: 24, bold: true),
          gap(20),
          panel(
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                benefit(Icons.person_outline, 'Vous êtes client ?'),
                gap(8),
                text('Réservez et suivez vos colis.',
                    size: 12, color: publicMuted),
                gap(12),
                clientButton()
              ]),
              color: publicTint),
          gap(12),
          panel(
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                benefit(Icons.local_shipping_outlined, 'Vous êtes livreur ?'),
                gap(8),
                text('Acceptez vos missions et confirmez vos livraisons.',
                    size: 12, color: publicMuted),
                gap(12),
                driverButton()
              ]),
              color: const Color(0xFFF8FAFC))
        ]));
        return b.maxWidth > 850
            ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(child: company),
                const SizedBox(width: 48),
                Expanded(child: accounts)
              ])
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [company, gap(24), accounts]);
      }), key: aboutKey);
  Widget footer() => section(Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 28,
          runSpacing: 18,
          children: [
            brand(),
            text('États-Unis → Togo', size: 12),
            TextButton(
                onPressed: () => jump(servicesKey),
                child: text('Nos services', size: 11)),
            TextButton(
                onPressed: () => legal('Confidentialité'),
                child: text('Confidentialité', size: 11)),
            TextButton(
                onPressed: () => legal('Conditions d’utilisation'),
                child: text('Conditions d’utilisation', size: 11)),
            text('© 2026 BarelGo', size: 11, color: publicMuted)
          ]));
  void legal(String title) => showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
              title: Text(title),
              content: const Text(
                  'Le contenu de cette page sera ajouté avant la mise en service. Les données de cette démonstration ne sont pas transmises à un serveur.'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fermer'))
              ]));
}
