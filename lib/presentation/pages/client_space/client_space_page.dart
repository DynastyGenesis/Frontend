import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

enum _ClientAuthView { login, register, recover }

enum _ClientDashboardRole { sender, recipient }

class ClientSpacePage extends StatefulWidget {
  final ValueChanged<int> onOpenSection;
  final bool startAsGuest;

  const ClientSpacePage({
    super.key,
    required this.onOpenSection,
    this.startAsGuest = false,
  });

  @override
  State<ClientSpacePage> createState() => _ClientSpacePageState();
}

class _ClientSpacePageState extends State<ClientSpacePage> {
  final _formKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  final _recoverFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  _ClientAuthView _authView = _ClientAuthView.login;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _acceptedTerms = false;
  bool _isConnected = false;
  bool _isGuest = false;
  bool _recoveryRequested = false;
  _ClientDashboardRole _dashboardRole = _ClientDashboardRole.sender;
  _PickupRequest? _pickupRequest;
  bool _recipientNotificationsEnabled = false;
  bool _recipientReceived = false;

  @override
  void initState() {
    super.initState();
    _isGuest = widget.startAsGuest;
    _isConnected = widget.startAsGuest;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _connect() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isConnected = true;
      _isGuest = false;
    });
  }

  void _continueAsGuest() {
    FocusScope.of(context).unfocus();
    setState(() {
      _isConnected = true;
      _isGuest = true;
    });
  }

  void _createAccount() {
    if (!_registerFormKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acceptez les conditions pour continuer.'),
        ),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _authView = _ClientAuthView.login;
      _passwordController.clear();
      _confirmPasswordController.clear();
      _acceptedTerms = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Compte de démonstration prêt. Aucune donnée n’a été enregistrée.',
        ),
      ),
    );
  }

  void _requestPasswordReset() {
    if (!_recoverFormKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _recoveryRequested = true);
  }

  void _showLogin() {
    setState(() {
      _authView = _ClientAuthView.login;
      _recoveryRequested = false;
    });
  }

  void _signOut() {
    setState(() {
      _isConnected = false;
      _isGuest = false;
      _passwordController.clear();
    });
  }

  void _showSignIn() {
    setState(() {
      _isConnected = false;
      _isGuest = false;
      _authView = _ClientAuthView.login;
    });
  }

  Future<void> _bookPickup() async {
    final request = await showDialog<_PickupRequest>(
      context: context,
      builder: (context) => const _PickupBookingDialog(),
    );
    if (request == null || !mounted) return;
    setState(() => _pickupRequest = request);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Pickup enregistré dans cet aperçu. Le paiement intégral sera dû à la collecte.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isConnected) return _buildDashboard();
    return switch (_authView) {
      _ClientAuthView.login => _buildLogin(),
      _ClientAuthView.register => _buildRegister(),
      _ClientAuthView.recover => _buildRecovery(),
    };
  }

  Widget _buildLogin() => _buildAuthShell(
        _LoginForm(
          formKey: _formKey,
          emailController: _emailController,
          passwordController: _passwordController,
          showPassword: _showPassword,
          onTogglePassword: () =>
              setState(() => _showPassword = !_showPassword),
          onSubmit: _connect,
          onBack: () => Navigator.of(context).pop(),
          onForgotPassword: () =>
              setState(() => _authView = _ClientAuthView.recover),
          onRegister: () =>
              setState(() => _authView = _ClientAuthView.register),
          onContinueAsGuest: _continueAsGuest,
        ),
      );

  Widget _buildRegister() => _buildAuthShell(
        _RegisterForm(
          formKey: _registerFormKey,
          nameController: _nameController,
          emailController: _emailController,
          passwordController: _passwordController,
          confirmPasswordController: _confirmPasswordController,
          showPassword: _showPassword,
          showConfirmPassword: _showConfirmPassword,
          acceptedTerms: _acceptedTerms,
          onTogglePassword: () =>
              setState(() => _showPassword = !_showPassword),
          onToggleConfirmPassword: () =>
              setState(() => _showConfirmPassword = !_showConfirmPassword),
          onTermsChanged: (value) =>
              setState(() => _acceptedTerms = value ?? false),
          onSubmit: _createAccount,
          onLogin: _showLogin,
        ),
      );

  Widget _buildRecovery() => _buildAuthShell(
        _RecoveryForm(
          formKey: _recoverFormKey,
          emailController: _emailController,
          requested: _recoveryRequested,
          onSubmit: _requestPasswordReset,
          onLogin: _showLogin,
        ),
      );

  Widget _buildAuthShell(Widget content) => Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              return isWide
                  ? Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(32),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Expanded(child: _ClientWelcomePanel()),
                              const SizedBox(width: 28),
                              Expanded(child: content),
                            ],
                          ),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            tooltip: 'Retour à l’accueil',
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const _ClientWelcomePanel(compact: true),
                        const SizedBox(height: 20),
                        content,
                      ],
                    );
            },
          ),
        ),
      );

  Widget _buildDashboard() => Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 850;
              final horizontalPadding = isWide ? 32.0 : 18.0;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  16,
                  horizontalPadding,
                  32,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DashboardHeader(
                          onSignOut: _signOut,
                          onSignIn: _showSignIn,
                          onOpenProfile: () => widget.onOpenSection(4),
                          isGuest: _isGuest,
                        ),
                        const SizedBox(height: 20),
                        SegmentedButton<_ClientDashboardRole>(
                          segments: const [
                            ButtonSegment(
                              value: _ClientDashboardRole.sender,
                              icon: Icon(Icons.outbox_outlined),
                              label: Text('Expéditeur'),
                            ),
                            ButtonSegment(
                              value: _ClientDashboardRole.recipient,
                              icon: Icon(Icons.move_to_inbox_outlined),
                              label: Text('Destinataire (Togo)'),
                            ),
                          ],
                          selected: {_dashboardRole},
                          onSelectionChanged: (selection) => setState(
                            () => _dashboardRole = selection.first,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_dashboardRole == _ClientDashboardRole.sender)
                          _buildSenderDashboard(isWide)
                        else
                          _buildRecipientDashboard(isWide),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );

  Widget _buildSenderDashboard(bool isWide) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WelcomeBanner(
            isSender: true,
            isGuest: _isGuest,
            pickupBooked: _pickupRequest != null,
            onPrimary: _bookPickup,
            onTrack: () => widget.onOpenSection(1),
          ),
          const SizedBox(height: 20),
          _PickupPaymentNotice(
            pickupBooked: _pickupRequest != null,
            pickupRequest: _pickupRequest,
          ),
          const SizedBox(height: 28),
          Text(
            'Suivez votre expédition',
            style: _headingStyle(isWide ? 25 : 22),
          ),
          const SizedBox(height: 14),
          _QuickActions(
            onOpenSection: widget.onOpenSection,
            onBookPickup: _bookPickup,
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Envois récents',
                  style: _headingStyle(isWide ? 25 : 22),
                ),
              ),
              TextButton(
                onPressed: () => widget.onOpenSection(3),
                child: const Text('Tout voir'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _RecentShipmentCard(
            reference: 'BGO-248519',
            route: 'Lomé, Togo  →  New York, États-Unis',
            status: 'En transit',
            statusColor: AppColors.blue,
            statusBackground: AppColors.pinkTint,
            date: 'Pris en charge le 04 oct. 2026',
            progress: .62,
          ),
          const SizedBox(height: 12),
          const _RecentShipmentCard(
            reference: 'BGO-247821',
            route: 'New York, États-Unis  →  Lomé, Togo',
            status: 'Livré',
            statusColor: AppColors.green,
            statusBackground: Color(0xFFEAF4EC),
            date: 'Livré le 28 sept. 2026',
            progress: 1,
          ),
          const SizedBox(height: 24),
          const _HelpBanner(),
        ],
      );

  Widget _buildRecipientDashboard(bool isWide) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WelcomeBanner(
            isSender: false,
            isGuest: _isGuest,
            pickupBooked: false,
            onPrimary: () => widget.onOpenSection(1),
            onTrack: () => widget.onOpenSection(3),
          ),
          const SizedBox(height: 24),
          _RecipientShipmentCard(
            notificationsEnabled: _recipientNotificationsEnabled,
            received: _recipientReceived,
            onNotificationsChanged: (value) => setState(
              () => _recipientNotificationsEnabled = value,
            ),
            onReceived: () => setState(() => _recipientReceived = true),
          ),
          const SizedBox(height: 20),
          Text(
            'À savoir',
            style: _headingStyle(isWide ? 25 : 22),
          ),
          const SizedBox(height: 12),
          const _RecipientInfoCard(),
        ],
      );
}

