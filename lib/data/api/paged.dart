/// Métadonnées de pagination du backend (`meta`).
class PageMeta {
  const PageMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory PageMeta.fromJson(Map<String, dynamic>? json) {
    final data = json ?? const <String, dynamic>{};
    int read(String key, int fallback) {
      final value = data[key];
      return value is num ? value.toInt() : fallback;
    }

    return PageMeta(
      currentPage: read('current_page', 1),
      lastPage: read('last_page', 1),
      perPage: read('per_page', 25),
      total: read('total', 0),
    );
  }

  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
}

/// Une page de résultats `{data, meta}`.
class Paged<T> {
  const Paged(this.items, this.meta);

  /// Construit une page à partir de la réponse JSON brute.
  factory Paged.fromJson(
    dynamic json,
    T Function(Map<String, dynamic>) parse,
  ) {
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};
    final raw = map['data'];
    final items = <T>[];
    if (raw is List) {
      for (final element in raw) {
        if (element is Map<String, dynamic>) items.add(parse(element));
      }
    }
    final meta = map['meta'];
    return Paged<T>(
      items,
      PageMeta.fromJson(meta is Map<String, dynamic> ? meta : null),
    );
  }

  final List<T> items;
  final PageMeta meta;

  bool get hasMore => meta.currentPage < meta.lastPage;
}
