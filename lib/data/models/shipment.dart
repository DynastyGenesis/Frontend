enum ShipmentStatus { delivered, transit, preparing }

class Shipment {
  final String id;
  final String destination;
  final String service;
  final String date;
  final ShipmentStatus status;
  final double progress;

  const Shipment({required this.id, required this.destination, required this.service, required this.date, required this.status, required this.progress});

  String get statusLabel => switch (status) {
    ShipmentStatus.delivered => 'Livré',
    ShipmentStatus.transit => 'En transit',
    ShipmentStatus.preparing => 'Préparation',
  };
}
