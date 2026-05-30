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
    final raw = rawText(key);
    if (raw == 'غير محدد') return raw;
    return _valueLabel(key, raw);
  }

  String rawText(String key) {
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

String _valueLabel(String key, String raw) {
  if (key == 'status') {
    return switch (raw) {
      'active' => 'مفعّلة',
      'inactive' => 'غير مفعّلة',
      'enabled' => 'مفعّلة',
      'disabled' => 'معطّلة',
      'paid' => 'مدفوعة',
      'unpaid' => 'غير مدفوعة',
      'draft' => 'مسودة',
      'cancelled' => 'ملغاة',
      'void' => 'ملغاة',
      'revoked' => 'ملغاة',
      'used' => 'مستخدمة',
      'available' => 'متاحة',
      'given' => 'مسلمة للعميل',
      'returned' => 'مسترجعة',
      'lost' => 'مفقودة',
      'maintenance' => 'صيانة',
      'open' => 'مفتوحة',
      'pending' => 'بانتظار متابعة',
      'closed' => 'مغلقة',
      _ => raw,
    };
  }
  if (key == 'enabled') {
    return switch (raw) {
      '1' || 'true' || 'نعم' => 'مفعّلة',
      '0' || 'false' || 'لا' => 'معطّلة',
      _ => raw,
    };
  }
  return raw;
}
