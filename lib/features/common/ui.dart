// NON ASSEMBLÉ. Éléments d'interface communs aux écrans de lib/features.
// Mêmes couleurs que l'espace client existant (bleu, marine, gris).
import 'package:flutter/material.dart';

const fBlue = Color(0xFF005BF3);
const fNavy = Color(0xFF08264C);
const fMuted = Color(0xFF73849B);
const fGreen = Color(0xFF1AA879);
const fOrange = Color(0xFFEA9B35);
const fRed = Color(0xFFD64545);
const fBorder = Color(0xFFEAF0F7);

/// 12,50 $
String usd(num value) => '${value.toStringAsFixed(2).replaceAll('.', ',')} \$';

String _two(int n) => n.toString().padLeft(2, '0');

/// 28/10/2026 14:00 (heure de l'appareil)
String formatDateTime(DateTime? value) {
  if (value == null) return '—';
  final d = value.toLocal();
  return '${_two(d.day)}/${_two(d.month)}/${d.year} ${_two(d.hour)}:${_two(d.minute)}';
}

String formatDate(DateTime? value) {
  if (value == null) return '—';
  final d = value.toLocal();
  return '${_two(d.day)}/${_two(d.month)}/${d.year}';
}

/// 14:00 – 16:00
String formatWindow(DateTime? start, DateTime? end) {
  if (start == null || end == null) return '—';
  final s = start.toLocal(), e = end.toLocal();
  return '${formatDate(s)} · ${_two(s.hour)}:${_two(s.minute)} – ${_two(e.hour)}:${_two(e.minute)}';
}

class FeatureScaffold extends StatelessWidget {
  const FeatureScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF4F8FD),
        appBar: AppBar(
          title: Text(title, style: const TextStyle(fontSize: 17)),
          backgroundColor: fNavy,
          foregroundColor: Colors.white,
          actions: actions,
        ),
        floatingActionButton: floatingActionButton,
        body: SafeArea(child: body),
      );
}

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.color = Colors.white});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: fBorder),
        ),
        // Les ListTile et InkWell posés dans le panneau peindent sur ce Material,
        // sinon la couleur de fond les masque.
        child: Material(type: MaterialType.transparency, child: child),
      );
}

class Heading extends StatelessWidget {
  const Heading(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: fNavy)),
      );
}

class LabeledLine extends StatelessWidget {
  const LabeledLine(this.label, this.value, {super.key});
  final String label, value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 12, color: fMuted))),
          const SizedBox(width: 12),
          Flexible(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: fNavy))),
        ]),
      );
}

class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.color = fBlue});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      );
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: fRed.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: fRed.withValues(alpha: .3)),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline, color: fRed, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: const TextStyle(fontSize: 12, color: fNavy))),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Réessayer')),
        ]),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.text, this.icon = Icons.inbox});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 42, color: fMuted),
          const SizedBox(height: 12),
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: fMuted)),
        ]),
      );
}

/// Bouton plein ou contour, désactivé et avec indicateur pendant l'attente.
class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.outline = false,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final bool outline;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final child = busy
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2))
        : Text(label, textAlign: TextAlign.center);
    final action = busy ? null : onPressed;
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: outline
          ? OutlinedButton(
              onPressed: action,
              style: OutlinedButton.styleFrom(foregroundColor: color ?? fBlue),
              child: child)
          : FilledButton(
              onPressed: action,
              style: FilledButton.styleFrom(backgroundColor: color ?? fBlue),
              child: child),
    );
  }
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// Dialogue de confirmation. Renvoie vrai si l'utilisateur confirme.
Future<bool> confirm(BuildContext context, String title, String message,
    {String yes = 'Confirmer'}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true), child: Text(yes)),
      ],
    ),
  );
  return result == true;
}
