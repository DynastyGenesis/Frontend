// Position GPS de l'appareil avec le package `geolocator`.
//
// Permissions déclarées : ACCESS_FINE_LOCATION / ACCESS_COARSE_LOCATION
// (Android) et NSLocationWhenInUseUsageDescription (iOS). Seule la position
// « pendant l'utilisation » est demandée : l'envoi s'arrête quand
// l'application passe en arrière-plan. Fourni par `AppServices`.
import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'location_provider.dart';

class GeolocatorLocationProvider implements LocationProvider {
  const GeolocatorLocationProvider({
    this.timeLimit = const Duration(seconds: 15),
  });

  final Duration timeLimit;

  @override
  Future<GeoPoint?> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        return null;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeLimit,
        ),
      );
      return GeoPoint(position.latitude, position.longitude);
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Ouvre les réglages quand la permission a été refusée définitivement.
  Future<bool> openSettings() => Geolocator.openAppSettings();
}
