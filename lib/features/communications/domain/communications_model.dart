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