class _ClientWelcomePanel extends StatelessWidget {
  final bool compact;

  const _ClientWelcomePanel({this.compact = false});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: compact ? 180 : 520),
        padding: EdgeInsets.all(compact ? 24 : 42),
        decoration: BoxDecoration(
          color: AppColors.blue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment:
              compact ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            const _BrandWordmark(),
            SizedBox(height: compact ? 20 : 56),
            Text(
              'Vos expéditions,\nà portée de main.',
              style: TextStyle(
                color: AppColors.white,
                fontSize: compact ? 28 : 42,
                fontWeight: FontWeight.w800,
                height: 1.12,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Retrouvez vos colis et palettes entre le Togo et les États-Unis, dans les deux sens.',
              style: TextStyle(
                color: Colors.white,
                height: 1.7,
                fontSize: 15,
              ),
            ),
            if (!compact) ...[
              const SizedBox(height: 34),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .1),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sync_alt, color: AppColors.brandPink),
                    SizedBox(width: 12),
                    Text(
                      'Togo  ↔  États-Unis',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
}

class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool showPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final VoidCallback onBack;
  final VoidCallback onForgotPassword;
  final VoidCallback onRegister;
  final VoidCallback onContinueAsGuest;

  const _LoginForm({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.showPassword,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.onBack,
    required this.onForgotPassword,
    required this.onRegister,
    required this.onContinueAsGuest,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (MediaQuery.sizeOf(context).width >= 900)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Retour au site'),
                  ),
                ),
              Text('Espace client', style: _headingStyle(30)),
              const SizedBox(height: 8),
              const Text(
                'Connectez-vous pour retrouver vos expéditions.',
                style: TextStyle(color: AppColors.muted, height: 1.6),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Adresse e-mail',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return 'Saisissez votre adresse e-mail.';
                  if (!email.contains('@') || !email.contains('.')) {
                    return 'Saisissez une adresse e-mail valide.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: passwordController,
                obscureText: !showPassword,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: showPassword
                        ? 'Masquer le mot de passe'
                        : 'Afficher le mot de passe',
                    onPressed: onTogglePassword,
                    icon: Icon(
                      showPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
                validator: (value) => (value ?? '').isEmpty
                    ? 'Saisissez votre mot de passe.'
                    : null,
                onFieldSubmitted: (_) => onSubmit(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onForgotPassword,
                  child: const Text('Mot de passe oublié ?'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onSubmit,
                  icon: const Icon(Icons.login),
                  label: const Text('Se connecter'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandPinkDark,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onRegister,
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Créer un compte'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.blue,
                    side: const BorderSide(color: AppColors.blue),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: onContinueAsGuest,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Accéder au tableau client sans compte'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.pinkTint,
                  border: Border.all(color: AppColors.pinkBorder),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: AppColors.brandPinkDark,
                    ),
                    SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Aperçu de démonstration : la connexion et les données ne sont pas reliées à un service de compte.',
                        style: TextStyle(
                          color: AppColors.ink,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _RegisterForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool showPassword;
  final bool showConfirmPassword;
  final bool acceptedTerms;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final ValueChanged<bool?> onTermsChanged;
  final VoidCallback onSubmit;
  final VoidCallback onLogin;

  const _RegisterForm({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.showPassword,
    required this.showConfirmPassword,
    required this.acceptedTerms,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onTermsChanged,
    required this.onSubmit,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) => _AuthCard(
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Créer un compte', style: _headingStyle(30)),
              const SizedBox(height: 8),
              const Text(
                'Créez votre espace pour préparer vos expéditions Togo ↔ États-Unis.',
                style: TextStyle(color: AppColors.muted, height: 1.6),
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => (value?.trim().isNotEmpty ?? false)
                    ? null
                    : 'Saisissez votre nom complet.',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Adresse e-mail',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                validator: _validateEmail,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passwordController,
                obscureText: !showPassword,
                autofillHints: const [AutofillHints.newPassword],
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  helperText: '8 caractères minimum',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: showPassword
                        ? 'Masquer le mot de passe'
                        : 'Afficher le mot de passe',
                    onPressed: onTogglePassword,
                    icon: Icon(
                      showPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
                validator: (value) => (value?.length ?? 0) >= 8
                    ? null
                    : 'Utilisez au moins 8 caractères.',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: !showConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirmer le mot de passe',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: showConfirmPassword
                        ? 'Masquer le mot de passe'
                        : 'Afficher le mot de passe',
                    onPressed: onToggleConfirmPassword,
                    icon: Icon(
                      showConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                  ),
                ),
                validator: (value) =>
                    value == passwordController.text && (value ?? '').isNotEmpty
                        ? null
                        : 'Les mots de passe ne correspondent pas.',
              ),
              const SizedBox(height: 8),
              Material(
                color: AppColors.white,
                child: CheckboxListTile(
                  value: acceptedTerms,
                  onChanged: onTermsChanged,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'J’accepte les conditions d’utilisation et la politique de confidentialité.',
                    style: TextStyle(fontSize: 12, height: 1.5),
                  ),
                  activeColor: AppColors.brandPinkDark,
                ),
              ),
              const SizedBox(height: 10),
              _AuthPrimaryButton(
                label: 'Créer mon compte',
                icon: Icons.person_add_alt_1,
                onPressed: onSubmit,
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: onLogin,
                  child: const Text('J’ai déjà un compte — Se connecter'),
                ),
              ),
              const _DemoNotice(),
            ],
          ),
        ),
      );
}

class _RecoveryForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final bool requested;
  final VoidCallback onSubmit;
  final VoidCallback onLogin;

  const _RecoveryForm({
    required this.formKey,
    required this.emailController,
    required this.requested,
    required this.onSubmit,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) => _AuthCard(
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mot de passe oublié', style: _headingStyle(30)),
              const SizedBox(height: 8),
              const Text(
                'Saisissez l’adresse e-mail associée à votre compte.',
                style: TextStyle(color: AppColors.muted, height: 1.6),
              ),
              const SizedBox(height: 22),
              if (requested) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.pinkTint,
                    border: Border.all(color: AppColors.pinkBorder),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.mark_email_read_outlined,
                          color: AppColors.brandPinkDark),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Demande simulée. Aucun e-mail n’a été envoyé car cet aperçu n’est relié à aucun service de compte.',
                          style: TextStyle(height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'Adresse e-mail',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: _validateEmail,
                ),
                const SizedBox(height: 18),
                _AuthPrimaryButton(
                  label: 'Continuer',
                  icon: Icons.arrow_forward,
                  onPressed: onSubmit,
                ),
              ],
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: onLogin,
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Retour à la connexion'),
                ),
              ),
              const _DemoNotice(),
            ],
          ),
        ),
      );
}

