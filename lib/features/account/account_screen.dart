// NON ASSEMBLÉ. Écran « Mon compte » : nom, e-mail, code destinataire, état.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../common/ui.dart';
import 'account_controller.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, required this.controller, this.onLogout});
  final AccountController controller;
  final VoidCallback? onLogout;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String? _state;

  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  @override
  Widget build(BuildContext context) => FeatureScaffold(
        title: 'Mon compte',
        body: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final c = widget.controller;
            final user = c.user;
            if (user == null) {
              return c.error != null
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: ErrorBanner(message: c.error!, onRetry: c.load))
                  : const Center(child: CircularProgressIndicator());
            }
            return ListView(padding: const EdgeInsets.all(16), children: [
              if (c.error != null) ErrorBanner(message: c.error!),
              Panel(
                  child: Column(children: [
                LabeledLine('Nom', user.name),
                LabeledLine('Adresse e-mail', user.email),
                LabeledLine('Rôle', user.isDriver ? 'Livreur' : 'Client'),
              ])),
              const SizedBox(height: 14),
              Panel(
                  child:
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Heading('Votre code destinataire'),
                const Text(
                    'Pour recevoir un colis, donnez ce code à l’expéditeur. Il en a besoin pour vous désigner comme destinataire.',
                    style: TextStyle(fontSize: 12, color: fMuted)),
                const SizedBox(height: 10),
                SelectableText(user.id,
                    style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        color: fNavy)),
                const SizedBox(height: 10),
                ActionButton(
                    label: 'Copier le code',
                    outline: true,
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: user.id));
                      if (context.mounted) showMessage(context, 'Code copié.');
                    }),
              ])),
              const SizedBox(height: 14),
              Panel(
                  child:
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Heading('Votre état américain'),
                const Text(
                    'Utilisé pour le tirage au sort mensuel.',
                    style: TextStyle(fontSize: 12, color: fMuted)),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _state ?? user.state,
                  isExpanded: true,
                  decoration: const InputDecoration(
                      labelText: 'État', isDense: true),
                  items: [
                    for (final code in usStates)
                      DropdownMenuItem(value: code, child: Text(code)),
                  ],
                  onChanged: (v) => setState(() => _state = v),
                ),
                const SizedBox(height: 10),
                ActionButton(
                    label: 'Enregistrer',
                    busy: c.busy,
                    onPressed: _state == null
                        ? null
                        : () async {
                            final ok = await c.saveState(_state!);
                            if (ok && context.mounted) {
                              showMessage(context, 'État enregistré.');
                            }
                          }),
              ])),
              if (widget.onLogout != null) ...[
                const SizedBox(height: 14),
                ActionButton(
                    label: 'Se déconnecter',
                    outline: true,
                    onPressed: widget.onLogout),
              ],
            ]);
          },
        ),
      );
}
