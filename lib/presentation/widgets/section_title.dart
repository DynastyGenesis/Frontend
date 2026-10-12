import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionTitle({super.key, required this.title, this.action, this.onAction});
  @override Widget build(BuildContext context) => Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink))), if (action != null) TextButton(onPressed: onAction, child: Text(action!))]);
}
