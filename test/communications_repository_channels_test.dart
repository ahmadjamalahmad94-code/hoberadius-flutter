import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/api/api_endpoint_storage.dart';
import 'package:hoberadius_app/core/auth/token_storage.dart';
import 'package:hoberadius_app/features/communications/data/communications_repository.dart';
import 'package:hoberadius_app/features/communications/domain/communications_model.dart';

class _MemoryTokenStorage implements TokenStorage {
  String? token = 'token';

  @override
  Future<void> clear() async => token = null;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String token) async => this.token = token;
}

class _MemoryEndpointStorage implements ApiEndpointStorage {
  String baseUrl = 'http://127.0.0.1:5000';

  @override
  Future<String> readBaseUrl() async => baseUrl;

  @override
  Future<void> writeBaseUrl(String baseUrl) async => this.baseUrl = baseUrl;
}

class _CaptureAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final data = switch ('${options.method} ${options.path}') {
      'GET /api/v1/communications/channels' => {
          'items': [_channelPayload()],
          'count': 1,
          'modes': [
            {'key': 'self_api', 'label': 'ربط مباشر من العميل'},
          ],
          'methods': ['GET', 'POST'],
        },
      'POST /api/v1/communications/channels/whatsapp' => {
          'channel': _channelPayload(
            enabled: true,
            active: true,
          ),
          'saved_config': {'ok': true},
        },
      'GET /api/v1/whatsapp' => {
          'status': {
            'ok': true,
            'status': 'success',
            'enabled': true,
            'connected': true,
            'onboarding': 'connected',
            'onboarding_label': 'متصل',
            'phone': '+970599000000',
            'business': 'Hobe Radius',
            'usage': {'sent': 7, 'remaining': 93},
          },
          'events': [
            {
              'key': 'otp',
              'label': 'رمز التحقق عند الدخول',
              'help': 'إرسال رمز تحقق للمشترك.',
              'setting_key': 'whatsapp.send.otp',
              'enabled': false,
            },
          ],
          'panel_portal_url': 'https://hoberadius.com/portal/whatsapp',
          'principles': ['الإرسال الرسمي يتم عبر لوحة التراخيص فقط.'],
        },
      'PATCH /api/v1/whatsapp/settings' => {
          'events': [
            {
              'key': 'otp',
              'label': 'رمز التحقق عند الدخول',
              'help': 'إرسال رمز تحقق للمشترك.',
              'setting_key': 'whatsapp.send.otp',
              'enabled': true,
            },
          ],
          'message': 'تم حفظ إعدادات رسائل واتساب للمشتركين.',
        },
      'POST /api/v1/whatsapp/test' => {
          'message': 'تم إرسال رسالة الاختبار عبر لوحة التراخيص.',
        },
      'POST /api/v1/whatsapp/cloud-test' => {
          'message': 'تم إرسال رسالة الاختبار عبر بيانات اللوحة.',
        },
      _ => <String, dynamic>{},
    };
    return ResponseBody.fromString(
      jsonEncode({'ok': true, 'data': data}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  Map<String, dynamic> _channelPayload({
    bool enabled = false,
    bool active = false,
    String mode = 'self_api',
  }) {
    return {
      'channel': 'sms',
      'label': 'الرسائل القصيرة',
      'enabled': enabled,
      'active': active,
      'mode': mode,
      'mode_label': 'ربط مباشر من العميل',
      'config': {
        'send_url_template':
            'https://provider.example/send?to={phone}&text={msg}',
        'http_method': 'POST',
        'balance_url': 'https://provider.example/balance',
      },
    };
  }
}

void main() {
  test('CommunicationsRepository uses channel and whatsapp API contracts',
      () async {
    final client = ApiClient(_MemoryTokenStorage(), _MemoryEndpointStorage());
    final adapter = _CaptureAdapter();
    client.dio.httpClientAdapter = adapter;
    final repo = CommunicationsRepository(client);

    final channels = await repo.channels();
    final saved = await repo.saveChannel(
      // SMS goes via TweetSMS (owner 2026-10-06) — only WhatsApp keeps an
      // HTTP config, saved without «mode» / «balance_url».
      const CommunicationChannelDraft(
        channel: 'whatsapp',
        enabled: true,
        sendUrlTemplate: 'https://provider.example/send?to={phone}&text={msg}',
        httpMethod: 'POST',
      ),
    );
    final whatsapp = await repo.whatsappBridge();
    final whatsappSaved = await repo.saveWhatsappToggles({'otp': true});
    final whatsappTest = await repo.sendWhatsappTest('+970599000000');
    final whatsappCloudTest = await repo.sendWhatsappCloudTest(
      recipientPhone: '+970599000000',
      templateName: 'hello_world',
      language: 'ar',
    );

    expect(channels.items.single.label, 'الرسائل القصيرة');
    expect(saved.active, isTrue);
    expect(whatsapp.status.connected, isTrue);
    expect(whatsappSaved.events.single.enabled, isTrue);
    expect(whatsappTest, contains('لوحة التراخيص'));
    expect(whatsappCloudTest, contains('بيانات اللوحة'));
    expect(
      adapter.requests.map((request) => '${request.method} ${request.path}'),
      [
        'GET /api/v1/communications/channels',
        'POST /api/v1/communications/channels/whatsapp',
        'GET /api/v1/whatsapp',
        'PATCH /api/v1/whatsapp/settings',
        'POST /api/v1/whatsapp/test',
        'POST /api/v1/whatsapp/cloud-test',
      ],
    );
    expect(adapter.requests[1].data, {
      'enabled': true,
      'send_url_template':
          'https://provider.example/send?to={phone}&text={msg}',
      'http_method': 'POST',
    });
    expect(adapter.requests[3].data, {
      'toggles': {'otp': true},
    });
    expect(adapter.requests[4].data, {
      'recipient_phone': '+970599000000',
    });
    expect(adapter.requests[5].data, {
      'recipient_phone': '+970599000000',
      'template_name': 'hello_world',
      'language': 'ar',
    });
  });
}
