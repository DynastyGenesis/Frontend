// NON ASSEMBLÉ. Disponibilité du livreur et envoi de sa position (POST /livreur/location).
//
// Le backend considère une position périmée après 2 minutes : pendant une
// mission, l'envoi doit se faire toutes les 30 secondes environ.
import 'dart:async';

import '../../data/services/backend_api.dart';
import '../common/feature_controller.dart';
import 'location_provider.dart';

class AvailabilityController extends FeatureController {
  AvailabilityController(
    this._api,
    this._location, {
    this.interval = const Duration(seconds: 30),
    this.available = true,
  });

  final BackendApi _api;
  final LocationProvider _location;
  final Duration interval;
  bool available;
  DateTime? lastSentAt;
  Timer? _timer;

  bool get tracking => _timer != null;

  /// Envoie la position actuelle avec l'état de disponibilité.
  Future<bool> sendNow() async {
    final point = await _location.current();
    if (point == null) {
      error = 'Position indisponible. Activez la localisation de l’appareil.';
      notifyListeners();
      return false;
    }
    final ok = await run(() async {
      await _api.sendLocation(
          lat: point.lat, lng: point.lng, available: available);
      return true;
    });
    if (ok == true) {
      lastSentAt = DateTime.now();
      notifyListeners();
    }
    return ok == true;
  }

  Future<bool> setAvailable(bool value) async {
    final previous = available;
    available = value;
    notifyListeners();
    final ok = await sendNow();
    if (!ok) {
      available = previous;
      notifyListeners();
    }
    return ok;
  }

  /// Envoie la position régulièrement tant que l'écran des missions est ouvert.
  void startTracking() {
    _timer?.cancel();
    sendNow();
    _timer = Timer.periodic(interval, (_) {
      if (!busy) sendNow();
    });
    notifyListeners();
  }

  /// [notify] à false quand l'écran se ferme : plus personne n'écoute.
  void stopTracking({bool notify = true}) {
    _timer?.cancel();
    _timer = null;
    if (notify) notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
