import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';

class HomePage extends StatefulWidget {
  final VoidCallback onOpenTracking;
  final VoidCallback onOpenQuote;
  final VoidCallback onOpenClient;
  final VoidCallback? onOpenDriver;

  const HomePage({
    super.key,
    required this.onOpenTracking,
    required this.onOpenQuote,
    required this.onOpenClient,
    this.onOpenDriver,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scrollController = ScrollController();
  final _servicesKey = GlobalKey();
  final _contactKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _scrollTo(GlobalKey key) async {
    final target = key.currentContext;
    if (target == null) return;

    await Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      alignment: 0.04,
    );
  }

  Future<void> _openLink(Uri uri) async {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d’ouvrir ce lien.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            return SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  _SiteHeader(
                    isWide: isWide,
                    onHome: () => _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 450),
                      curve: Curves.easeInOut,
                    ),
                    onServices: () => _scrollTo(_servicesKey),
                    onContact: () => _scrollTo(_contactKey),
                    onOpenQuote: widget.onOpenQuote,
                    onOpenClient: widget.onOpenClient,
                    onOpenDriver: widget.onOpenDriver,
                  ),
                  _HeroSection(
                    isWide: isWide,
                    onContact: () => _openLink(
                      Uri.parse('https://www.ships4us.com/contact'),
                    ),
                    onPlan: widget.onOpenQuote,
                  ),
                  _TransportSection(
                    key: _servicesKey,
                    isWide: isWide,
                    onPlan: widget.onOpenQuote,
                  ),
                  _CustomsSection(
                    isWide: isWide,
                    onContact: () => _openLink(
                      Uri.parse('https://www.ships4us.com/contact'),
                    ),
                    onPlan: widget.onOpenQuote,
                  ),
                  _StepsSection(
                    isWide: isWide,
                    onContact: () => _openLink(
                      Uri.parse('https://www.ships4us.com/contact'),
                    ),
                    onPlan: widget.onOpenQuote,
                  ),
                  _TrackingSection(
                    isWide: isWide,
                    onTrack: widget.onOpenTracking,
                  ),
                  _NewsSection(isWide: isWide, onPlan: widget.onOpenQuote),
                  _TrustSection(
                    isWide: isWide,
                    onContact: () => _openLink(
                      Uri.parse('https://www.ships4us.com/contact'),
                    ),
                    onPlan: widget.onOpenQuote,
                  ),
                  _SiteFooter(
                    key: _contactKey,
                    isWide: isWide,
                    onContact: () => _openLink(
                      Uri.parse('https://www.ships4us.com/contact'),
                    ),
                    onCall: () => _openLink(Uri.parse('tel:+33488927172')),
                    onLegal: () => _openLink(
                      Uri.parse('https://www.ships4us.com/mentions-legales'),
                    ),
                    onPrivacy: () => _openLink(
                      Uri.parse(
                        'https://www.ships4us.com/politique-confidentialite',
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      );
}

class _SiteHeader extends StatelessWidget {
  final bool isWide;
  final VoidCallback onHome;
  final VoidCallback onServices;
  final VoidCallback onContact;
  final VoidCallback onOpenQuote;
  final VoidCallback onOpenClient;
  final VoidCallback? onOpenDriver;

  const _SiteHeader({
    required this.isWide,
    required this.onHome,
    required this.onServices,
    required this.onContact,
    required this.onOpenQuote,
    required this.onOpenClient,
    this.onOpenDriver,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: AppColors.white,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 28 : 20,
                vertical: 14,
              ),
              child: Row(
                children: [
                  _BrandWordmark(isWide: isWide),
                  const Spacer(),
                  if (isWide) ...[
                    _HeaderLink(
                        label: 'Accueil', onPressed: onHome, active: true),
                    _HeaderLink(
                      label: 'Afrique ↔ États-Unis',
                      onPressed: onServices,
                    ),
                    _HeaderLink(label: 'Contact', onPressed: onContact),
                    const SizedBox(width: 18),
                    _HeaderButton(
                      icon: Icons.mail_outline,
                      label: 'Espace Client',
                      onPressed: onOpenClient,
                    ),
                    if (onOpenDriver != null) ...[
                      const SizedBox(width: 8),
                      _HeaderButton(
                        icon: Icons.local_shipping_outlined,
                        label: 'Espace Livreur',
                        onPressed: onOpenDriver!,
                      ),
                    ],
                    const SizedBox(width: 8),
                    _HeaderButton(
                      icon: Icons.call,
                      label: '04 88 92 71 72',
                      onPressed: () => launchUrl(Uri.parse('tel:+33488927172')),
                    ),
                  ] else ...[
                    if (MediaQuery.sizeOf(context).width < 520) ...[
                      IconButton(
                        tooltip: 'Espace client',
                        onPressed: onOpenClient,
                        icon: const Icon(
                          Icons.person_outline,
                          color: AppColors.brandPinkDark,
                        ),
                      ),
                      if (onOpenDriver != null)
                        IconButton(
                          tooltip: 'Espace livreur',
                          onPressed: onOpenDriver!,
                          icon: const Icon(
                            Icons.local_shipping_outlined,
                            color: AppColors.brandPinkDark,
                          ),
                        ),
                      IconButton(
                        tooltip: 'Planifier un envoi',
                        onPressed: onOpenQuote,
                        icon: const Icon(
                          Icons.add_box_outlined,
                          color: AppColors.brandPinkDark,
                        ),
                      ),
                    ] else ...[
                      IconButton(
                        tooltip: 'Contacter barrelGo',
                        onPressed: onContact,
                        icon: const Icon(
                          Icons.mail_outline,
                          color: AppColors.brandPinkDark,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Espace client',
                        onPressed: onOpenClient,
                        icon: const Icon(
                          Icons.person_outline,
                          color: AppColors.brandPinkDark,
                        ),
                      ),
                      if (onOpenDriver != null)
                        IconButton(
                          tooltip: 'Espace livreur',
                          onPressed: onOpenDriver!,
                          icon: const Icon(
                            Icons.local_shipping_outlined,
                            color: AppColors.brandPinkDark,
                          ),
                        ),
                      const SizedBox(width: 4),
                      FilledButton(
                        onPressed: onOpenQuote,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brandPink,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                        child: const Text('Planifier un envoi'),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      );
}

class _HeaderLink extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool active;

  const _HeaderLink({
    required this.label,
    required this.onPressed,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: active ? AppColors.brandPinkDark : AppColors.ink,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
        ),
        child: Text(label, style: const TextStyle(fontSize: 14)),
      );
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _HeaderButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: Text(label, maxLines: 1),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandPink,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
          ),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
        ),
      );
}

class _HeroSection extends StatelessWidget {
  final bool isWide;
  final VoidCallback onContact;
  final VoidCallback onPlan;

  const _HeroSection({
    required this.isWide,
    required this.onContact,
    required this.onPlan,
  });

  @override
  Widget build(BuildContext context) {
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bienvenue sur barrelGo',
          style: _displayStyle(
            fontSize: isWide ? 46 : 34,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 24),
        const Text.rich(
          TextSpan(
            style: TextStyle(height: 1.85, color: Colors.black87),
            children: [
              TextSpan(
                text: 'barrelGo',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(
                text:
                    ' vous accompagne pour vos expéditions de colis et de palettes entre le Togo, en Afrique, et les États-Unis, dans les deux sens.',
              ),
            ],
          ),
          textAlign: TextAlign.justify,
        ),
        const SizedBox(height: 16),
        const Text(
          'Organisez vos envois entre l’Afrique et les États-Unis, avec des départs et des livraisons au Togo.',
          textAlign: TextAlign.justify,
          style: TextStyle(height: 1.85, color: Colors.black87),
        ),
        const SizedBox(height: 16),
        const Text(
          'barrelGo vous accompagne dans la préparation de votre expédition et de ses formalités, à l’export comme à l’import.',
          textAlign: TextAlign.justify,
          style: TextStyle(height: 1.85, color: Colors.black87),
        ),
        const SizedBox(height: 24),
        _CallToActions(onContact: onContact, onPlan: onPlan),
      ],
    );

    final image = ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(isWide ? 20 : 12),
        bottomLeft: Radius.circular(isWide ? 20 : 12),
        topRight: Radius.circular(isWide ? 150 : 50),
        bottomRight: Radius.circular(isWide ? 150 : 50),
      ),
      child: Image.asset(
        'assets/images/home_hero.jpg',
        height: isWide ? 510 : 280,
        width: double.infinity,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        semanticLabel: 'Préparation d’un colis à expédier',
      ),
    );

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFD5D7), Color(0xFFFFFFFF), Color(0xFFE8DDF0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 28 : 20,
              vertical: isWide ? 76 : 38,
            ),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 6, child: copy),
                      const SizedBox(width: 64),
                      Expanded(flex: 5, child: image),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      copy,
                      const SizedBox(height: 30),
                      image,
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _CallToActions extends StatelessWidget {
  final VoidCallback onContact;
  final VoidCallback onPlan;

  const _CallToActions({required this.onContact, required this.onPlan});

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 14,
        runSpacing: 10,
        children: [
          _SiteAction(
            label: 'Nous contacter',
            onPressed: onContact,
            outlined: true,
          ),
          _SiteAction(
            label: 'Planifier un envoi',
            icon: Icons.mail_outline,
            onPressed: onPlan,
          ),
        ],
      );
}

