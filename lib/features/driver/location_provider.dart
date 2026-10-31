// NON ASSEMBLÉ. Port vers la position GPS de l'appareil.
//
// Le backend détecte l'arrivée du livreur à moins de 150 m du lieu de collecte
// à partir des positions envoyées, et refuse une position de plus de 2 minutes
// pour l'itinéraire. À l'assemblage : implémenter ce port avec le package
// `geolocator` (non ajouté au projet) et déclarer les permissions de
// localisation Android (ACCESS_FINE_LOCATION) et iOS (NSLocationWhenInUseUsageDescription).

class GeoPoint {
  const GeoPoint(this.lat, this.lng);
  final double lat;
  final double lng;
}

abstract class LocationProvider {
  /// Position actuelle, ou null si la localisation est refusée ou coupée.
  Future<GeoPoint?> current();
}

/// Utilisé tant que le GPS n'est pas branché.
class NoLocationProvider implements LocationProvider {
  const NoLocationProvider();

  @override
  Future<GeoPoint?> current() async => null;
}
