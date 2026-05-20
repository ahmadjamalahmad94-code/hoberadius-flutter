class OperationalReportSnapshot {
  const OperationalReportSnapshot({
    required this.slug,
    required this.items,
    required this.count,
    required this.query,
    required this.limit,
    required this.offset,
  });

  final String slug;
  final List<Map<String, dynamic>> items;
  final int count;
  final String query;
  final int limit;
  final int offset;

  factory OperationalReportSnapshot.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return OperationalReportSnapshot(
      slug: (json['slug'] ?? '').toString(),
      count: _asInt(json['count']),
      query: (json['query'] ?? '').toString(),
      limit: _asInt(json['limit']),
      offset: _asInt(json['offset']),
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map(
                (item) => item.map(
                  (key, value) => MapEntry(key.toString(), value),
                ),
              )
              .toList()
          : const [],
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString()) ?? 0;
}