class _SiteAction extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool outlined;
  final bool dark;

  const _SiteAction({
    required this.label,
    required this.onPressed,
    this.icon,
    this.outlined = false,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = dark
        ? AppColors.white
        : outlined
            ? AppColors.brandPinkDark
            : AppColors.white;
    final background = dark
        ? AppColors.brandPink
        : outlined
            ? Colors.transparent
            : AppColors.brandPink;

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: foreground,
        backgroundColor: background,
        side: BorderSide(
          color: outlined ? AppColors.brandPinkDark : background,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w400),
      ),
    );
  }
}

class _TransportSection extends StatelessWidget {
  final bool isWide;
  final VoidCallback onPlan;

  const _TransportSection({
    super.key,
    required this.isWide,
    required this.onPlan,
  });

  static const _partners = [
    _Partner(
      name: 'CHRONOPOST',
      image: 'assets/images/chronopost.jpg',
      description:
          'Solutions de transport express, selon la disponibilité sur votre itinéraire.',
    ),
    _Partner(
      name: 'DHL',
      image: 'assets/images/dhl.png',
      description:
          'Transport international et accompagnement pour les formalités douanières.',
    ),
    _Partner(
      name: 'FEDEX',
      image: 'assets/images/fedex.png',
      description:
          'Des solutions de transport international pour vos colis et palettes.',
    ),
    _Partner(
      name: 'UPS',
      image: 'assets/images/ups.png',
      description:
          'Un réseau de transport international mobilisable selon votre expédition.',
    ),
  ];

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: AppColors.blue,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 28 : 20,
                vertical: isWide ? 72 : 48,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EXPÉDITION DE COLIS ET DE PALETTES ENTRE L’AFRIQUE ET LES ÉTATS-UNIS',
                    style: TextStyle(
                      color: AppColors.brandPink,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      fontSize: isWide ? 13 : 11,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Un besoin transport, une solution sur barrelGo',
                    style: _displayStyle(
                      fontSize: isWide ? 36 : 28,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Depuis le Togo, en Afrique, envoyez vers les États-Unis et recevez des colis depuis les États-Unis. barrelGo vous aide à préparer votre demande.',
                    style: TextStyle(
                      color: Colors.white,
                      height: 1.8,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Choisissez le sens de votre envoi et renseignez ses détails pour obtenir une estimation adaptée à votre trajet.',
                    style: TextStyle(
                      color: Colors.white,
                      height: 1.7,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 28),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = isWide ? 4 : 2;
                      final spacing = 14.0;
                      final cardWidth =
                          (constraints.maxWidth - spacing * (columns - 1)) /
                              columns;
                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: _partners
                            .map(
                              (partner) => SizedBox(
                                width: cardWidth,
                                child: _PartnerCard(partner: partner),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Des services pour chaque expédition',
                    style: _displayStyle(
                      fontSize: isWide ? 24 : 21,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'barrelGo accompagne les expéditions entre l’Afrique et les États-Unis, avec un service au départ ou à destination du Togo. Les options sont à confirmer selon les caractéristiques de votre colis.',
                    style: TextStyle(
                      color: Colors.white,
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SiteAction(
                    label: 'Comparer les solutions',
                    icon: Icons.arrow_forward,
                    onPressed: onPlan,
                    dark: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _Partner {
  final String name;
  final String image;
  final String description;

  const _Partner({
    required this.name,
    required this.image,
    required this.description,
  });
}

class _PartnerCard extends StatelessWidget {
  final _Partner partner;

  const _PartnerCard({required this.partner});

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 235),
        padding: const EdgeInsets.all(20),
        color: AppColors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 58,
              width: double.infinity,
              child: Image.asset(
                partner.image,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    Text(partner.name, style: _displayStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              partner.name,
              style: _displayStyle(fontSize: 17),
            ),
            const SizedBox(height: 8),
            Text(
              partner.description,
              style: const TextStyle(
                color: AppColors.muted,
                height: 1.6,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
}

class _CustomsSection extends StatelessWidget {
  final bool isWide;
  final VoidCallback onContact;
  final VoidCallback onPlan;

  const _CustomsSection({
    required this.isWide,
    required this.onContact,
    required this.onPlan,
  });

  @override
  Widget build(BuildContext context) {
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(
          title:
              'Expédier simplement vos colis internationaux sous douane électronique',
          isWide: isWide,
        ),
        const SizedBox(height: 18),
        const Text(
          'Dans un esprit d’efficacité et de proactivité permanente, barrelGo vous accompagne dans vos formalités douanières.',
          style: TextStyle(height: 1.8),
        ),
        const SizedBox(height: 12),
        const Text(
          'Vos expéditions internationales vous permettent de pré-renseigner la douane électronique et d’éviter l’édition des documents d’accompagnement du colis.',
          style: TextStyle(height: 1.8),
        ),
        const SizedBox(height: 16),
        const Text(
          'Les informations à préparer :',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        const _Bullet(label: 'Origine de fabrication de chaque produit'),
        const _Bullet(label: 'Poids brut du colis, emballage compris'),
        const _Bullet(label: 'Nomenclature douanière de chaque produit'),
        const _Bullet(label: 'Incoterm relatif à votre vente'),
        const SizedBox(height: 14),
        const Text(
          'Notre service client vous accompagne si vous avez besoin d’aide lors de la saisie.',
          style: TextStyle(height: 1.8),
        ),
        const SizedBox(height: 22),
        _CallToActions(onContact: onContact, onPlan: onPlan),
      ],
    );
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.asset(
        'assets/images/customs.jpg',
        width: double.infinity,
        height: isWide ? 500 : 250,
        fit: BoxFit.cover,
        semanticLabel: 'Préparation des documents d’expédition',
      ),
    );

    return _SectionSurface(
      isWide: isWide,
      background: AppColors.white,
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 6, child: copy),
                const SizedBox(width: 56),
                Expanded(flex: 5, child: image),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [copy, const SizedBox(height: 28), image],
            ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String label;

  const _Bullet({required this.label});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.check,
              size: 19,
              color: AppColors.brandPinkDark,
            ),
            const SizedBox(width: 9),
            Expanded(child: Text(label, style: const TextStyle(height: 1.5))),
          ],
        ),
      );
}

class _StepsSection extends StatelessWidget {
  final bool isWide;
  final VoidCallback onContact;
  final VoidCallback onPlan;

  const _StepsSection({
    required this.isWide,
    required this.onContact,
    required this.onPlan,
  });

  static const _steps = [
    'Créez un compte sur barrelGo',
    'Préparez vos colis, mesurez-les et pesez-les',
    'Renseignez les villes de départ et d’arrivée et les dimensions des colis',
    'Choisissez le transporteur, imprimez et collez votre étiquette',
    'Suivez votre expédition en ligne sur barrelGo',
  ];

  @override
  Widget build(BuildContext context) => _SectionSurface(
        isWide: isWide,
        background: const Color(0xFFF2F2F2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _SectionHeading(title: 'Les étapes', isWide: isWide),
            const SizedBox(height: 12),
            const Text(
              'Expédier un colis simplement, de la création de compte au suivi.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            _CallToActions(onContact: onContact, onPlan: onPlan),
            const SizedBox(height: 32),
            LayoutBuilder(
              builder: (context, constraints) {
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(
                      _steps.length,
                      (index) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: index == _steps.length - 1 ? 0 : 14,
                          ),
                          child: _StepCard(
                            number: index + 1,
                            text: _steps[index],
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return Column(
                  children: List.generate(
                    _steps.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _StepCard(
                        number: index + 1,
                        text: _steps[index],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
}

class _StepCard extends StatelessWidget {
  final int number;
  final String text;

  const _StepCard({required this.number, required this.text});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 170),
        padding: const EdgeInsets.all(18),
        color: AppColors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.brandPink,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$number',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Étape $number',
              style: _displayStyle(fontSize: 17),
            ),
            const SizedBox(height: 8),
            Text(text, style: const TextStyle(height: 1.55)),
          ],
        ),
      );
}

class _TrackingSection extends StatelessWidget {
  final bool isWide;
  final VoidCallback onTrack;

  const _TrackingSection({required this.isWide, required this.onTrack});

  @override
  Widget build(BuildContext context) {
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeading(
          title: 'Suivez vos envois avec précision',
          isWide: isWide,
        ),
        const SizedBox(height: 18),
        const Text(
          'Notre système de tracking multi-transporteurs vous apporte facilité d’usage et sérénité au quotidien. En un coup d’œil, constatez l’avancée de vos expéditions et appuyez-vous sur la réactivité de notre service client.',
          style: TextStyle(height: 1.8),
        ),
        const SizedBox(height: 14),
        const Text(
          'Un numéro unique, non surtaxé, vous répond du lundi au vendredi, de 08h à 20h.',
          style: TextStyle(height: 1.8),
        ),
        const SizedBox(height: 22),
        _SiteAction(
          label: 'Suivre un envoi',
          icon: Icons.location_searching,
          onPressed: onTrack,
        ),
      ],
    );
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.asset(
        'assets/images/tracking.jpg',
        width: double.infinity,
        height: isWide ? 410 : 245,
        fit: BoxFit.cover,
        semanticLabel: 'Suivi d’une expédition barrelGo',
      ),
    );

    return _SectionSurface(
      isWide: isWide,
      background: AppColors.white,
      child: isWide
          ? Row(
              children: [
                Expanded(flex: 5, child: image),
                const SizedBox(width: 64),
                Expanded(flex: 6, child: copy),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: 26),
                image,
              ],
            ),
    );
  }
}

class _NewsSection extends StatelessWidget {
  final bool isWide;
  final VoidCallback onPlan;

  const _NewsSection({required this.isWide, required this.onPlan});

  static const _stories = [
    _Story(
      title: 'De l’Afrique vers les États-Unis',
      image: 'assets/images/tracking.jpg',
      description:
          'Préparez un envoi au départ du Togo, en Afrique, à destination des États-Unis.',
    ),
    _Story(
      title: 'Des États-Unis vers l’Afrique',
      image: 'assets/images/home_hero.jpg',
      description:
          'Organisez la réception au Togo de colis expédiés depuis les États-Unis.',
    ),
    _Story(
      title: 'Un accompagnement à chaque étape',
      image: 'assets/images/story_courier.jpg',
      description:
          'Préparez les informations de votre colis et anticipez les formalités liées à votre expédition.',
    ),
  ];

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: AppColors.blue,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 28 : 20,
                vertical: isWide ? 64 : 44,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vos expéditions Afrique ↔ États-Unis',
                    style: _displayStyle(
                      fontSize: isWide ? 36 : 28,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 26),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final gap = 18.0;
                      final width = isWide
                          ? (constraints.maxWidth - 2 * gap) / 3
                          : constraints.maxWidth;
                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: _stories
                            .map(
                              (story) => SizedBox(
                                width: width,
                                child: _StoryCard(
                                  story: story,
                                  onPressed: onPlan,
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _Story {
  final String title;
  final String image;
  final String description;
  const _Story({
    required this.title,
    required this.image,
    required this.description,
  });
}

class _StoryCard extends StatelessWidget {
  final _Story story;
  final VoidCallback onPressed;

  const _StoryCard({required this.story, required this.onPressed});

  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              story.image,
              width: double.infinity,
              height: 190,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(story.title, style: _displayStyle(fontSize: 19)),
                  const SizedBox(height: 10),
                  Text(
                    story.description,
                    style: const TextStyle(
                      color: AppColors.muted,
                      height: 1.65,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton.icon(
                    onPressed: onPressed,
                    icon: const Icon(Icons.arrow_forward, size: 17),
                    label: const Text('Demander un devis'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.brandPinkDark,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _TrustSection extends StatelessWidget {
  final bool isWide;
  final VoidCallback onContact;
  final VoidCallback onPlan;

  const _TrustSection({
    required this.isWide,
    required this.onContact,
    required this.onPlan,
  });

  static const _items = [
    _TrustItem(
      title: 'Réactivité',
      description:
          'Pour une demande de prix ou la mise en place d’un transport international, comptez sur notre équipe.',
      image: 'assets/images/reactivite.png',
    ),
    _TrustItem(
      title: 'Accompagnement',
      description:
          'Parce que l’export et l’import ne s’improvisent pas, nos experts sont à vos côtés à chaque étape.',
      image: 'assets/images/accompagnement.png',
    ),
  ];

  @override
  Widget build(BuildContext context) => _SectionSurface(
        isWide: isWide,
        background: AppColors.white,
        child: Column(
          children: [
            Text(
              'Chez barrelGo, chaque client est unique',
              textAlign: TextAlign.center,
              style: _displayStyle(fontSize: isWide ? 30 : 24),
            ),
            const SizedBox(height: 28),
            LayoutBuilder(
              builder: (context, constraints) {
                final gap = 20.0;
                final width = isWide
                    ? (constraints.maxWidth - gap) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: _items
                      .map(
                        (item) => SizedBox(
                          width: width,
                          child: _TrustCard(item: item),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 28),
            const Text(
              'Nos clients peuvent vous le confirmer : notre équipe vous accompagne à chaque étape clé de votre expédition.',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.7),
            ),
            const SizedBox(height: 22),
            _CallToActions(onContact: onContact, onPlan: onPlan),
          ],
        ),
      );
}

class _TrustItem {
  final String title;
  final String description;
  final String image;

  const _TrustItem({
    required this.title,
    required this.description,
    required this.image,
  });
}

class _TrustCard extends StatelessWidget {
  final _TrustItem item;

  const _TrustCard({required this.item});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(item.image, width: 70, height: 70, fit: BoxFit.contain),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: _displayStyle(fontSize: 20)),
                  const SizedBox(height: 8),
                  Text(item.description, style: const TextStyle(height: 1.6)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _SiteFooter extends StatelessWidget {
  final bool isWide;
  final VoidCallback onContact;
  final VoidCallback onCall;
  final VoidCallback onLegal;
  final VoidCallback onPrivacy;

  const _SiteFooter({
    super.key,
    required this.isWide,
    required this.onContact,
    required this.onCall,
    required this.onLegal,
    required this.onPrivacy,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: const Color(0xFFF2F2F2),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 28 : 20,
                vertical: 30,
              ),
              child: isWide
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _FooterBrand(onLegal: onLegal, onPrivacy: onPrivacy),
                        _FooterContact(onContact: onContact, onCall: onCall),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FooterBrand(onLegal: onLegal, onPrivacy: onPrivacy),
                        const SizedBox(height: 24),
                        _FooterContact(onContact: onContact, onCall: onCall),
                      ],
                    ),
            ),
          ),
        ),
      );
}

class _FooterBrand extends StatelessWidget {
  final VoidCallback onLegal;
  final VoidCallback onPrivacy;

  const _FooterBrand({required this.onLegal, required this.onPrivacy});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BrandWordmark(isWide: true),
          const SizedBox(height: 10),
          const Text(
            'Vos expéditions entre l’Afrique et les États-Unis, avec le Togo comme point de départ ou de livraison.',
            style: TextStyle(color: AppColors.muted),
          ),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: onLegal,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.brandPinkDark,
                  padding: EdgeInsets.zero,
                ),
                child: const Text('Mentions légales'),
              ),
              TextButton(
                onPressed: onPrivacy,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.brandPinkDark,
                  padding: EdgeInsets.zero,
                ),
                child: const Text('Confidentialité'),
              ),
            ],
          ),
        ],
      );
}

class _FooterContact extends StatelessWidget {
  final VoidCallback onContact;
  final VoidCallback onCall;

  const _FooterContact({required this.onContact, required this.onCall});

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          OutlinedButton.icon(
            onPressed: onContact,
            icon: const Icon(Icons.mail_outline),
            label: const Text('Contactez-nous'),
          ),
          OutlinedButton.icon(
            onPressed: onCall,
            icon: const Icon(Icons.call),
            label: const Text('04 88 92 71 72'),
          ),
        ],
      );
}

class _SectionSurface extends StatelessWidget {
  final bool isWide;
  final Color background;
  final Widget child;

  const _SectionSurface({
    required this.isWide,
    required this.background,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        color: background,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1240),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 28 : 20,
                vertical: isWide ? 76 : 48,
              ),
              child: child,
            ),
          ),
        ),
      );
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final bool isWide;

  const _SectionHeading({required this.title, required this.isWide});

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: _displayStyle(fontSize: isWide ? 34 : 27),
      );
}

TextStyle _displayStyle({
  double fontSize = 24,
  Color color = AppColors.ink,
}) =>
    TextStyle(
      fontFamily: 'Poppins',
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      height: 1.25,
      color: color,
    );

class _BrandWordmark extends StatelessWidget {
  final bool isWide;

  const _BrandWordmark({required this.isWide});

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'barrelGo',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              color: AppColors.blue,
              size: isWide ? 31 : 27,
            ),
            const SizedBox(width: 7),
            Text(
              'barrelGo',
              style: _displayStyle(
                fontSize: isWide ? 25 : 22,
                color: AppColors.blue,
              ),
            ),
          ],
        ),
      );
}
