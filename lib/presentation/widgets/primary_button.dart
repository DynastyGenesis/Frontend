import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  const PrimaryButton(
      {super.key, required this.label, this.onPressed, this.icon});
  @override
  Widget build(BuildContext context) => SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandPink,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
          onPressed: onPressed,
          icon: Icon(icon ?? Icons.arrow_forward_rounded),
          label: Text(label,
              style: const TextStyle(fontWeight: FontWeight.w700))));
}
