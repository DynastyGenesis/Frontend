import 'dart:typed_data';

enum MissionStage { available, accepted, collected, transit, delivered }

class DriverMission {
  final String id,
      product,
      image,
      client,
      phone,
      pickup,
      destination,
      zone,
      slot;
  final double fee, weight;
  MissionStage stage;
  String? incident, recipient;
  Uint8List? proof;
  DateTime? completedAt;
  DriverMission(
      {required this.id,
      required this.product,
      required this.image,
      required this.client,
      required this.phone,
      required this.pickup,
      required this.destination,
      required this.zone,
      required this.slot,
      required this.fee,
      required this.weight,
      this.stage = MissionStage.available});
  String get status => [
        'Disponible',
        'Acceptée',
        'Colis collecté',
        'En livraison',
        'Livrée'
      ][stage.index];
  bool get active =>
      stage != MissionStage.available && stage != MissionStage.delivered;
  bool advance() {
    if (stage == MissionStage.delivered || stage == MissionStage.transit) {
      return false;
    }
    stage = MissionStage.values[stage.index + 1];
    return true;
  }

  bool complete(String name, bool confirmed, {Uint8List? photo}) {
    if (stage != MissionStage.transit || name.trim().isEmpty || !confirmed) {
      return false;
    }
    recipient = name.trim();
    proof = photo;
    completedAt = DateTime.now();
    stage = MissionStage.delivered;
    return true;
  }
}

class DriverSession {
  String name = 'Jean Koffi',
      phone = '+228 90 12 34 56',
      vehicle = 'Moto · TG 4582',
      zone = 'Togo';
  bool available = true;
  final missions = <DriverMission>[
    DriverMission(
        id: 'LIV-2026-0048',
        product: 'Chaussures Nike Air Force 1',
        image: 'shoes',
        client: 'Koffi Mensah',
        phone: '+228 90 12 34 56',
        pickup: 'Agence Ships4US, Tokoin, Lomé',
        destination: 'Bè, Lomé, Togo',
        zone: 'Togo',
        slot: 'Aujourd’hui · 14:00 – 16:00',
        fee: 8,
        weight: 1.2),
    DriverMission(
        id: 'LIV-2026-0049',
        product: 'iPhone 15 Pro',
        image: 'phone',
        client: 'Ama Lawson',
        phone: '+228 91 23 45 67',
        pickup: 'Agence Ships4US, Tokoin, Lomé',
        destination: 'Agoè, Lomé, Togo',
        zone: 'Togo',
        slot: 'Aujourd’hui · 15:00 – 17:00',
        fee: 12,
        weight: .5),
    DriverMission(
        id: 'LIV-2026-0050',
        product: 'MacBook Air',
        image: 'laptop',
        client: 'Akouvi Dossou',
        phone: '+228 92 34 56 78',
        pickup: 'Agence Ships4US, Tokoin, Lomé',
        destination: 'Adidogomé, Lomé, Togo',
        zone: 'Togo',
        slot: 'Demain · 09:00 – 11:00',
        fee: 10,
        weight: 1.8),
    DriverMission(
        id: 'LIV-2026-0047',
        product: 'Sac à main',
        image: 'bag',
        client: 'Abla Sika',
        phone: '+228 93 45 67 89',
        pickup: 'Agence Ships4US, Tokoin, Lomé',
        destination: 'Hédzranawoé, Lomé, Togo',
        zone: 'Togo',
        slot: 'Aujourd’hui · 13:00 – 15:00',
        fee: 7,
        weight: .8,
        stage: MissionStage.accepted),
    DriverMission(
        id: 'COL-2026-0012',
        product: 'Baskets Nike',
        image: 'shoes',
        client: 'David Mensah',
        phone: '+1 212 555 0142',
        pickup: 'Point de collecte, Manhattan, New York',
        destination: 'Entrepôt Ships4US, Queens, New York',
        zone: 'États-Unis',
        slot: 'Demain · 10:00 – 12:00',
        fee: 18,
        weight: 1),
    DriverMission(
        id: 'LIV-2026-0044',
        product: 'Baskets Nike',
        image: 'shoes',
        client: 'Yao Agbo',
        phone: '+228 94 56 78 90',
        pickup: 'Agence Ships4US, Tokoin, Lomé',
        destination: 'Centre-ville, Lomé, Togo',
        zone: 'Togo',
        slot: '07 oct. 2026 · 10:30',
        fee: 6,
        weight: 1,
        stage: MissionStage.delivered),
    DriverMission(
        id: 'LIV-2026-0043',
        product: 'Sac à main',
        image: 'bag',
        client: 'Adjo Kossi',
        phone: '+228 95 67 89 01',
        pickup: 'Agence Ships4US, Tokoin, Lomé',
        destination: 'Nyékonakpoè, Lomé, Togo',
        zone: 'Togo',
        slot: '07 oct. 2026 · 09:00',
        fee: 7,
        weight: .8,
        stage: MissionStage.delivered),
  ];
  final notifications = <String>[
    'Trois missions disponibles à Lomé.',
    'Mission LIV-2026-0047 : collecte à préparer.',
    'Votre relevé de démonstration est disponible.'
  ];
  final read = <int>{};
  List<DriverMission> get local =>
      missions.where((m) => m.zone == zone).toList();
  double get earnings => missions
      .where((m) => m.stage == MissionStage.delivered)
      .fold(0, (sum, m) => sum + m.fee);
}
