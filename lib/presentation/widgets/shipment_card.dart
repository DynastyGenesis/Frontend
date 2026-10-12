import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/shipment.dart';

class ShipmentCard extends StatelessWidget {
  final Shipment shipment; final VoidCallback? onTap;
  const ShipmentCard({super.key, required this.shipment, this.onTap});
  @override Widget build(BuildContext context) {
    final color = shipment.status == ShipmentStatus.delivered ? AppColors.green : AppColors.blue;
    return Card(margin: const EdgeInsets.only(bottom: 12), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: AppColors.border)), child: InkWell(borderRadius: BorderRadius.circular(18), onTap: onTap, child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(12)), child: Icon(Icons.inventory_2_outlined, color: color)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(shipment.id, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(shipment.destination, style: const TextStyle(color: AppColors.muted))])), Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6), decoration: BoxDecoration(color: color.withAlpha(18), borderRadius: BorderRadius.circular(20)), child: Text(shipment.statusLabel, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)))]),
      const SizedBox(height: 14), LinearProgressIndicator(value: shipment.progress, minHeight: 6, borderRadius: BorderRadius.circular(8), color: color, backgroundColor: AppColors.border), const SizedBox(height: 10), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(shipment.service, style: const TextStyle(color: AppColors.muted)), Text(shipment.date, style: const TextStyle(color: AppColors.muted, fontSize: 12))])
    ]))));
  }
}
