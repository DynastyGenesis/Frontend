import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
          child: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Mon profil',
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: AppColors.ink)),
        const SizedBox(height: 20),
        Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border)),
            child: const Row(children: [
              CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.brandPink,
                  child: Text('M',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700))),
              SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Marcel Langheu',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('Client barrelGo',
                    style: TextStyle(color: AppColors.muted))
              ])
            ])),
        const SizedBox(height: 18),
        const _Item(
            icon: Icons.person_outline, title: 'Informations personnelles'),
        const _Item(icon: Icons.notifications_none, title: 'Notifications'),
        const _Item(icon: Icons.language, title: 'Langue'),
        const _Item(icon: Icons.help_outline, title: 'Aide et support'),
        const _Item(
            icon: Icons.description_outlined, title: 'Conditions générales'),
        const _Item(icon: Icons.logout, title: 'Se déconnecter', danger: true)
      ]));
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool danger;
  const _Item({required this.icon, required this.title, this.danger = false});
  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          tileColor: Colors.white,
          leading:
              Icon(icon, color: danger ? Colors.red : AppColors.brandPinkDark),
          title: Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: danger ? Colors.red : AppColors.ink)),
          trailing: const Icon(Icons.chevron_right, color: AppColors.muted)));
}
