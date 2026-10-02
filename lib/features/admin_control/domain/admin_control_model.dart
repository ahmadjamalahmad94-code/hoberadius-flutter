import '../../../core/format/currency.dart';

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

/// Settings the web edits with a select/toggle — the app offers the same
/// choices instead of free text (parity-b: «نعم» saved for a toggle was read
/// as OFF, «شيكل» was stored as the currency). Null = free text.
const _boolChoices = <(String, String)>[('1', 'مفعّل'), ('0', 'معطّل')];

const Set<String> kBoolSettingKeys = {
  'auth.allow_password_reset',
  'cards.login_without_password_default',
  'security.block_random_mac_cards',
  'security.block_random_mac_subscribers',
  'portal.show_usage',
  'portal.show_sessions',
  'portal.show_invoices',
  'portal.allow_password_change',
  'portal.allow_renewal_request',
  'portal.allow_loan_request',
  'portal.show_support',
  'portal.allow_self_purchase',
  'portal.allow_plan_change',
};


List<(String, String)>? settingChoices(String key) {
  if (kBoolSettingKeys.contains(key) ||
      (key.startsWith('limits.') && key.endsWith('.unlimited'))) {
    return _boolChoices;
  }
  switch (key) {
    case 'billing.currency':
      return [for (final c in kSettingsCurrencyCodes) (c, c)];
    case 'subscribers.create_without_expiry':
      return const [('expired', 'منتهٍ فورًا'), ('unlimited', 'بلا انتهاء')];
    case 'security.unauthorized_ui':
      return const [('freeze', 'تجميد (يظهر معطّلًا)'), ('hide', 'إخفاء')];
    case 'device_limit.subscribers.mode':
    case 'device_limit.cards.mode':
      return const [
        ('reject', 'رفض الجهاز الجديد'),
        ('replace', 'استبدال الأقدم'),
      ];
    case 'billing.timezone_offset':
      return const [
        ('2', '2'),
        ('3', '3'),
        ('3.5', '3.5'),
        ('4', '4'),
        ('0', '0'),
      ];
  }
  return null;
}
