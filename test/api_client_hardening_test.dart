import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/api/api_endpoint_storage.dart';
import 'package:hoberadius_app/core/api/api_exception.dart';
import 'package:hoberadius_app/core/auth/security_key_storage.dart';
import 'package:hoberadius_app/core/auth/token_storage.dart';

class _MemoryTokenStorage implements TokenStorage {
  _MemoryTokenStorage([this.token]);
  String? token;

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

class _MemorySecurityKeyStorage implements SecurityKeyStorage {
  _MemorySecurityKeyStorage([this.key]);
  String? key;

  @override
  Future<void> clear() async => key = null;

  @override
  Future<String?> read() async => key;

  @override
  Future<void> write(String key) async => this.key = key;
}

class _Step {
  const _Step({this.status = 200, this.body, this.throwTimeout = false});
  final int status;
  final Object? body;
  final bool throwTimeout;
}

/// Adapter that replays a programmed sequence of steps (the last step repeats),
/// recording every request so header/attempt assertions are possible.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.steps);
  final List<_Step> steps;
  final requests = <RequestOptions>[];
  int index = 0;

  int get calls => requests.length;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final step = steps[min(index, steps.length - 1)];
    index += 1;
    if (step.throwTimeout) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.receiveTimeout,
      );
    }
    return ResponseBody.fromString(
      jsonEncode(step.body ?? {'ok': true, 'data': {'path': options.path}}),
      step.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

ApiClient _client(
  _ScriptedAdapter adapter, {
  String? token = 'token',
  String? securityKey = 'sec-key',
}) {
  final client = ApiClient(
    _MemoryTokenStorage(token),
    _MemoryEndpointStorage(),
    securityKeyStorage: _MemorySecurityKeyStorage(securityKey),
    config: const ApiClientConfig(
      maxRetries: 2,
      baseBackoff: Duration(milliseconds: 1),
      maxBackoff: Duration(milliseconds: 2),
      maxConcurrentRequests: 4,
    ),
  );
  client.dio.httpClientAdapter = adapter;
  return client;
}

void main() {
  test('every request carries the bearer token and X-API-Key security key',
      () async {
    final adapter = _ScriptedAdapter([const _Step()]);
    final client = _client(adapter);

    await client.get('/api/v1/dashboard');

    final req = adapter.requests.single;
    expect(req.headers['Authorization'], 'Bearer token');
    expect(req.headers['X-API-Key'], 'sec-key');
  });

  test('login request sends X-API-Key but not the bearer token', () async {
    final adapter = _ScriptedAdapter([
      const _Step(
        body: {
          'ok': true,
          'data': {'token': 'new-token'},
        },
      ),
    ]);
    final client = _client(adapter);

    await client.post('/api/admin/login', body: {'username': 'a'});

    final req = adapter.requests.single;
    expect(req.headers.containsKey('Authorization'), isFalse);
    expect(req.headers['X-API-Key'], 'sec-key');
  });

  test('no security key configured → X-API-Key header is omitted', () async {
    final adapter = _ScriptedAdapter([const _Step()]);
    final client = _client(adapter, securityKey: null);

    await client.get('/api/v1/dashboard');

    expect(adapter.requests.single.headers.containsKey('X-API-Key'), isFalse);
  });

  test('receive timeout fails fast after bounded retries, never hangs',
      () async {
    final adapter = _ScriptedAdapter([const _Step(throwTimeout: true)]);
    final client = _client(adapter);

    await expectLater(
      client.get('/api/v1/dashboard'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('الخادم تأخر في الرد'),
        ),
      ),
    );
    // maxRetries=2 → at most 3 attempts, then surfaces an error.
    expect(adapter.calls, 3);
  });

  test('retries a 503 with backoff then succeeds', () async {
    final adapter = _ScriptedAdapter([
      const _Step(
        status: 503,
        body: {
          'ok': false,
          'error': {'code': 'x'},
        },
      ),
      const _Step(),
    ]);
    final client = _client(adapter);

    final res = await client.get('/api/v1/dashboard');
    expect(res['ok'], isTrue);
    expect(adapter.calls, 2);
  });

  test('non-idempotent POST is not retried on 503', () async {
    final adapter = _ScriptedAdapter([
      const _Step(
        status: 503,
        body: {
          'ok': false,
          'error': {'code': 'server_unavailable', 'message': 'down'},
        },
      ),
      const _Step(),
    ]);
    final client = _client(adapter);

    await expectLater(
      client.post('/api/v1/payments'),
      throwsA(isA<ApiException>()),
    );
    expect(adapter.calls, 1);
  });

  test('429 is retried honouring the body retry hint, then succeeds', () async {
    final adapter = _ScriptedAdapter([
      const _Step(
        status: 429,
        body: {
          'ok': false,
          'error': {
            'code': 'rate_limited',
            'message': 'تجاوزت الحد',
            'details': {'retry_after_seconds': 0},
          },
        },
      ),
      const _Step(),
    ]);
    final client = _client(adapter);

    final res = await client.get('/api/v1/sessions/online');
    expect(res['ok'], isTrue);
    expect(adapter.calls, 2);
  });

  test('persistent 429 surfaces a clear Arabic rate-limit error', () async {
    final adapter = _ScriptedAdapter([
      const _Step(
        status: 429,
        body: {
          'ok': false,
          'error': {
            'code': 'rate_limited',
            'message': 'تجاوزت الحد',
            'details': {'retry_after_seconds': 0},
          },
        },
      ),
    ]);
    final client = _client(adapter);

    await expectLater(
      client.get('/api/v1/sessions/online'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.code, 'code', 'rate_limited')
            .having((e) => e.message, 'message', contains('طلبات كثيرة')),
      ),
    );
    expect(adapter.calls, 3);
  });

  test('401 surfaces a clear auth error and is not retried', () async {
    final adapter = _ScriptedAdapter([
      const _Step(
        status: 401,
        body: {
          'ok': false,
          'error': {'code': 'unauthorized', 'message': 'no'},
        },
      ),
    ]);
    final client = _client(adapter);

    await expectLater(
      client.get('/api/v1/dashboard'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('سجّل الدخول مرة أخرى'),
        ),
      ),
    );
    expect(adapter.calls, 1);
  });
}
