/// Telegram admin-alerts models — the Flutter mirror of the web
/// `alerts/telegram` page contract (`/api/v1/alerts/telegram`).
///
/// The bot token is a secret: the API never returns it raw — only [hasToken]
/// + a masked tail. Saving is PATCH-style (blank token keeps the stored one).
class TelegramBot {
  const TelegramBot({
    required this.hasToken,
    required this.tokenMasked,
    required this.chatId,
    required this.threadId,
    required this.enabled,
    required this.ready,
  });

  final bool hasToken;
  final String tokenMasked;
  final String chatId;
  final String threadId;
  final bool enabled;

  /// Server-computed: bot is configured + enabled and can actually send.
  final bool ready;

  factory TelegramBot.fromJson(Map<String, dynamic> j) {
    return TelegramBot(
      hasToken: j['has_token'] == true,
      tokenMasked: _str(j['token_masked']),
      chatId: _str(j['chat_id']),
      threadId: _str(j['thread_id']),
      enabled: j['enabled'] == true,
      ready: j['ready'] == true,
    );
  }

  static const empty = TelegramBot(
    hasToken: false,
    tokenMasked: '',
    chatId: '',
    threadId: '',
    enabled: false,
    ready: false,
  );
}

/// A display group of alerts (e.g. subscribers, network, finance).
class AlertGroup {
  const AlertGroup({required this.key, required this.label, required this.icon});

  final String key;
  final String label;
  final String icon;

  factory AlertGroup.fromJson(Map<String, dynamic> j) => AlertGroup(
        key: _str(j['key']),
        label: _str(j['label']),
        icon: _str(j['icon']),
      );
}

/// A single alert spec: per-tenant enable state + the rendered preview text.
class AlertItem {
  const AlertItem({
    required this.key,
    required this.group,
    required this.groupLabel,
    required this.label,
    required this.description,
    required this.enabled,
    required this.template,
    required this.preview,
  });

  final String key;
  final String group;
  final String groupLabel;
  final String label;
  final String description;
  final bool enabled;
  final String template;
  final String preview;

  AlertItem copyWith({bool? enabled}) => AlertItem(
        key: key,
        group: group,
        groupLabel: groupLabel,
        label: label,
        description: description,
        enabled: enabled ?? this.enabled,
        template: template,
        preview: preview,
      );

  factory AlertItem.fromJson(Map<String, dynamic> j) => AlertItem(
        key: _str(j['key']),
        group: _str(j['group']),
        groupLabel: _str(j['group_label']),
        label: _str(j['label']),
        description: _str(j['description']),
        enabled: j['enabled'] == true,
        template: _str(j['template']),
        preview: _str(j['preview']),
      );
}

/// Full `/alerts/telegram` snapshot: bot + groups + the alert catalogue.
class TelegramAlertsSnapshot {
  const TelegramAlertsSnapshot({
    required this.bot,
    required this.groups,
    required this.catalogue,
  });

  final TelegramBot bot;
  final List<AlertGroup> groups;
  final List<AlertItem> catalogue;

  factory TelegramAlertsSnapshot.fromJson(Map<String, dynamic> j) {
    return TelegramAlertsSnapshot(
      bot: j['bot'] is Map
          ? TelegramBot.fromJson(_map(j['bot']))
          : TelegramBot.empty,
      groups: _list(j['groups']).map(AlertGroup.fromJson).toList(),
      catalogue: _list(j['catalogue']).map(AlertItem.fromJson).toList(),
    );
  }
}

String _str(Object? v) => v?.toString() ?? '';

Map<String, dynamic> _map(Object? v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val));
  return const {};
}

List<Map<String, dynamic>> _list(Object? v) {
  if (v is! List) return const [];
  return v.whereType<Map>().map(_map).toList();
}
