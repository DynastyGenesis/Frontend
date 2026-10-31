// Mes destinataires : liste, ajout, suppression et sélecteur pour la réservation.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/local/contacts_store.dart';
import '../common/ui.dart';
import 'recipients_controller.dart';

class RecipientsScreen extends StatefulWidget {
  const RecipientsScreen({super.key, required this.controller});
  final RecipientsController controller;

  @override
  State<RecipientsScreen> createState() => _RecipientsScreenState();
}

class _RecipientsScreenState extends State<RecipientsScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  @override
  Widget build(BuildContext context) => FeatureScaffold(
        title: 'Mes destinataires',
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: fBlue,
          foregroundColor: Colors.white,
          onPressed: () => showAddRecipientSheet(context, widget.controller),
          icon: const Icon(Icons.person_add_alt),
          label: const Text('Ajouter'),
        ),
        body: ListenableBuilder(
          listenable: widget.controller,
          builder: (context, _) {
            final c = widget.controller;
            return ListView(padding: const EdgeInsets.all(16), children: [
              const Panel(
                  color: Color(0xFFEFF5FF),
                  child: Text(
                    'Le destinataire doit avoir un compte BarelGo et vous '
                    'transmettre son code (écran Mon compte). Ce carnet est '
                    'gardé sur cet appareil et n’est partagé avec personne.',
                    style: TextStyle(fontSize: 12, color: fNavy),
                  )),
              const SizedBox(height: 12),
              if (c.error != null) ErrorBanner(message: c.error!),
              if (c.loadedOnce && c.contacts.isEmpty)
                const EmptyState(
                    text: 'Aucun destinataire enregistré.',
                    icon: Icons.people_outline),
              for (final contact in c.contacts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Panel(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.person_outline, color: fBlue),
                      title: Text(contact.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, color: fNavy)),
                      subtitle: Text(contact.code,
                          style: const TextStyle(fontSize: 11)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                          tooltip: 'Copier le code',
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: contact.code));
                            showMessage(context, 'Code copié.');
                          },
                        ),
                        IconButton(
                          tooltip: 'Supprimer',
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () async {
                            if (await confirm(
                                context,
                                'Supprimer ce destinataire ?',
                                '${contact.name} sera retiré de votre carnet.',
                                yes: 'Supprimer')) {
                              await c.remove(contact);
                            }
                          },
                        ),
                      ]),
                    ),
                  ),
                ),
              const SizedBox(height: 72),
            ]);
          },
        ),
      );
}

/// Feuille d'ajout d'un destinataire. Renvoie vrai s'il est enregistré.
Future<bool> showAddRecipientSheet(
    BuildContext context, RecipientsController controller) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: _AddRecipientForm(controller: controller),
    ),
  );
  return result == true;
}

class _AddRecipientForm extends StatefulWidget {
  const _AddRecipientForm({required this.controller});
  final RecipientsController controller;

  @override
  State<_AddRecipientForm> createState() => _AddRecipientFormState();
}

class _AddRecipientFormState extends State<_AddRecipientForm> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _code = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Heading('Nouveau destinataire'),
            if (c.error != null) ErrorBanner(message: c.error!),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(),
                  isDense: true),
              validator: c.validateName,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _code,
              decoration: const InputDecoration(
                  labelText: 'Code du destinataire',
                  helperText: 'À lire dans Mon compte, chez le destinataire.',
                  border: OutlineInputBorder(),
                  isDense: true),
              validator: c.validateCode,
            ),
            const SizedBox(height: 12),
            ActionButton(
              label: 'Enregistrer',
              busy: c.busy,
              onPressed: () async {
                if (!_form.currentState!.validate()) return;
                final ok = await c.add(name: _name.text, code: _code.text);
                if (ok && context.mounted) Navigator.pop(context, true);
              },
            ),
          ]),
        ),
      ),
    );
  }
}

/// Liste de choix pour la réservation. Renvoie le destinataire retenu, ou null.
Future<RecipientContact?> pickRecipient(
    BuildContext context, RecipientsController controller) async {
  await controller.load();
  if (!context.mounted) return null;
  return showModalBottomSheet<RecipientContact>(
    context: context,
    builder: (ctx) => SafeArea(
      child: ListView(shrinkWrap: true, padding: const EdgeInsets.all(16), children: [
        const Heading('Choisir un destinataire'),
        if (controller.contacts.isEmpty)
          const EmptyState(
              text: 'Votre carnet est vide. Ajoutez un destinataire depuis le '
                  'menu « Mes destinataires ».',
              icon: Icons.people_outline),
        for (final contact in controller.contacts)
          ListTile(
            leading: const Icon(Icons.person_outline, color: fBlue),
            title: Text(contact.name),
            subtitle: Text(contact.code, style: const TextStyle(fontSize: 11)),
            onTap: () => Navigator.pop(ctx, contact),
          ),
      ]),
    ),
  );
}
