import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/api/api_exception.dart';
import '../../../data/app_services.dart';
import '../../../features/client_flow.dart';
import '../../../features/driver_flow.dart';

const blue = Color(0xFF005BF3);
const navy = Color(0xFF08264C);
const muted = Color(0xFF73849B);

class ShipsLoginPage extends StatefulWidget {
  final bool driver;

  /// Vrai quand une session Google vient d'être créée : la page termine la
  /// connexion sans demander d'identifiants.
  final bool resumeSession;
  const ShipsLoginPage({
    super.key,
    this.driver = false,
    this.resumeSession = false,
  });
  @override
  State<ShipsLoginPage> createState() => _ShipsLoginPageState();
}

class _ShipsLoginPageState extends State<ShipsLoginPage> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(),
      password = TextEditingController(),
      name = TextEditingController();
  bool register = false, hidden = true;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();
    super.dispose();
  }

  bool busy = false;

  @override
  void initState() {
    super.initState();
    final services = AppServices.instance;
    if (widget.resumeSession && services != null && services.auth.isSignedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finishSignIn());
    }
  }

  Future<void> signInWithGoogle() async {
    final services = AppServices.instance;
    if (services == null) return;
    if (!kIsWeb) {
      _notify('La connexion Google est disponible sur la version web.');
      return;
    }
    final base = Uri.base;
    final back = Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: base.path,
      queryParameters: {'space': widget.driver ? 'driver' : 'client'},
    );
    final opened = await launchUrl(
      services.auth.googleSignInUrl(back.toString()),
      webOnlyWindowName: '_self',
    );
    if (!opened) _notify('Impossible d’ouvrir la connexion Google.');
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _openSpace() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => widget.driver
            ? const DriverBackendMenuScreen()
            : const ClientBackendMenuScreen(),
      ),
    );
  }

  Future<String?> _askVehicle() => showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Votre véhicule'),
      children: [
        for (final option in const {
          'moto': 'Moto',
          'tricycle': 'Tricycle',
          'camionnette': 'Camionnette',
        }.entries)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, option.key),
            child: Text(option.value),
          ),
      ],
    ),
  );

  Future<void> submit() async {
    if (!form.currentState!.validate() || busy) return;
    FocusScope.of(context).unfocus();
    final services = AppServices.instance;
    if (services == null) return;
    setState(() => busy = true);
    try {
      if (register) {
        final result = await services.auth.signUp(
          email: email.text,
          password: password.text,
          name: name.text,
        );
        if (result.needsEmailConfirmation) {
          _notify(
            'Compte créé. Confirmez votre adresse e-mail, puis connectez-vous.',
          );
          if (mounted) setState(() => register = false);
          return;
        }
      } else {
        await services.auth.signIn(email: email.text, password: password.text);
      }
      await _completeSignIn(services);
    } on ApiException catch (error) {
      _notify(error.displayMessage);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _finishSignIn() async {
    final services = AppServices.instance;
    if (services == null || busy) return;
    setState(() => busy = true);
    try {
      await _completeSignIn(services);
    } on ApiException catch (error) {
      _notify(error.displayMessage);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _completeSignIn(AppServices services) async {
    var user = await services.api.me();
    if (widget.driver && !user.isDriver) {
      if (!mounted) return;
      final vehicle = await _askVehicle();
      if (vehicle == null) {
        await services.auth.signOut();
        return;
      }
      try {
        await services.api.becomeDriver(vehicleType: vehicle);
      } on ApiException catch (error) {
        if (!error.isConflict) rethrow;
      }
      user = await services.api.me();
    }
    services.startPush();
    if (!mounted) return;
    _openSpace();
  }

  Future<void> resetPassword() async {
    final services = AppServices.instance;
    if (services == null) return;
    final address = email.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(address)) {
      _notify('Saisissez votre adresse e-mail pour recevoir le lien.');
      return;
    }
    try {
      await services.auth.requestPasswordReset(address);
      _notify(
        'Si ce compte existe, un e-mail de réinitialisation vient d’être envoyé.',
      );
    } on ApiException catch (error) {
      _notify(error.displayMessage);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF1F7FE),
    appBar: AppBar(
      backgroundColor: Colors.white,
      title: Text(
        widget.driver ? 'BarelGo · Espace livreur' : 'BarelGo · Espace client',
        style: const TextStyle(fontSize: 17, color: navy),
      ),
    ),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Card(
            color: Colors.white,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Form(
                key: form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.view_in_ar_outlined,
                      color: blue,
                      size: 46,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      register
                          ? widget.driver
                                ? 'Créer votre compte livreur'
                                : 'Créer votre compte client'
                          : 'Connectez-vous à votre espace',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: navy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.driver
                          ? 'Gérez vos missions, collectes et livraisons avec BarelGo.'
                          : 'Réservez et suivez vos colis des États-Unis au Togo.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: muted),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF4FF),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Text(
                        'Connexion sécurisée : votre compte est vérifié par le service BarelGo.',
                        style: TextStyle(fontSize: 11, color: navy),
                      ),
                    ),
                    const SizedBox(height: 22),
                    if (register) ...[
                      TextFormField(
                        controller: name,
                        decoration: const InputDecoration(
                          labelText: 'Nom complet',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Saisissez votre nom.'
                            : null,
                      ),
                      const SizedBox(height: 18),
                    ],
                    TextFormField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Adresse e-mail',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      validator: (v) =>
                          v == null ||
                              !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                  .hasMatch(v.trim())
                          ? 'Saisissez une adresse e-mail valide.'
                          : null,
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: password,
                      obscureText: hidden,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: hidden
                              ? 'Afficher le mot de passe'
                              : 'Masquer le mot de passe',
                          onPressed: () => setState(() => hidden = !hidden),
                          icon: Icon(
                            hidden
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (v) => v == null || v.length < 6
                          ? 'Saisissez au moins 6 caractères.'
                          : null,
                      onFieldSubmitted: (_) => submit(),
                    ),
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: submit,
                      child: Text(
                        register ? 'Créer mon compte' : 'Se connecter',
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: busy ? null : signInWithGoogle,
                      icon: const Text(
                        'G',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Color(0xFFDB4437),
                        ),
                      ),
                      label: const Text('Continuer avec Google'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() => register = !register),
                      child: Text(
                        register
                            ? 'J’ai déjà un compte — Se connecter'
                            : widget.driver
                            ? 'Créer un compte livreur'
                            : 'Créer un compte client',
                      ),
                    ),
                    if (!register)
                      TextButton(
                        onPressed: resetPassword,
                        child: const Text('Mot de passe oublié ?'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
