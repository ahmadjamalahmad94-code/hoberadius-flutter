class CommunicationsHome {
  const CommunicationsHome({
    required this.summary,
    required this.templates,
    required this.segments,
    required this.deliveries,
  });

  final CommunicationsSummary summary;
  final List<MessageTemplate> templates;
  final List<AudienceSegment> segments;
  final List<MessageDelivery> deliveries;

  factory CommunicationsHome.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    return CommunicationsHome(
      summary: CommunicationsSummary.fromJson(_map(data['summary'])),
      templates: _list(data['templates'])
          .map((item) => MessageTemplate.fromJson(_map(item)))
          .toList(),
      segments: _list(data['segments'])
          .map((item) => AudienceSegment.fromJson(_map(item)))
          .toList(),
      deliveries: _list(data['deliveries'])
          .map((item) => MessageDelivery.fromJson(_map(item)))
          .toList(),
    );
  }
}

class CommunicationsSummary {
  const CommunicationsSummary({
    required this.templates,
    required this.segments,
    required this.queued,
    required this.sent,
    required this.failed,
  });

  final int templates;
  final int segments;
  final int queued;
  final int sent;
  final int failed;

  factory CommunicationsSummary.fromJson(Map<String, dynamic> json) {
    return CommunicationsSummary(
      templates: _int(json['templates']),
      segments: _int(json['segments']),
      queued: _int(json['queued']),
      sent: _int(json['sent']),
      failed: _int(json['failed']),
    );
  }
}

class MessageTemplatePage {
  const MessageTemplatePage({required this.items, required this.count});

  final List<MessageTemplate> items;
  final int count;

  factory MessageTemplatePage.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    final items = _list(data['items'])
        .map((item) => MessageTemplate.fromJson(_map(item)))
        .toList();
    return MessageTemplatePage(items: items, count: _int(data['count']));
  }
}

class MessageTemplate {
  const MessageTemplate({
    required this.id,
    required this.templateKey,
    required this.title,
    required this.channel,
    required this.subject,
    required this.body,
    required this.status,
    required this.variables,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String templateKey;
  final String title;
  final String channel;
  final String subject;
  final String body;
  final String status;
  final List<String> variables;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory MessageTemplate.fromJson(Map<String, dynamic> json) {
    return MessageTemplate(
      id: _int(json['id']),
      templateKey: _string(json['template_key']),
      title: _string(json['title']),
      channel: _string(json['channel'], fallback: 'internal'),
      subject: _string(json['subject']),
      body: _string(json['body']),
      status: _string(json['status'], fallback: 'active'),
      variables: _strings(json['variables']),
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
    );
  }

  String get channelLabel => communicationChannelLabel(channel);
  String get statusLabel => communicationStatusLabel(status);
}

class AudienceSegmentPage {
  const AudienceSegmentPage({required this.items, required this.count});

  final List<AudienceSegment> items;
  final int count;

  factory AudienceSegmentPage.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    final items = _list(data['items'])
        .map((item) => AudienceSegment.fromJson(_map(item)))
        .toList();
    return AudienceSegmentPage(items: items, count: _int(data['count']));
  }
}

class AudienceSegment {
  const AudienceSegment({
    required this.id,
    required this.segmentKey,
    required this.title,
    required this.status,
    required this.filters,
  });

  final int id;
  final String segmentKey;
  final String title;
  final String status;
  final Map<String, dynamic> filters;

  factory AudienceSegment.fromJson(Map<String, dynamic> json) {
    return AudienceSegment(
      id: _int(json['id']),
      segmentKey: _string(json['segment_key']),
      title: _string(json['title']),
      status: _string(json['status'], fallback: 'active'),
      filters: _map(json['filters']),
    );
  }

  String get targetLabel =>
      communicationTargetLabel(_string(filters['target']));
  String get statusLabel => communicationStatusLabel(status);
}

class AudiencePreview {
  const AudiencePreview({required this.items, required this.count});

  final List<RecipientPreview> items;
  final int count;

  factory AudiencePreview.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    final items = _list(data['items'])
        .map((item) => RecipientPreview.fromJson(_map(item)))
        .toList();
    return AudiencePreview(items: items, count: _int(data['count']));
  }
}

