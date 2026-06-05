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
            {'key': 'admin_quota', 'label': 'رصيد مخصص من الإدارة'},
          ],
          'methods': ['GET', 'POST'],
        },
      'POST /api/v1/communications/channels/sms' => {
          'channel': _channelPayload(
            enabled: true,
            active: true,
            mode: 'admin_quota',
          ),
          'saved_config': {'ok': true},
        },
      'GET /api/v1/communications/quota' => {
          'items': [_quotaPayload()],
          'count': 1,
        },
      'POST /api/v1/communications/quota/sms/credit' => {
          'quota': _quotaPayload(balance: 250),
          'balance_after': 250,
          'message': 'تمت إضافة 100 رسالة إلى رصيد الرسائل القصيرة.',
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
      'mode_label': mode == 'admin_quota'
          ? 'رصيد مخصص من الإدارة'
          : 'ربط مباشر من العميل',
      'config': {
        'send_url_template':
            'https://provider.example/send?to={phone}&text={msg}',
        'http_method': 'POST',
        'balance_url': 'https://provider.example/balance',
      },
      'quota': {
        'balance': 150,
        'used': 12,
        'is_quota_mode': mode == 'admin_quota',
      },
    };
  }

  Map<String, dynamic> _quotaPayload({int balance = 150}) {
    return {
      'channel': 'sms',
      'label': 'الرسائل القصيرة',
      'mode': 'admin_quota',
      'mode_label': 'رصيد مخصص من الإدارة',
      'balance': balance,
      'used': 12,
      'is_quota_mode': true,
      'ledger': [],
    };
  }
}

void main() {
  test('CommunicationsRepository uses channel and quota API contracts',
      () async {
    final client = ApiClient(_MemoryTokenStorage(), _MemoryEndpointStorage());
    final adapter = _CaptureAdapter();
    client.dio.httpClientAdapter = adapter;
    final repo = CommunicationsRepository(client);

    final channels = await repo.channels();
    final saved = await repo.saveChannel(
      const CommunicationChannelDraft(
        channel: 'sms',
        enabled: true,
        mode: 'admin_quota',
        sendUrlTemplate: 'https://provider.example/send?to={phone}&text={msg}',
        httpMethod: 'POST',
        balanceUrl: 'https://provider.example/balance',
      ),
    );
    final quota = await repo.quota();
    final credit = await repo.creditQuota(
      channel: 'sms',
      amount: 100,
      note: 'دفعة شهرية',
    );

    expect(channels.items.single.label, 'الرسائل القصيرة');
    expect(saved.active, isTrue);
    expect(quota.items.single.balance, 150);
    expect(credit.balanceAfter, 250);
    expect(
      adapter.requests.map((request) => '${request.method} ${request.path}'),
      [
        'GET /api/v1/communications/channels',
        'POST /api/v1/communications/channels/sms',
        'GET /api/v1/communications/quota',
        'POST /api/v1/communications/quota/sms/credit',
      ],
    );
    expect(adapter.requests[1].data, {
      'enabled': true,
      'mode': 'admin_quota',
      'send_url_template':
          'https://provider.example/send?to={phone}&text={msg}',
      'http_method': 'POST',
      'balance_url': 'https://provider.example/balance',
    });
    expect(adapter.requests[3].data, {
      'amount': 100,
      'note': 'دفعة شهرية',
    });
  });
}
