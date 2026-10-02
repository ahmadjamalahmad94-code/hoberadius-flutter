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

  /// Arabic name shown to the user. The raw key (`system.name`) is an
  /// implementation detail and is never displayed: a missing/raw label falls
  /// back to «إعداد <القسم>» derived from the key prefix.
  String get displayLabel {
    final l = label.trim();
    if (l.isNotEmpty && l != key && !_rawKeyLike.hasMatch(l)) return l;
    return settingFallbackLabel(key);
  }

  factory SettingItem.fromJson(Map<String, dynamic> json) {
    return SettingItem(
      key: _string(json['key']),
      label: _string(json['label']),
      value: _string(json['value']),
      defaultValue: _string(json['default']),
    );
  }
}

final RegExp _rawKeyLike = RegExp(r'^[A-Za-z0-9_]+(\.[A-Za-z0-9_]+)+$');

const Map<String, String> _settingSectionsAr = {
  'system': 'النظام',
  'branding': 'الهويّة',
  'billing': 'الفوترة',
  'portal': 'البوّابة',
  'device_limit': 'حدّ الأجهزة',
  'security': 'الأمان',
  'cards': 'البطاقات',
  'radius': 'الراديوس',
  'comms': 'الاتصالات',
  'subscribers': 'المشتركين',
  'auth': 'الدخول',
  'quota': 'الحصّة',
  'network': 'الشبكة',
  'infra': 'البنية التحتيّة',
  'limits': 'الحدود',
};

/// Arabic fallback for a setting with no usable label — never the raw key.
String settingFallbackLabel(String key) {
  final dot = key.indexOf('.');
  final prefix = dot <= 0 ? key : key.substring(0, dot);
  final section = _settingSectionsAr[prefix];
  return section == null ? 'إعداد إضافيّ' : 'إعداد $section';
}

class SettingsSnapshot {
  const SettingsSnapshot({
    required this.items,
    required this.settings,
    this.systemCurrency = '',
    this.currencySymbol = '',
    this.currencyName = '',
  });

  final List<SettingItem> items;
  final Map<String, String> settings;

  /// `system.currency` — the EFFECTIVE tenant currency (updated servers);
  /// empty on older servers (then `billing.currency` is used).
  final String systemCurrency;
  final String currencySymbol;
  final String currencyName;

  factory SettingsSnapshot.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    final system = _map(json['system']);
    return SettingsSnapshot(
      systemCurrency: _string(system['currency']).trim().toUpperCase(),
      currencySymbol: _string(system['currency_symbol']),
      currencyName: _string(system['currency_name']),
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
