import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/shipment.dart';
import '../../../data/services/shipment_service.dart';
import '../../widgets/shipment_card.dart';

class ShipmentsPage extends StatelessWidget { const ShipmentsPage({super.key}); @override Widget build(BuildContext context)=>SafeArea(child:ListView(padding:const EdgeInsets.fromLTRB(20,16,20,28),children:[const Text('Mes envois',style:TextStyle(fontSize:26,fontWeight:FontWeight.w900,color:AppColors.ink)),const SizedBox(height:8),const Text('Retrouvez toutes vos expéditions.',style:TextStyle(color:AppColors.muted)),const SizedBox(height:22),FutureBuilder<List<Shipment>>(future:ShipmentService().getShipments(),builder:(context,snap){if(!snap.hasData)return const Center(child:CircularProgressIndicator());return Column(children:snap.data!.map((s)=>ShipmentCard(shipment:s)).toList());})])); }