class RecipientPreview {
  const RecipientPreview({
    required this.recipientType,
    required this.recipientId,
    required this.displayName,
    required this.address,
  });

  final String recipientType;
  final int recipientId;
  final String displayName;
  final String address;

  factory RecipientPreview.fromJson(Map<String, dynamic> json) {
    return RecipientPreview(
      recipientType: _string(json['recipient_type']),
      recipientId: _int(json['recipient_id']),
      displayName: _string(json['display_name']),
      address: _string(json['address']),
    );
  }

  String get typeLabel => communicationTargetLabel(recipientType);
}

class MessageDeliveryPage {
  const MessageDeliveryPage({required this.items, required this.count});

  final List<MessageDelivery> items;
  final int count;

  factory MessageDeliveryPage.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    final items = _list(data['items'])
        .map((item) => MessageDelivery.fromJson(_map(item)))
        .toList();
    return MessageDeliveryPage(items: items, count: _int(data['count']));
  }
}

class MessageDelivery {
  const MessageDelivery({
    required this.id,
    required this.channel,
    required this.status,
    required this.providerKey,
    required this.recipientType,
    required this.recipientId,
    required this.subject,
    required this.body,
    required this.errorMessage,
    required this.createdAt,
    required this.sentAt,
  });

  final int id;
  final String channel;
  final String status;
  final String providerKey;
  final String recipientType;
  final int recipientId;
  final String subject;
  final String body;
  final String errorMessage;
  final DateTime? createdAt;
  final DateTime? sentAt;

  factory MessageDelivery.fromJson(Map<String, dynamic> json) {
    return MessageDelivery(
      id: _int(json['id']),
      channel: _string(json['channel'], fallback: 'internal'),
      status: _string(json['status'], fallback: 'queued'),
      providerKey: _string(json['provider_key']),
      recipientType: _string(json['recipient_type']),
      recipientId: _int(json['recipient_id']),
      subject: _string(json['subject']),
      body: _string(json['body']),
      errorMessage: _string(json['error_message']),
      createdAt: _date(json['created_at']),
      sentAt: _date(json['sent_at']),
    );
  }

  String get channelLabel => communicationChannelLabel(channel);
  String get statusLabel => communicationStatusLabel(status);
  String get recipientLabel =>
      '${communicationTargetLabel(recipientType)} #$recipientId';
  String get createdAtLabel => dateTimeLabel(createdAt);
}

class CampaignPage {
  const CampaignPage({required this.items, required this.count});

  final List<MessageCampaign> items;
  final int count;

  factory CampaignPage.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    final items = _list(data['items'])
        .map((item) => MessageCampaign.fromJson(_map(item)))
        .toList();
    return CampaignPage(items: items, count: _int(data['count']));
  }
}

class MessageCampaign {
  const MessageCampaign({
    required this.id,
    required this.campaignKey,
    required this.title,
    required this.channel,
    required this.status,
    required this.templateId,
    required this.dryRun,
  });

  final int id;
  final String campaignKey;
  final String title;
  final String channel;
  final String status;
  final int templateId;
  final Map<String, dynamic> dryRun;

  factory MessageCampaign.fromJson(Map<String, dynamic> json) {
    return MessageCampaign(
      id: _int(json['id']),
      campaignKey: _string(json['campaign_key']),
      title: _string(json['title']),
      channel: _string(json['channel'], fallback: 'internal'),
      status: _string(json['status']),
      templateId: _int(json['template_id']),
      dryRun: _map(json['dry_run']),
    );
  }

  int get recipientCount => _int(dryRun['recipient_count']);
  bool get externalSend => _bool(dryRun['external_send']);
  String get channelLabel => communicationChannelLabel(channel);
  String get statusLabel => communicationStatusLabel(status);
}

class CommunicationChannelPage {
  const CommunicationChannelPage({
    required this.items,
    required this.count,
    required this.modes,
    required this.methods,
  });

  final List<CommunicationChannel> items;
  final int count;
  final List<CommunicationModeOption> modes;
  final List<String> methods;

