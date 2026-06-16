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

class ApiTokenRecord {
  const ApiTokenRecord({
    required this.id,
    required this.name,
    required this.scopes,
    required this.revoked,
    required this.lastUsedAt,
    required this.expiresAt,
    required this.createdAt,
    this.token,
    this.tokenShownOnce = false,
  });

  final int id;
  final String name;
  final List<String> scopes;
  final bool revoked;
  final String lastUsedAt;
  final String expiresAt;
  final String createdAt;
  final String? token;
  final bool tokenShownOnce;

  factory ApiTokenRecord.fromJson(Map<String, dynamic> json) {
    final scopes = json['scopes'];
    return ApiTokenRecord(
      id: _int(json['id']),
      name: _string(json['name']),
      scopes: scopes is List ? scopes.map((e) => _string(e)).toList() : const [],
      revoked: _bool(json['revoked']),
      lastUsedAt: _string(json['last_used_at']),
      expiresAt: _string(json['expires_at']),
      createdAt: _string(json['created_at']),
      token: json.containsKey('token') ? _string(json['token']) : null,
      tokenShownOnce: _bool(json['token_shown_once']),
    );
  }
}

class TenantRecord {
  const TenantRecord({
    required this.id,
    required this.slug,
    required this.name,
    required this.displayName,
    required this.email,
    required this.phone,
    required this.currency,
    required this.locale,
    required this.timezone,
    required this.status,
    required this.planTier,
    required this.maxSubscribers,
    required this.maxNas,
    required this.apiRpm,
    this.primaryColor = '',
    this.logoUrl = '',
  });

  final int id;
  final String slug;
  final String name;
  final String displayName;
  final String email;
  final String phone;
  final String currency;
  final String locale;
  final String timezone;
  final String status;
  final String planTier;
  final int maxSubscribers;
  final int maxNas;
  final int apiRpm;
  final String primaryColor;
  final String logoUrl;

  factory TenantRecord.fromJson(Map<String, dynamic> json) {
    return TenantRecord(
      id: _int(json['id']),
      slug: _string(json['slug']),
      name: _string(json['name']),
      displayName: _string(json['display_name']),
      email: _string(json['email']),
      phone: _string(json['phone']),
      currency: _string(json['currency']),
      locale: _string(json['locale']),
      timezone: _string(json['timezone']),
      status: _string(json['status']),
      planTier: _string(json['plan_tier']),
      maxSubscribers: _int(json['max_subscribers']),
      maxNas: _int(json['max_nas']),
      apiRpm: _int(json['api_rpm']),
      primaryColor: _string(json['primary_color']),
      logoUrl: _string(json['logo_url']),
    );
  }

  Map<String, dynamic> toBody({bool includeSlug = false}) {
    return {
      if (includeSlug) 'slug': slug,
      'name': name,
      'display_name': displayName,
      'email': email,
      'phone': phone,
      'currency': currency,
      'locale': locale,
      'timezone': timezone,
      'status': status,
      'plan_tier': planTier,
      'max_subscribers': maxSubscribers,
      'max_nas': maxNas,
      'api_rpm': apiRpm,
      if (primaryColor.isNotEmpty) 'primary_color': primaryColor,
      if (logoUrl.isNotEmpty) 'logo_url': logoUrl,
    };
  }
}

class WebhookConfig {
  const WebhookConfig({
    required this.targetUrl,
    required this.enabledEvents,
    required this.secretSet,
  });

  final String targetUrl;
  final List<String> enabledEvents;
  final bool secretSet;

  factory WebhookConfig.fromJson(Map<String, dynamic> json) {
    final events = json['enabled_events'];
    return WebhookConfig(
      targetUrl: _string(json['target_url']),
      enabledEvents:
          events is List ? events.map((item) => _string(item)).toList() : const [],
      secretSet: _bool(json['secret_set']),
    );
  }
}

class WebhookDelivery {
  const WebhookDelivery({
    required this.id,
    required this.event,
    required this.eventId,
    required this.status,
    required this.attempts,
    required this.lastStatusCode,
    required this.lastResponseExcerpt,
    required this.nextAttemptAt,
    required this.createdAt,
  });

  final int id;
  final String event;
  final String eventId;
  final String status;
  final int attempts;
  final int lastStatusCode;
  final String lastResponseExcerpt;
  final String nextAttemptAt;
  final String createdAt;

  factory WebhookDelivery.fromJson(Map<String, dynamic> json) {
    return WebhookDelivery(
      id: _int(json['id']),
      event: _string(json['event']),
      eventId: _string(json['event_id']),
      status: _string(json['status']),
      attempts: _int(json['attempts']),
      lastStatusCode: _int(json['last_status_code']),
      lastResponseExcerpt: _string(json['last_response_excerpt']),
      nextAttemptAt: _string(json['next_attempt_at']),
      createdAt: _string(json['created_at']),
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

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(_string(value)) ?? 0;
}

bool _bool(Object? value) {
  if (value is bool) return value;
  return {'1', 'true', 'yes', 'on'}.contains(_string(value).trim().toLowerCase());
}

String _string(Object? value) => (value ?? '').toString();
