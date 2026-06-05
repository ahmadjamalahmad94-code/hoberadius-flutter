import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/api/api_endpoint_storage.dart';
import 'package:hoberadius_app/core/auth/token_storage.dart';
import 'package:hoberadius_app/features/sessions/data/sessions_repository.dart';

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
    return ResponseBody.fromString(
      jsonEncode({
        'ok': true,
        'data': {
          'path': options.path,
          'temporary_speed': {'reverted': true},
        },
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  test('SessionsRepository sends live control actions to session API',
      () async {
    final client = ApiClient(_MemoryTokenStorage(), _MemoryEndpointStorage());
    final adapter = _CaptureAdapter();
    client.dio.httpClientAdapter = adapter;
    final repo = SessionsRepository(client);

    await repo.lockMac(username: 'sub', sessionId: 'sess-1');
    await repo.lockIp(username: 'sub', sessionId: 'sess-1');
    await repo.applyTemporarySpeed(
      username: 'sub',
      sessionId: 'sess-1',
      downloadKbps: 2048,
      uploadKbps: 1024,
      durationMinutes: 30,
    );
    await repo.cancelTemporarySpeed(username: 'sub', sessionId: 'sess-1');

    expect(
      adapter.requests.map((request) => request.path),
      [
        '/api/v1/sessions/lock-mac',
        '/api/v1/sessions/lock-ip',
        '/api/v1/sessions/temp-speed',
        '/api/v1/sessions/temp-speed/cancel',
      ],
    );
    expect(
      adapter.requests.every((request) => request.method == 'POST'),
      isTrue,
    );
    expect(adapter.requests[0].data, {
      'username': 'sub',
      'session_id': 'sess-1',
    });
    expect(adapter.requests[2].data, {
      'username': 'sub',
      'session_id': 'sess-1',
      'down_kbps': 2048,
      'up_kbps': 1024,
      'duration_minutes': 30,
    });
  });
}