  factory CommunicationChannelPage.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    final items = _list(data['items'])
        .map((item) => CommunicationChannel.fromJson(_map(item)))
        .toList();
    final modes = _list(data['modes'])
        .map((item) => CommunicationModeOption.fromJson(_map(item)))
        .toList();
    final methods = _strings(data['methods']);
    return CommunicationChannelPage(
      items: items,
      count: _int(data['count']),
      modes: modes,
      methods: methods.isEmpty ? const ['GET', 'POST'] : methods,
    );
  }
}

class CommunicationChannel {
  const CommunicationChannel({
    required this.channel,
    required this.label,
    required this.enabled,
    required this.active,
    required this.mode,
    required this.modeLabel,
    required this.config,
    required this.quota,
  });

  final String channel;
  final String label;
  final bool enabled;
  final bool active;
  final String mode;
  final String modeLabel;
  final CommunicationChannelConfig config;
  final CommunicationChannelQuotaSummary quota;

  factory CommunicationChannel.fromJson(Map<String, dynamic> json) {
    final channel = _string(json['channel']);
    return CommunicationChannel(
      channel: channel,
      label: _string(
        json['label'],
        fallback: communicationChannelLabel(channel),
      ),
      enabled: _bool(json['enabled']),
      active: _bool(json['active']),
      mode: _string(json['mode'], fallback: 'self_api'),
      modeLabel: _string(
        json['mode_label'],
        fallback: communicationModeLabel(_string(json['mode'])),
      ),
      config: CommunicationChannelConfig.fromJson(_map(json['config'])),
      quota: CommunicationChannelQuotaSummary.fromJson(_map(json['quota'])),
    );
  }

  String get statusLabel {
    if (!enabled) return 'متوقفة';
    if (active) return 'جاهزة للإرسال';
    return 'تحتاج ضبط رابط الإرسال';
  }
}

class CommunicationChannelConfig {
  const CommunicationChannelConfig({
    required this.sendUrlTemplate,
    required this.httpMethod,
    required this.balanceUrl,
  });

  final String sendUrlTemplate;
  final String httpMethod;
  final String balanceUrl;

  factory CommunicationChannelConfig.fromJson(Map<String, dynamic> json) {
    return CommunicationChannelConfig(
      sendUrlTemplate: _string(json['send_url_template']),
      httpMethod: _string(json['http_method'], fallback: 'GET').toUpperCase(),
      balanceUrl: _string(json['balance_url']),
    );
  }
}

class CommunicationChannelQuotaSummary {
  const CommunicationChannelQuotaSummary({
    required this.balance,
    required this.used,
    required this.isQuotaMode,
  });

  final int balance;
  final int used;
  final bool isQuotaMode;

  factory CommunicationChannelQuotaSummary.fromJson(Map<String, dynamic> json) {
    return CommunicationChannelQuotaSummary(
      balance: _int(json['balance']),
      used: _int(json['used']),
      isQuotaMode: _bool(json['is_quota_mode']),
    );
  }
}

class CommunicationModeOption {
  const CommunicationModeOption({required this.key, required this.label});

  final String key;
  final String label;

  factory CommunicationModeOption.fromJson(Map<String, dynamic> json) {
    final key = _string(json['key']);
    return CommunicationModeOption(
      key: key,
      label: _string(json['label'], fallback: communicationModeLabel(key)),
    );
  }
}

class CommunicationChannelDraft {
  const CommunicationChannelDraft({
    required this.channel,
    required this.enabled,
    required this.mode,
    required this.sendUrlTemplate,
    required this.httpMethod,
    required this.balanceUrl,
  });

  final String channel;
  final bool enabled;
  final String mode;
  final String sendUrlTemplate;
  final String httpMethod;
  final String balanceUrl;

  Map<String, dynamic> toBody() => {
        'enabled': enabled,
        'mode': mode,
        'send_url_template': sendUrlTemplate,
        'http_method': httpMethod.toUpperCase(),
        'balance_url': balanceUrl,
      };
}

class CommunicationQuotaPage {
  const CommunicationQuotaPage({required this.items, required this.count});

  final List<CommunicationQuotaStatus> items;
  final int count;

  factory CommunicationQuotaPage.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    final items = _list(data['items'])
        .map((item) => CommunicationQuotaStatus.fromJson(_map(item)))
        .toList();
    return CommunicationQuotaPage(items: items, count: _int(data['count']));
  }
}