class _AuthCard extends StatelessWidget {
  final Widget child;

  const _AuthCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      );
}

class _AuthPrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _AuthPrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brandPinkDark,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(vertical: 17),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
}

class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.pinkTint,
          border: Border.all(color: AppColors.pinkBorder),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 18, color: AppColors.brandPinkDark),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'Interface de démonstration uniquement : aucune donnée n’est enregistrée et aucun e-mail n’est envoyé.',
                style: TextStyle(
                  color: AppColors.ink,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
}

String? _validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Saisissez votre adresse e-mail.';
  if (!email.contains('@') || !email.contains('.')) {
    return 'Saisissez une adresse e-mail valide.';
  }
  return null;
}

class _DashboardHeader extends StatelessWidget {
  final VoidCallback onSignOut;
  final VoidCallback onSignIn;
  final VoidCallback onOpenProfile;
  final bool isGuest;

  const _DashboardHeader({
    required this.onSignOut,
    required this.onSignIn,
    required this.onOpenProfile,
    required this.isGuest,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const _BrandWordmark(dark: true),
          const Spacer(),
          const Icon(Icons.notifications_none, color: AppColors.blue),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: AppColors.pinkTint,
            child: Text(
              isGuest ? 'I' : 'ML',
              style: const TextStyle(
                color: AppColors.brandPinkDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (MediaQuery.sizeOf(context).width >= 650) ...[
            Text(
              isGuest ? 'Mode invité' : 'Marcel Langheu',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
          ],
          PopupMenuButton<String>(
            tooltip: 'Menu du compte',
            onSelected: (value) {
              if (value == 'logout') onSignOut();
              if (value == 'profile') onOpenProfile();
              if (value == 'signin') onSignIn();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Text('Mon profil'),
              ),
              if (isGuest)
                const PopupMenuItem(
                  value: 'signin',
                  child: Text('Se connecter'),
                ),
              PopupMenuItem(
                value: 'logout',
                child: Text(
                  isGuest ? 'Quitter le tableau client' : 'Se déconnecter',
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
      );
}

class _WelcomeBanner extends StatelessWidget {
  final bool isSender;
  final bool isGuest;
  final bool pickupBooked;
  final VoidCallback onPrimary;
  final VoidCallback onTrack;

  const _WelcomeBanner({
    required this.isSender,
    required this.isGuest,
    required this.pickupBooked,
    required this.onPrimary,
    required this.onTrack,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: AppColors.blue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 600;
            final welcome = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ESPACE CLIENT  •  TOGO ↔ ÉTATS-UNIS',
                  style: TextStyle(
                    color: AppColors.brandPink,
                    fontSize: 12,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isGuest
                      ? 'Bienvenue, invité !'
                      : isSender
                          ? 'Bonjour, Marcel !'
                          : 'Bonjour, Kossi !',
                  style: _headingStyle(32, color: AppColors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  isSender
                      ? 'Réservez une collecte, réglez à la prise en charge et suivez votre colis.'
                      : 'Suivez le colis qui vous est destiné au Togo et choisissez vos notifications.',
                  style: const TextStyle(color: Colors.white, height: 1.6),
                ),
              ],
            );
            final action = FilledButton.icon(
              onPressed: isSender ? onPrimary : onTrack,
              icon:
                  Icon(isSender ? Icons.local_shipping_outlined : Icons.search),
              label: Text(
                isSender
                    ? pickupBooked
                        ? 'Réserver un autre pickup'
                        : 'Réserver un pickup'
                    : 'Suivre mon colis',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPink,
                foregroundColor: AppColors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            );
            return stacked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      welcome,
                      const SizedBox(height: 20),
                      action,
                    ],
                  )
                : Row(
                    children: [
                      Expanded(child: welcome),
                      const SizedBox(width: 16),
                      action,
                    ],
                  );
          },
        ),
      );
}

class _PickupPaymentNotice extends StatelessWidget {
  final bool pickupBooked;
  final _PickupRequest? pickupRequest;

  const _PickupPaymentNotice({
    required this.pickupBooked,
    required this.pickupRequest,
  });

  @override
  Widget build(BuildContext context) {
    final request = pickupRequest;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.pinkBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.payments_outlined,
                color: AppColors.brandPinkDark,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paiement à la collecte',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'L’intégralité du montant de l’expédition est réglée au moment où le colis est récupéré. Aucun paiement lors de la réservation.',
                      style: TextStyle(
                        color: AppColors.muted,
                        height: 1.55,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (pickupBooked && request != null) ...[
            const Divider(height: 26),
            Text(
              'Pickup réservé • ${request.route}',
              style: const TextStyle(
                color: AppColors.blue,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '${_formatDate(request.date)} • ${request.timeWindow}\n'
              'Collecte : ${request.pickupAddress} • ${request.senderPhone}\n'
              'Destinataire : ${request.recipientName} • ${request.recipientPhone}\n'
              'Livraison : ${request.deliveryAddress}\n'
              'Colis : ${request.parcelDescription}',
              style: const TextStyle(
                color: AppColors.muted,
                height: 1.5,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecipientShipmentCard extends StatelessWidget {
  final bool notificationsEnabled;
  final bool received;
  final ValueChanged<bool> onNotificationsChanged;
  final VoidCallback onReceived;

  const _RecipientShipmentCard({
    required this.notificationsEnabled,
    required this.received,
    required this.onNotificationsChanged,
    required this.onReceived,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Colis à recevoir au Togo',
                    style: _headingStyle(21),
                  ),
                ),
                _StatusBadge(
                  label: received ? 'Réception confirmée' : 'En transit',
                  isDelivered: received,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'BGO-248519',
              style: TextStyle(
                color: AppColors.blue,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'New York, États-Unis  →  Lomé, Togo',
              style: TextStyle(fontWeight: FontWeight.w700, height: 1.5),
            ),
            const SizedBox(height: 5),
            Text(
              received
                  ? 'Vous avez confirmé la réception de ce colis.'
                  : 'Le colis est en route vers son destinataire à Lomé.',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            _DeliveryTimeline(received: received),
            const SizedBox(height: 14),
            const Divider(),
            Material(
              color: AppColors.white,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: notificationsEnabled,
                activeThumbColor: AppColors.brandPinkDark,
                onChanged: onNotificationsChanged,
                title: const Text(
                  'Notifications de livraison',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                subtitle: Text(
                  notificationsEnabled
                      ? 'Vous serez averti des changements de statut (simulation).'
                      : 'Activez cette option si vous souhaitez être averti.',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
                secondary: const Icon(
                  Icons.notifications_active_outlined,
                  color: AppColors.brandPinkDark,
                ),
              ),
            ),
            if (!received) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmReceipt(context),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Confirmer la réception du colis'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.blue,
                    side: const BorderSide(color: AppColors.blue),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );

  Future<void> _confirmReceipt(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Colis bien reçu ?'),
        content: const Text(
          'Confirmez uniquement si le colis vous a bien été remis à Lomé.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Pas encore'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Oui, confirmer'),
          ),
        ],
      ),
    );
    if (confirmed == true) onReceived();
  }
}

class _DeliveryTimeline extends StatelessWidget {
  final bool received;

  const _DeliveryTimeline({required this.received});

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('Colis collecté aux États-Unis', true),
      ('En transit vers le Togo', true),
      ('Arrivé au Togo', received),
      ('Remis au destinataire', received),
    ];
    return Column(
      children: [
        for (var index = 0; index < steps.length; index++)
          Padding(
            padding:
                EdgeInsets.only(bottom: index == steps.length - 1 ? 0 : 12),
            child: Row(
              children: [
                Icon(
                  steps[index].$2
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  size: 19,
                  color: steps[index].$2
                      ? AppColors.green
                      : AppColors.muted.withValues(alpha: .55),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    steps[index].$1,
                    style: TextStyle(
                      fontSize: 13,
                      color: steps[index].$2 ? AppColors.ink : AppColors.muted,
                      fontWeight:
                          steps[index].$2 ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final bool isDelivered;

  const _StatusBadge({required this.label, required this.isDelivered});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDelivered ? const Color(0xFFEAF4EC) : AppColors.pinkTint,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isDelivered ? AppColors.green : AppColors.blue,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _RecipientInfoCard extends StatelessWidget {
  const _RecipientInfoCard();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.blue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: AppColors.brandPink),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Le destinataire peut suivre l’acheminement et activer les notifications de statut. Cette maquette ne transmet pas de notifications réelles.',
                style:
                    TextStyle(color: Colors.white, height: 1.6, fontSize: 13),
              ),
            ),
          ],
        ),
      );
}

class _PickupRequest {
  final String route;
  final DateTime date;
  final String timeWindow;
  final String pickupAddress;
  final String senderPhone;
  final String recipientName;
  final String recipientPhone;
  final String deliveryAddress;
  final String parcelDescription;

  const _PickupRequest({
    required this.route,
    required this.date,
    required this.timeWindow,
    required this.pickupAddress,
    required this.senderPhone,
    required this.recipientName,
    required this.recipientPhone,
    required this.deliveryAddress,
    required this.parcelDescription,
  });
}

class _PickupBookingDialog extends StatefulWidget {
  const _PickupBookingDialog();

  @override
  State<_PickupBookingDialog> createState() => _PickupBookingDialogState();
}

class _PickupBookingDialogState extends State<_PickupBookingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pickupAddress = TextEditingController();
  final _senderPhone = TextEditingController();
  final _recipientName = TextEditingController();
  final _recipientPhone = TextEditingController();
  final _deliveryAddress = TextEditingController();
  final _parcelDescription = TextEditingController();
  DateTime _pickupDate = DateTime.now().add(const Duration(days: 1));
  String _timeWindow = '08:00 – 12:00';
  String _route = 'Togo → États-Unis';

  static const _timeWindows = [
    '08:00 – 12:00',
    '12:00 – 16:00',
    '16:00 – 19:00',
  ];

  @override
  void dispose() {
    _pickupAddress.dispose();
    _senderPhone.dispose();
    _recipientName.dispose();
    _recipientPhone.dispose();
    _deliveryAddress.dispose();
    _parcelDescription.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _pickupDate.isBefore(now) ? now : _pickupDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _pickupDate = date);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      _PickupRequest(
        route: _route,
        date: _pickupDate,
        timeWindow: _timeWindow,
        pickupAddress: _pickupAddress.text.trim(),
        senderPhone: _senderPhone.text.trim(),
        recipientName: _recipientName.text.trim(),
        recipientPhone: _recipientPhone.text.trim(),
        deliveryAddress: _deliveryAddress.text.trim(),
        parcelDescription: _parcelDescription.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Réserver un pickup'),
        content: SizedBox(
          width: 480,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Collecte du colis et détails de livraison',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _route,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Sens de l’expédition',
                      prefixIcon: Icon(Icons.swap_horiz),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Togo → États-Unis',
                        child: Text(
                          'Togo → États-Unis',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'États-Unis → Togo',
                        child: Text(
                          'États-Unis → Togo',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _route = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_month),
                    label:
                        Text('Date de collecte : ${_formatDate(_pickupDate)}'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _timeWindow,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Créneau de collecte',
                      prefixIcon: Icon(Icons.schedule),
                    ),
                    items: _timeWindows
                        .map(
                          (window) => DropdownMenuItem(
                            value: window,
                            child: Text(window),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _timeWindow = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  _PickupField(
                    controller: _pickupAddress,
                    label: 'Adresse de collecte',
                    icon: Icons.home_outlined,
                  ),
                  const SizedBox(height: 12),
                  _PickupField(
                    controller: _senderPhone,
                    label: 'Téléphone du client expéditeur',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 18),
                  const _PickupFormSectionTitle(title: 'Destinataire'),
                  const SizedBox(height: 10),
                  _PickupField(
                    controller: _recipientName,
                    label: 'Nom du destinataire',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 12),
                  _PickupField(
                    controller: _recipientPhone,
                    label: 'Téléphone du destinataire',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _PickupField(
                    controller: _deliveryAddress,
                    label: 'Adresse de livraison',
                    icon: Icons.place_outlined,
                  ),
                  const SizedBox(height: 18),
                  const _PickupFormSectionTitle(title: 'Colis'),
                  const SizedBox(height: 10),
                  _PickupField(
                    controller: _parcelDescription,
                    label: 'Description du colis',
                    icon: Icons.inventory_2_outlined,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.pinkTint,
                      border: Border.all(color: AppColors.pinkBorder),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.payments_outlined,
                            color: AppColors.brandPinkDark, size: 19),
                        SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'Paiement : 100 % du montant sera réglé au moment de la collecte. Aucun paiement n’est demandé ici.',
                            style: TextStyle(fontSize: 12, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.event_available),
            label: const Text('Confirmer le pickup'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandPinkDark,
              foregroundColor: AppColors.white,
            ),
          ),
        ],
      );
}

class _PickupField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;

  const _PickupField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          alignLabelWithHint: maxLines > 1,
        ),
        validator: (value) => (value?.trim().isNotEmpty ?? false)
            ? null
            : 'Ce champ est obligatoire.',
      );
}

class _PickupFormSectionTitle extends StatelessWidget {
  final String title;

  const _PickupFormSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            color: AppColors.blue,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

class _QuickActions extends StatelessWidget {
  final ValueChanged<int> onOpenSection;
  final VoidCallback onBookPickup;

  const _QuickActions({
    required this.onOpenSection,
    required this.onBookPickup,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 720 ? 3 : 1;
          final spacing = 12.0;
          final width =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              _QuickActionCard(
                width: width,
                icon: Icons.local_shipping_outlined,
                title: 'Réserver un pickup',
                subtitle: 'Choisir collecte et destinataire',
                onTap: onBookPickup,
              ),
              _QuickActionCard(
                width: width,
                icon: Icons.location_searching,
                title: 'Suivre un colis',
                subtitle: 'Consulter une expédition',
                onTap: () => onOpenSection(1),
              ),
              _QuickActionCard(
                width: width,
                icon: Icons.inventory_2_outlined,
                title: 'Mes envois',
                subtitle: 'Voir tous vos colis',
                onTap: () => onOpenSection(3),
              ),
            ],
          );
        },
      );
}

class _QuickActionCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(icon, color: AppColors.brandPinkDark, size: 25),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
        ),
      );
}

class _RecentShipmentCard extends StatelessWidget {
  final String reference;
  final String route;
  final String status;
  final Color statusColor;
  final Color statusBackground;
  final String date;
  final double progress;

  const _RecentShipmentCard({
    required this.reference,
    required this.route,
    required this.status,
    required this.statusColor,
    required this.statusBackground,
    required this.date,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  reference,
                  style: const TextStyle(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              route,
              style: const TextStyle(fontWeight: FontWeight.w700, height: 1.5),
            ),
            const SizedBox(height: 8),
            Text(
              date,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.pinkTint,
                color: AppColors.brandPinkDark,
              ),
            ),
          ],
        ),
      );
}

class _HelpBanner extends StatelessWidget {
  const _HelpBanner();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.pinkTint,
          border: Border.all(color: AppColors.pinkBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.support_agent, color: AppColors.brandPinkDark, size: 26),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Besoin d’aide pour un envoi ?',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Notre équipe peut vous accompagner dans la préparation de votre expédition entre le Togo et les États-Unis.',
                    style: TextStyle(
                      color: AppColors.muted,
                      height: 1.5,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _BrandWordmark extends StatelessWidget {
  final bool dark;

  const _BrandWordmark({this.dark = false});

  @override
  Widget build(BuildContext context) => RichText(
        text: TextSpan(
          style: TextStyle(
            color: dark ? AppColors.blue : AppColors.white,
            fontSize: 23,
            fontWeight: FontWeight.w800,
            letterSpacing: -.7,
          ),
          children: const [
            TextSpan(text: 'barrel'),
            TextSpan(
              text: 'Go',
              style: TextStyle(color: AppColors.brandPink),
            ),
          ],
        ),
      );
}

TextStyle _headingStyle(double size, {Color color = AppColors.ink}) =>
    TextStyle(
      color: color,
      fontSize: size,
      fontWeight: FontWeight.w800,
      letterSpacing: -.6,
      height: 1.2,
    );
