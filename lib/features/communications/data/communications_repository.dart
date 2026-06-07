import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/communications_model.dart';

class CommunicationsRepository {
  CommunicationsRepository(this._api);

  final ApiClient _api;

  Future<CommunicationsHome> summary() async {
    final res = await _api.get('/api/v1/communications/summary');
    return CommunicationsHome.fromJson(res);
  }

  Future<MessageTemplatePage> templates() async {
    final res = await _api.get('/api/v1/communications/templates');
    return MessageTemplatePage.fromJson(res);
  }

  Future<MessageTemplate> createTemplate({
    required String title,
    required String channel,
    required String subject,
    required String body,
  }) async {
    final res = await _api.post(
      '/api/v1/communications/templates',
      body: {
        'template_key': generatedKey(title, 'template'),
        'title': title,
        'channel': channel,
        'subject': subject,
        'body': body,
      },
    );
    return MessageTemplate.fromJson(_nested(res, 'template'));
  }

  Future<AudienceSegmentPage> segments() async {
    final res = await _api.get('/api/v1/communications/audience');
    return AudienceSegmentPage.fromJson(res);
  }

  Future<AudiencePreview> previewAudience(Map<String, dynamic> audience) async {
    final res = await _api.post(
      '/api/v1/communications/audience/preview',
      body: audience,
    );
    return AudiencePreview.fromJson(res);
  }

  Future<AudiencePreview> createSegment({
    required String title,
    required Map<String, dynamic> audience,
  }) async {
    final res = await _api.post(
      '/api/v1/communications/audience',
      body: {
        'segment_key': generatedKey(title, 'segment'),
        'title': title,
        ...audience,
      },
    );
    final data = _data(res);
    final items = data['preview'];
    return AudiencePreview.fromJson({
      'data': {'items': items, 'count': items is List ? items.length : 0},
    });
  }

  Future<int> sendManual({
    required String channel,
    required String subject,
    required String message,
    required Map<String, dynamic> audience,
  }) async {
    final res = await _api.post(
      '/api/v1/communications/send',
      body: {
        'channel': channel,
        'subject': subject,
        'message': message,
        ...audience,
      },
    );
    return _int(_data(res)['queued_count']);
  }

  Future<MessageDeliveryPage> deliveries() async {
    final res = await _api.get('/api/v1/communications/deliveries');
    return MessageDeliveryPage.fromJson(res);
  }

  Future<CommunicationChannelPage> channels() async {
    final res = await _api.get('/api/v1/communications/channels');
    return CommunicationChannelPage.fromJson(res);
  }

  Future<CommunicationChannel> saveChannel(
    CommunicationChannelDraft draft,
  ) async {
    final res = await _api.post(
      '/api/v1/communications/channels/${draft.channel}',
      body: draft.toBody(),
    );
    return CommunicationChannel.fromJson(_nested(res, 'channel'));
  }

  Future<CommunicationQuotaPage> quota() async {
    final res = await _api.get('/api/v1/communications/quota');
    return CommunicationQuotaPage.fromJson(res);
  }

  Future<CommunicationQuotaCreditResult> creditQuota({
    required String channel,
    required int amount,
    String note = '',
  }) async {
    final res = await _api.post(
      '/api/v1/communications/quota/$channel/credit',
      body: {'amount': amount, 'note': note},
    );
    return CommunicationQuotaCreditResult.fromJson(res);
  }

  Future<WhatsappBridgeState> whatsappBridge() async {
    final res = await _api.get('/api/v1/whatsapp');
    return WhatsappBridgeState.fromJson(res);
  }

  Future<WhatsappBridgeSettingsResult> saveWhatsappToggles(
    Map<String, bool> toggles,
  ) async {
    final res = await _api.patch(
      '/api/v1/whatsapp/settings',
      body: {'toggles': toggles},
    );
    return WhatsappBridgeSettingsResult.fromJson(res);
  }

  Future<String> sendWhatsappTest(String recipientPhone) async {
    final res = await _api.post(
      '/api/v1/whatsapp/test',
      body: {'recipient_phone': recipientPhone},
    );
    return _string(_data(res)['message']);
  }

  Future<String> sendWhatsappCloudTest({
    required String recipientPhone,
    String templateName = '',
    String language = '',
  }) async {
    final res = await _api.post(
      '/api/v1/whatsapp/cloud-test',
      body: {
        'recipient_phone': recipientPhone,
        'template_name': templateName,
        'language': language,
      },
    );
    return _string(_data(res)['message']);
  }

  Future<CampaignPage> campaigns() async {
    final res = await _api.get('/api/v1/communications/campaigns');
    return CampaignPage.fromJson(res);
  }

  Future<MessageCampaign> dryRunCampaign({
    required String title,
    required int templateId,
    required Map<String, dynamic> audience,
    required List<String> actions,
  }) async {
    final res = await _api.post(
      '/api/v1/communications/campaigns',
      body: {
        'campaign_key': generatedKey(title, 'campaign'),
        'title': title,
        'template_id': templateId,
        'actions': actions,
        ...audience,
      },
    );
    return MessageCampaign.fromJson(_nested(res, 'campaign'));
  }
}

final communicationsRepositoryProvider =
    Provider<CommunicationsRepository>((ref) {
  return CommunicationsRepository(ref.watch(apiClientProvider));
});

Map<String, dynamic> _nested(Map<String, dynamic> json, String key) {
  return _map(_data(json)[key]);
}

Map<String, dynamic> _data(Map<String, dynamic> json) {
  final data = json['data'];
  return data is Map<String, dynamic> ? data : _map(data);
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _string(Object? value) => value?.toString().trim() ?? '';