class CommunicationQuotaStatus {
  const CommunicationQuotaStatus({
    required this.channel,
    required this.label,
    required this.mode,
    required this.modeLabel,
    required this.balance,
    required this.used,
    required this.isQuotaMode,
    required this.ledger,
  });

  final String channel;
  final String label;
  final String mode;
  final String modeLabel;
  final int balance;
  final int used;
  final bool isQuotaMode;
  final List<CommunicationQuotaLedgerEntry> ledger;

  factory CommunicationQuotaStatus.fromJson(Map<String, dynamic> json) {
    final channel = _string(json['channel']);
    final mode = _string(json['mode'], fallback: 'self_api');
    return CommunicationQuotaStatus(
      channel: channel,
      label:
          _string(json['label'], fallback: communicationChannelLabel(channel)),
      mode: mode,
      modeLabel:
          _string(json['mode_label'], fallback: communicationModeLabel(mode)),
      balance: _int(json['balance']),
      used: _int(json['used']),
      isQuotaMode: _bool(json['is_quota_mode']),
      ledger: _list(json['ledger'])
          .map((item) => CommunicationQuotaLedgerEntry.fromJson(_map(item)))
          .toList(),
    );
  }
}

class CommunicationQuotaLedgerEntry {
  const CommunicationQuotaLedgerEntry({
    required this.ts,
    required this.delta,
    required this.by,
    required this.note,
    required this.balanceAfter,
  });

  final DateTime? ts;
  final int delta;
  final String by;
  final String note;
  final int balanceAfter;

  factory CommunicationQuotaLedgerEntry.fromJson(Map<String, dynamic> json) {
    return CommunicationQuotaLedgerEntry(
      ts: _date(json['ts']),
      delta: _int(json['delta']),
      by: _string(json['by']),
      note: _string(json['note']),
      balanceAfter: _int(json['balance_after']),
    );
  }

  String get tsLabel => dateTimeLabel(ts);
}

class CommunicationQuotaCreditResult {
  const CommunicationQuotaCreditResult({
    required this.quota,
    required this.balanceAfter,
    required this.message,
  });

  final CommunicationQuotaStatus quota;
  final int balanceAfter;
  final String message;

  factory CommunicationQuotaCreditResult.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    return CommunicationQuotaCreditResult(
      quota: CommunicationQuotaStatus.fromJson(_map(data['quota'])),
      balanceAfter: _int(data['balance_after']),
      message: _string(data['message']),
    );
  }
}

class WhatsappBridgeState {
  const WhatsappBridgeState({
    required this.status,
    required this.events,
    required this.panelPortalUrl,
    required this.principles,
  });

  final WhatsappBridgeStatus status;
  final List<WhatsappBridgeEvent> events;
  final String panelPortalUrl;
  final List<String> principles;

  factory WhatsappBridgeState.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    return WhatsappBridgeState(
      status: WhatsappBridgeStatus.fromJson(_map(data['status'])),
      events: _list(data['events'])
          .map((item) => WhatsappBridgeEvent.fromJson(_map(item)))
          .toList(),
      panelPortalUrl: _string(data['panel_portal_url']),
      principles: _strings(data['principles']),
    );
  }
}

class WhatsappBridgeStatus {
  const WhatsappBridgeStatus({
    required this.ok,
    required this.status,
    required this.enabled,
    required this.connected,
    required this.onboarding,
    required this.onboardingLabel,
    required this.phone,
    required this.business,
    required this.usage,
  });

  final bool ok;
  final String status;
  final bool enabled;
  final bool connected;
  final String onboarding;
  final String onboardingLabel;
  final String phone;
  final String business;
  final Map<String, dynamic> usage;

  factory WhatsappBridgeStatus.fromJson(Map<String, dynamic> json) {
    final onboarding = _string(json['onboarding'], fallback: 'needs_setup');
    return WhatsappBridgeStatus(
      ok: _bool(json['ok']),
      status: _string(json['status'], fallback: 'unavailable'),
      enabled: _bool(json['enabled']),
      connected: _bool(json['connected']),
      onboarding: onboarding,
      onboardingLabel: _string(
        json['onboarding_label'],
        fallback: whatsappOnboardingLabel(onboarding, _bool(json['ok'])),
      ),
      phone: _string(json['phone']),
      business: _string(json['business']),
      usage: _map(json['usage']),
    );
  }

