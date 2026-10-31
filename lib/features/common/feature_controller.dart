// NON ASSEMBLÉ : ces contrôleurs ne sont importés par aucun écran existant.
import 'package:flutter/foundation.dart';

import '../../data/api/api_exception.dart';
import '../../data/api/paged.dart';

/// Base des contrôleurs d'écran : un indicateur d'attente, le dernier message
/// d'erreur affichable et l'erreur brute (utile pour réagir à un 409).
class FeatureController extends ChangeNotifier {
  bool _disposed = false;

  /// Vrai pendant qu'une action réseau est en cours.
  bool busy = false;

  /// Message français à afficher, ou null.
  String? error;

  /// Dernière erreur du serveur, pour tester `isConflict`, `isUnavailable`…
  ApiException? failure;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void clearError() {
    error = null;
    failure = null;
    notifyListeners();
  }

  /// Exécute [action] en gérant l'attente et les erreurs. Renvoie null en cas
  /// d'échec ; le message est alors dans [error].
  Future<T?> run<T>(Future<T> Function() action) async {
    busy = true;
    error = null;
    failure = null;
    notifyListeners();
    try {
      return await action();
    } on ApiException catch (e) {
      failure = e;
      error = e.displayMessage;
      return null;
    } catch (_) {
      error = 'Une erreur inattendue est survenue. Réessayez.';
      return null;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}

/// Liste paginée chargée page par page (`{data, meta}` du backend).
class PagedController<T> extends FeatureController {
  PagedController([Future<Paged<T>> Function(int page)? fetch]) : _fetch = fetch;

  final Future<Paged<T>> Function(int page)? _fetch;

  /// Charge une page. Les sous-classes avec filtres la redéfinissent.
  Future<Paged<T>> fetchPage(int page) {
    final fetch = _fetch;
    if (fetch == null) {
      throw StateError('fetchPage doit être redéfinie ou une fonction fournie.');
    }
    return fetch(page);
  }

  final List<T> items = [];
  int _page = 0;
  bool hasMore = true;
  bool loadedOnce = false;

  Future<void> refresh() async {
    final result = await run(() => fetchPage(1));
    if (result == null) return;
    items
      ..clear()
      ..addAll(result.items);
    _page = 1;
    hasMore = result.hasMore;
    loadedOnce = true;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (busy || !hasMore || !loadedOnce) return;
    final result = await run(() => fetchPage(_page + 1));
    if (result == null) return;
    items.addAll(result.items);
    _page += 1;
    hasMore = result.hasMore;
    notifyListeners();
  }
}
