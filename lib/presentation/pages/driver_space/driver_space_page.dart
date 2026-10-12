import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

enum _DriverAuthView { login, register, recover }

class DriverSpacePage extends StatefulWidget {
  final ValueChanged<int> onOpenSection;

  const DriverSpacePage({
    super.key,
    required this.onOpenSection,
  });

  @override
  State<DriverSpacePage> createState() => _DriverSpacePageState();
}

class _DriverSpacePageState extends State<DriverSpacePage> {
  final _formKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();
  final _recoverFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  _DriverAuthView _authView = _DriverAuthView.login;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _acceptedTerms = false;
  bool _isConnected = false;
  bool _recoveryRequested = false;
  bool _isAvailable = true;
  bool _completedToday = false;
  int _totalDeliveries = 12;
  int _activeDeliveries = 3;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _vehicleController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _connect() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isConnected = true);
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
      _authView = _DriverAuthView.login;
      _passwordController.clear();
      _confirmPasswordController.clear();
      _acceptedTerms = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Compte de démonstration prêt. Aucune donnée n\'a été enregistrée.',
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
      _authView = _DriverAuthView.login;
      _recoveryRequested = false;
    });
  }

  void _signOut() {
    setState(() {
      _isConnected = false;
      _passwordController.clear();
    });
  }

  void _toggleAvailability(bool value) {
    setState(() => _isAvailable = value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isAvailable
              ? 'Vous êtes maintenant disponible.'
              : 'Vous êtes indisponible.',
        ),
      ),
    );
  }

  void _confirmDelivery() {
    setState(() {
      _activeDeliveries = (_activeDeliveries > 0) ? _activeDeliveries - 1 : 0;
      _completedToday = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Livraison confirmée avec succès.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isConnected) return _buildDashboard();
    return switch (_authView) {
      _DriverAuthView.login => _buildLogin(),
      _DriverAuthView.register => _buildRegister(),
      _DriverAuthView.recover => _buildRecovery(),
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
              setState(() => _authView = _DriverAuthView.recover),
          onRegister: () =>
              setState(() => _authView = _DriverAuthView.register),
        ),
      );

  Widget _buildRegister() => _buildAuthShell(
        _RegisterForm(
          formKey: _registerFormKey,
          nameController: _nameController,
          emailController: _emailController,
          phoneController: _phoneController,
          vehicleController: _vehicleController,
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
                              const Expanded(child: _DriverWelcomePanel()),
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
                            tooltip: 'Retour à l\'accueil',
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const _DriverWelcomePanel(compact: true),
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
                          onOpenProfile: () => widget.onOpenSection(4),
                        ),
                        const SizedBox(height: 20),
                        _AvailabilityCard(
                          isAvailable: _isAvailable,
                          onAvailabilityChanged: _toggleAvailability,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Vos livraisons du jour',
                          style: _headingStyle(isWide ? 25 : 22),
                        ),
                        const SizedBox(height: 14),
                        _StatsRow(
                          activeDeliveries: _activeDeliveries,
                          totalDeliveries: _totalDeliveries,
                          completedToday: _completedToday,
                        ),
                        const SizedBox(height: 20),
                        _ActiveDeliveriesCard(
                          onConfirmDelivery: _confirmDelivery,
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'Historique des livraisons',
                          style: _headingStyle(isWide ? 25 : 22),
                        ),
                        const SizedBox(height: 12),
                        const _DeliveryHistoryCard(
                          reference: 'BGO-248519',
                          destination: 'Togo',
                          status: 'Livré',
                          date: '04 oct. 2026',
                          time: '14:30',
                        ),
                        const SizedBox(height: 12),
                        const _DeliveryHistoryCard(
                          reference: 'BGO-247821',
                          destination: 'États-Unis',
                          status: 'Livré',
                          date: '03 oct. 2026',
                          time: '11:15',
                        ),
                        const SizedBox(height: 24),
                        const _SupportBanner(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
}

class _DriverWelcomePanel extends StatelessWidget {
  final bool compact;

  const _DriverWelcomePanel({this.compact = false});

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
              'Espace\nlivreur.',
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
              'Gérez vos livraisons entre le Togo et les États-Unis en temps réel.',
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
                    Icon(Icons.local_shipping, color: AppColors.brandPink),
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
              Text('Espace livreur', style: _headingStyle(30)),
              const SizedBox(height: 8),
              const Text(
                'Connectez-vous pour gérer vos livraisons.',
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
                validator: _validateEmail,
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
                  label: const Text('Créer un compte livreur'),
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
  final TextEditingController phoneController;
  final TextEditingController vehicleController;
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
    required this.phoneController,
    required this.vehicleController,
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
              Text('Créer un compte livreur', style: _headingStyle(30)),
              const SizedBox(height: 8),
              const Text(
                'Créez votre espace pour gérer vos livraisons Togo ↔ États-Unis.',
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
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Numéro de téléphone',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (value) => (value?.trim().isNotEmpty ?? false)
                    ? null
                    : 'Saisissez votre numéro de téléphone.',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: vehicleController,
                decoration: const InputDecoration(
                  labelText: 'Type de véhicule',
                  prefixIcon: Icon(Icons.directions_car_outlined),
                  hintText: 'Ex: Moto, Voiture, Camion',
                ),
                validator: (value) => (value?.trim().isNotEmpty ?? false)
                    ? null
                    : 'Saisissez votre type de véhicule.',
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
                    'J\'accepte les conditions d\'utilisation et la politique de confidentialité.',
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
                  child: const Text('J\'ai déjà un compte — Se connecter'),
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
                'Saisissez l\'adresse e-mail associée à votre compte.',
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
                          'Demande simulée. Aucun e-mail n\'a été envoyé car cet aperçu n\'est relié à aucun service de compte.',
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
                'Interface de démonstration uniquement : aucune donnée n\'est enregistrée et aucun e-mail n\'est envoyé.',
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
  final VoidCallback onOpenProfile;

  const _DashboardHeader({
    required this.onSignOut,
    required this.onOpenProfile,
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
            child: const Text(
              'JD',
              style: TextStyle(
                color: AppColors.brandPinkDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (MediaQuery.sizeOf(context).width >= 650) ...[
            const Text(
              'Jean Diomandé',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
          ],
          PopupMenuButton<String>(
            tooltip: 'Menu du compte',
            onSelected: (value) {
              if (value == 'logout') onSignOut();
              if (value == 'profile') onOpenProfile();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Text('Mon profil'),
              ),
              PopupMenuItem(
                value: 'logout',
                child: const Text('Se déconnecter'),
              ),
            ],
            icon: const Icon(Icons.more_vert),
          ),
        ],
      );
}

class _AvailabilityCard extends StatelessWidget {
  final bool isAvailable;
  final ValueChanged<bool> onAvailabilityChanged;

  const _AvailabilityCard({
    required this.isAvailable,
    required this.onAvailabilityChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Votre disponibilité',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isAvailable
                        ? 'Vous êtes disponible pour les livraisons'
                        : 'Vous êtes actuellement indisponible',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Material(
              color: Colors.transparent,
              child: Switch(
                value: isAvailable,
                activeColor: AppColors.green,
                onChanged: onAvailabilityChanged,
              ),
            ),
          ],
        ),
      );
}

class _StatsRow extends StatelessWidget {
  final int activeDeliveries;
  final int totalDeliveries;
  final bool completedToday;

  const _StatsRow({
    required this.activeDeliveries,
    required this.totalDeliveries,
    required this.completedToday,
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
              _StatCard(
                width: width,
                label: 'Livraisons actives',
                value: '$activeDeliveries',
                icon: Icons.local_shipping,
                color: AppColors.blue,
              ),
              _StatCard(
                width: width,
                label: 'Livraisons du jour',
                value: '$totalDeliveries',
                icon: Icons.calendar_today,
                color: AppColors.brandPink,
              ),
              _StatCard(
                width: width,
                label: 'Complétées',
                value: '${totalDeliveries - activeDeliveries}',
                icon: Icons.check_circle,
                color: AppColors.green,
              ),
            ],
          );
        },
      );
}

class _StatCard extends StatelessWidget {
  final double width;
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
}

class _ActiveDeliveriesCard extends StatelessWidget {
  final VoidCallback onConfirmDelivery;

  const _ActiveDeliveriesCard({required this.onConfirmDelivery});

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
            const Row(
              children: [
                Expanded(
                  child: Text(
                    'Prochaines livraisons',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                _StatusBadge(label: 'Actif', isActive: true),
              ],
            ),
            const SizedBox(height: 16),
            const _DeliveryTaskCard(
              reference: 'BGO-248519',
              sender: 'Marcel Langheu',
              destination: 'Togo',
              address: '123 Rue de l\'Indépendance, Lomé',
              priority: 'Haute',
            ),
            const SizedBox(height: 12),
            const _DeliveryTaskCard(
              reference: 'BGO-248520',
              sender: 'Kossi Agbenyenu',
              destination: 'Togo',
              address: '456 Avenue de la République, Accra',
              priority: 'Normale',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onConfirmDelivery,
                icon: const Icon(Icons.check_circle),
                label: const Text('Confirmer une livraison'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _DeliveryTaskCard extends StatelessWidget {
  final String reference;
  final String sender;
  final String destination;
  final String address;
  final String priority;

  const _DeliveryTaskCard({
    required this.reference,
    required this.sender,
    required this.destination,
    required this.address,
    required this.priority,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  reference,
                  style: const TextStyle(
                    color: AppColors.blue,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priority == 'Haute'
                        ? Color(0xFFFEEEED)
                        : Color(0xFFF0F5FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    priority,
                    style: TextStyle(
                      color: priority == 'Haute'
                          ? AppColors.brandPinkDark
                          : AppColors.blue,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              sender,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$destination • $address',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
}

class _DeliveryHistoryCard extends StatelessWidget {
  final String reference;
  final String destination;
  final String status;
  final String date;
  final String time;

  const _DeliveryHistoryCard({
    required this.reference,
    required this.destination,
    required this.status,
    required this.date,
    required this.time,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4EC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.green,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reference,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.blue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Livré au $destination • $date à $time',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, size: 20, color: AppColors.blue),
          ],
        ),
      );
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final bool isActive;

  const _StatusBadge({required this.label, required this.isActive});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEAF4EC) : AppColors.pinkTint,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.green : AppColors.blue,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _SupportBanner extends StatelessWidget {
  const _SupportBanner();

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
            Icon(Icons.support_agent, color: AppColors.brandPink, size: 26),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Besoin d\'assistance ?',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Notre équipe de support est disponible pour répondre à vos questions sur les livraisons.',
                    style: TextStyle(
                      color: Colors.white,
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
