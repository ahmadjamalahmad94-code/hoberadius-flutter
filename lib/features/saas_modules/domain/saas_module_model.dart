class SaasRecord {
  const SaasRecord(this.values);

  final Map<String, dynamic> values;

  factory SaasRecord.fromJson(Map<String, dynamic> json) {
    return SaasRecord(
      json.map((key, value) => MapEntry(key.toString(), value)),
    );
  }

  int get id => _asInt(values['id']);

  String text(String key) {
    final value = values[key];
    if (value == null || value.toString().isEmpty) return 'غير محدد';
    if (value is bool) return value ? 'نعم' : 'لا';
    return value.toString();
  }
}

class SaasModuleSnapshot {
  const SaasModuleSnapshot({
    required this.items,
    required this.count,
    this.stats = const {},
  });

  final List<SaasRecord> items;
  final int count;
  final Map<String, dynamic> stats;

  factory SaasModuleSnapshot.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final rawStats = json['stats'];
    return SaasModuleSnapshot(
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map(
                (item) => SaasRecord.fromJson(
                  item.map((key, value) => MapEntry(key.toString(), value)),
                ),
              )
              .toList()
          : const [],
      count: _asInt(json['count']),
      stats: rawStats is Map
          ? rawStats.map((key, value) => MapEntry(key.toString(), value))
          : const {},
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString()) ?? 0;
}
