import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_endpoint_storage.dart';
import 'package:hoberadius_app/core/api/api_exception.dart';
import 'package:hoberadius_app/features/subscriber_portal/data/subscriber_portal_repository.dart';

class _MemoryEndpointStorage implements ApiEndpointStorage {
  _MemoryEndpointStorage(this.baseUrl);

  String baseUrl;

  @override
  Future<String> readBaseUrl() async => baseUrl;

  @override
  Future<void> writeBaseUrl(String baseUrl) async => this.baseUrl = baseUrl;
}

class _RecordedRequest {
  const _RecordedRequest({
    required this.path,
    required this.headers,
    required this.body,
  });

  final String path;
  final Map<String, dynamic> headers;
  final Map<String, dynamic> body;
}

class _PortalAdapter implements HttpClientAdapter {
  _PortalAdapter(this.handler);

  final FutureOr<ResponseBody> Function(RequestOptions, Map<String, dynamic>)
      handler;
  final requests = <_RecordedRequest>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final rawBody = requestStream == null
        ? ''
        : await utf8.decoder.bind(requestStream).join();
    final body = rawBody.trim().isEmpty
        ? <String, dynamic>{}
        : (jsonDecode(rawBody) as Map).map(
            (key, value) => MapEntry(key.toString(), value),
          );
    requests.add(
      _RecordedRequest(
        path: options.path,
        headers: Map<String, dynamic>.from(options.headers),
        body: body,
      ),
    );
    return handler(options, body);
  }
}

ResponseBody _json(Map<String, dynamic> body, int status) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  test('login uses public subscriber portal API without admin token', () async {
    final storage = _MemoryEndpointStorage('http://old.local');
    late _PortalAdapter adapter;
    adapter = _PortalAdapter((options, body) {
      expect(options.path, '/api/v1/subscriber-portal/login');
      expect(body['username'], 'subscriber-1');
      expect(body['password'], 'secret');
      return _json(
        {
          'ok': true,
          'token': 'subscriber-token',
          'expires_in': 900,
          'subscriber': {
            'id': 1,
            'username': 'subscriber-1',
            'full_name': 'Subscriber One',
            'status': 'active',
          },
          'capabilities': {
            'dashboard': true,
            'requests': true,
            'loan_request': true,
            'renewal_request': true,
            'support_request': true,
          },
        },
        200,
      );
    });
    final dio = Dio(BaseOptions(validateStatus: (status) => true));
    dio.httpClientAdapter = adapter;

    final repo = SubscriberPortalRepository(storage, dio: dio);
    final result = await repo.login(
      baseUrl: 'https://hoberadius.com',
      username: 'subscriber-1',
      password: 'secret',
      tenantId: 4,
    );

    expect(storage.baseUrl, 'https://hoberadius.com');
    expect(result.token, 'subscriber-token');
    expect(result.capabilities.requests, isTrue);
    expect(adapter.requests.single.headers['X-Tenant-Id'], '4');
    expect(adapter.requests.single.headers, isNot(contains('Authorization')));
  });

  test('dashboard, requests, and loan use subscriber bearer token', () async {
    final storage = _MemoryEndpointStorage('https://hoberadius.com');
    final adapter = _PortalAdapter((options, body) {
      if (options.path.endsWith('/dashboard')) {
        return _json(
          {
            'ok': true,
            'dashboard': {
              'subscriber': {
                'id': 1,
                'username': 'subscriber-1',
                'full_name': 'Subscriber One',
                'status': 'active',
              },
              'plan': {'id': 2, 'name': '25 Mbps'},
              'subscription': {'status': 'active'},
              'usage': {},
              'wallet': {'balance': '0', 'currency': 'ILS'},
              'debt': 0,
              'loan_policy': {'enabled': true, 'allowed_minutes': 60},
              'sessions': [],
              'loans': [],
              'payments': [],
              'notifications': [],
              'cards': [],
              'walled_garden_note': '',
            },
          },
          200,
        );
      }
      if (options.path.endsWith('/requests')) {
        return _json(
          {
            'ok': true,
            'items': [
              {
                'id': 7,
                'request_type': 'renewal',
                'status': 'pending',
                'reason': 'renew',
              },
            ],
          },
          200,
        );
      }
      return _json(
        {
          'ok': true,
          'request': {
            'id': 8,
            'request_type': 'loan',
            'status': 'requires_approval',
            'reason': body['reason'],
            'result': {},
          },
        },
        201,
      );
    });
    final dio = Dio(BaseOptions(validateStatus: (status) => true));
    dio.httpClientAdapter = adapter;

    final repo = SubscriberPortalRepository(storage, dio: dio);
    final dashboard = await repo.dashboard(
      token: 'subscriber-token',
      tenantId: 4,
    );
    final requests = await repo.requests(
      token: 'subscriber-token',
      tenantId: 4,
    );
    final loan = await repo.loanRequest(
      token: 'subscriber-token',
      tenantId: 4,
      requestedMinutes: 60,
      reason: 'need time',
    );

    expect(dashboard.subscriber.username, 'subscriber-1');
    expect(requests.single.id, 7);
    expect(loan.id, 8);
    expect(adapter.requests, hasLength(3));
    for (final request in adapter.requests) {
      expect(request.headers['Authorization'], 'Bearer subscriber-token');
      expect(request.headers['X-Tenant-Id'], '4');
    }
  });

  test('flat portal errors are translated away from raw codes', () async {
    final storage = _MemoryEndpointStorage('https://hoberadius.com');
    final adapter = _PortalAdapter((options, body) {
      return _json(
        {
          'ok': false,
          'error': 'token_expired',
          'message': 'token_expired',
        },
        401,
      );
    });
    final dio = Dio(BaseOptions(validateStatus: (status) => true));
    dio.httpClientAdapter = adapter;

    final repo = SubscriberPortalRepository(storage, dio: dio);

    try {
      await repo.me(token: 'old-token');
      fail('me should fail');
    } on ApiException catch (error) {
      expect(error.code, 'token_expired');
      expect(error.message, isNot(contains('token_expired')));
    }
  });
}
