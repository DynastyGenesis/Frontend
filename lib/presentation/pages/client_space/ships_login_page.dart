import 'package:flutter/material.dart';
import 'ships_client_page.dart';
import '../driver_space/ships_driver_page.dart';

class ShipsLoginPage extends StatefulWidget {
  final bool driver;
  const ShipsLoginPage({super.key, this.driver = false});
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

  void submit() {
    if (!form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
        builder: (_) =>
            widget.driver ? const ShipsDriverPage() : const ShipsClientPage()));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: const Color(0xFFF1F7FE),
      appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
              widget.driver
                  ? 'Ships4US · Espace livreur'
                  : 'Ships4US · Espace client',
              style: const TextStyle(fontSize: 17, color: navy))),
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Icon(Icons.view_in_ar_outlined,
                                        color: blue, size: 46),
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
                                            color: navy)),
                                    const SizedBox(height: 8),
                                    Text(
                                        widget.driver
                                            ? 'Gérez vos missions, collectes et livraisons avec Ships4US.'
                                            : 'Réservez et suivez vos colis des États-Unis au Togo.',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontSize: 12, color: muted)),
                                    const SizedBox(height: 24),
                                    Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                            color: const Color(0xFFEAF4FF),
                                            borderRadius:
                                                BorderRadius.circular(7)),
                                        child: const Text(
                                            'Accès de démonstration : aucun compte n’est créé ni vérifié par un serveur.',
                                            style: TextStyle(
                                                fontSize: 11, color: navy))),
                                    const SizedBox(height: 22),
                                    if (register) ...[
                                      TextFormField(
                                          controller: name,
                                          decoration: const InputDecoration(
                                              labelText: 'Nom complet'),
                                          validator: (v) =>
                                              v == null || v.trim().isEmpty
                                                  ? 'Saisissez votre nom.'
                                                  : null),
                                      const SizedBox(height: 18)
                                    ],
                                    TextFormField(
                                        controller: email,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        autofillHints: const [
                                          AutofillHints.email
                                        ],
                                        decoration: const InputDecoration(
                                            labelText: 'Adresse e-mail',
                                            prefixIcon:
                                                Icon(Icons.mail_outline)),
                                        validator: (v) => v == null ||
                                                !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                                    .hasMatch(v.trim())
                                            ? 'Saisissez une adresse e-mail valide.'
                                            : null),
                                    const SizedBox(height: 18),
                                    TextFormField(
                                        controller: password,
                                        obscureText: hidden,
                                        autofillHints: const [
                                          AutofillHints.password
                                        ],
                                        decoration: InputDecoration(
                                            labelText: 'Mot de passe',
                                            prefixIcon:
                                                const Icon(Icons.lock_outline),
                                            suffixIcon: IconButton(
                                                tooltip: hidden
                                                    ? 'Afficher le mot de passe'
                                                    : 'Masquer le mot de passe',
                                                onPressed: () => setState(
                                                    () => hidden = !hidden),
                                                icon: Icon(hidden
                                                    ? Icons.visibility_outlined
                                                    : Icons
                                                        .visibility_off_outlined))),
                                        validator: (v) => v == null ||
                                                v.length < 6
                                            ? 'Saisissez au moins 6 caractères.'
                                            : null,
                                        onFieldSubmitted: (_) => submit()),
                                    const SizedBox(height: 22),
                                    FilledButton(
                                        onPressed: submit,
                                        child: Text(register
                                            ? 'Créer mon compte de démonstration'
                                            : 'Se connecter')),
                                    const SizedBox(height: 12),
                                    TextButton(
                                        onPressed: () => setState(
                                            () => register = !register),
                                        child: Text(register
                                            ? 'J’ai déjà un compte — Se connecter'
                                            : widget.driver
                                                ? 'Créer un compte livreur'
                                                : 'Créer un compte client')),
                                    if (!register)
                                      TextButton(
                                          onPressed: () => showDialog<void>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                      title: const Text(
                                                          'Mot de passe oublié'),
                                                      content: const Text(
                                                          'La récupération de mot de passe sera activée avec le service de connexion. Pour la démonstration, utilisez une adresse e-mail valide et un mot de passe fictif d’au moins 6 caractères.'),
                                                      actions: [
                                                        TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    context),
                                                            child: const Text(
                                                                'Fermer'))
                                                      ])),
                                          child: const Text(
                                              'Mot de passe oublié ?'))
                                  ]))))))));
}