  String get sentLabel => _usageLabel('sent');
  String get remainingLabel => _usageLabel('remaining');
  String get limitLabel => _usageLabel('limit');

  String _usageLabel(String key) {
    final value = usage[key];
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? 'غير محدد' : text;
  }
}

class WhatsappBridgeEvent {
  const WhatsappBridgeEvent({
    required this.key,
    required this.label,
    required this.help,
    required this.settingKey,
    required this.enabled,
  });

  final String key;
  final String label;
  final String help;
  final String settingKey;
  final bool enabled;

  factory WhatsappBridgeEvent.fromJson(Map<String, dynamic> json) {
    return WhatsappBridgeEvent(
      key: _string(json['key']),
      label: _string(json['label']),
      help: _string(json['help']),
      settingKey: _string(json['setting_key']),
      enabled: _bool(json['enabled']),
    );
  }
}

class WhatsappBridgeSettingsResult {
  const WhatsappBridgeSettingsResult({
    required this.events,
    required this.message,
  });

  final List<WhatsappBridgeEvent> events;
  final String message;

  factory WhatsappBridgeSettingsResult.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    return WhatsappBridgeSettingsResult(
      events: _list(data['events'])
          .map((item) => WhatsappBridgeEvent.fromJson(_map(item)))
          .toList(),
      message: _string(data['message']),
    );
  }
}

String whatsappOnboardingLabel(String value, bool ok) {
  if (!ok) return 'غير متوفّرة';
  return switch (value) {
    'connected' => 'متصل',
    'not_connected' => 'غير متصل',
    'needs_setup' => 'بحاجة إلى الإعداد',
    _ => 'بحاجة إلى الإعداد',
  };
}

String communicationChannelLabel(String value) {
  return switch (value) {
    'internal' => 'رسالة داخلية',
    'sms' => 'رسالة جوال',
    'whatsapp' => 'واتساب',
    'telegram' => 'تيليجرام',
    'email' => 'بريد إلكتروني',
    'push' => 'إشعار فوري',
    _ => 'قناة غير محددة',
  };
}

String communicationModeLabel(String value) {
  return switch (value) {
    'self_api' => 'ربط مباشر من العميل',
    'admin_quota' => 'رصيد مخصص من الإدارة',
    _ => 'غير محدد',
  };
}

String communicationTargetLabel(String value) {
  return switch (value) {
    'subscriber' || 'selected_subscribers' => 'المشتركين',
    'card_user' => 'مستخدمي الكروت',
    'manager' => 'المدراء',
    'distributor' => 'الموزعين',
    'company' => 'الشركة',
    _ => 'جمهور غير محدد',
  };
}

String communicationStatusLabel(String value) {
  return switch (value) {
    'active' => 'مفعّل',
    'disabled' => 'معطّل',
    'queued' => 'في الطابور',
    'sent' => 'تم الإرسال',
    'failed' => 'فشل',
    'dry_run_ready' => 'معاينة جاهزة',
    'read' => 'مقروء',
    _ => value.trim().isEmpty ? 'غير محدد' : value,
  };
}

String dateTimeLabel(DateTime? date) {
  if (date == null) return 'غير محدد';
  String two(int value) => value.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)} '
      '${two(date.hour)}:${two(date.minute)}';
}

String generatedKey(String title, String prefix) {
  final base = title
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  final suffix = DateTime.now().millisecondsSinceEpoch.toString();
  return '${prefix}_${base.isEmpty ? suffix : '$base-$suffix'}';
}

Map<String, dynamic> _data(Map<String, dynamic> json) {
  final data = json['data'];
  return data is Map<String, dynamic>
      ? data
      : _map(data).isEmpty
          ? json
          : _map(data);
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

List<Object?> _list(Object? value) {
  if (value is List) return value;
  return const [];
}

List<String> _strings(Object? value) {
  if (value is List) {
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  final text = _string(value);
  return text.isEmpty ? const [] : [text];
}

String _string(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _bool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().trim().toLowerCase();
  return text == 'true' || text == '1' || text == 'yes' || text == 'on';
}

DateTime? _date(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text.replaceFirst('Z', ''));
}
