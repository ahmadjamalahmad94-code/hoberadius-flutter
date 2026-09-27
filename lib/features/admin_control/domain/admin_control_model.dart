class SettingItem {
  const SettingItem({
    required this.key,
    required this.label,
    required this.value,
    required this.defaultValue,
  });

  final String key;
  final String label;
  final String value;
  final String defaultValue;

  factory SettingItem.fromJson(Map<String, dynamic> json) {
    return SettingItem(
      key: _string(json['key']),
      label: _string(json['label']),
      value: _string(json['value']),
      defaultValue: _string(json['default']),
    );
  }
}

class SettingsSnapshot {
  const SettingsSnapshot({required this.items, required this.settings});

  final List<SettingItem> items;
  final Map<String, String> settings;

  factory SettingsSnapshot.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return SettingsSnapshot(
      items: raw is List
          ? raw
              .whereType<Map>()
              .map((item) => SettingItem.fromJson(_map(item)))
              .toList()
          : const [],
      settings: _stringMap(json['settings']),
    );
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, val) => MapEntry('$key', val));
  return const {};
}

Map<String, String> _stringMap(Object? value) {
  final source = _map(value);
  return {for (final entry in source.entries) entry.key: _string(entry.value)};
}

String _string(Object? value) => (value ?? '').toString();
