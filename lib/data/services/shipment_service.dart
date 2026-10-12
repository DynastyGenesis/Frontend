import '../models/shipment.dart';

class ShipmentService {
  Future<List<Shipment>> getShipments() async => const [
    Shipment(id: 'BGO-248519', destination: 'Lomé → New York', service: 'Express', date: '04 oct. 2026', status: ShipmentStatus.transit, progress: .62),
    Shipment(id: 'BGO-247821', destination: 'New York → Lomé', service: 'Standard', date: '28 sept. 2026', status: ShipmentStatus.delivered, progress: 1),
    Shipment(id: 'BGO-247114', destination: 'Lomé → Atlanta', service: 'Standard', date: '21 sept. 2026', status: ShipmentStatus.preparing, progress: .18),
  ];
}
