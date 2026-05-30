import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/api/api_endpoint_storage.dart';
import 'package:hoberadius_app/core/api/api_exception.dart';
import 'package:hoberadius_app/core/auth/token_storage.dart';

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

class _CountingAdapter implements HttpClientAdapter {
  int calls = 0;
  final Completer<void> gate = Completer<void>();

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls += 1;
    await gate.future;
    return ResponseBody.fromString(
      jsonEncode({
        'ok': true,
        'data': {'path': options.path},
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

class _ApiErrorAdapter implements HttpClientAdapter {
  _ApiErrorAdapter(this.code, this.message);

  final String code;
  final String message;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({
        'ok': false,
        'error': {'code': code, 'message': message},
      }),
      400,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  test('ApiClient coalesces identical in-flight GET requests', () async {
    final client = ApiClient(_MemoryTokenStorage(), _MemoryEndpointStorage());
    final adapter = _CountingAdapter();
    client.dio.httpClientAdapter = adapter;

    final first = client.get('/api/v1/sessions/online', query: {'type': 'all'});
    final second =
        client.get('/api/v1/sessions/online', query: {'type': 'all'});
    adapter.gate.complete();

    final results = await Future.wait([first, second]);
    expect(adapter.calls, 1);
    expect(results[0]['data'], results[1]['data']);
  });

  test('ApiClient hides raw English API messages from visible errors',
      () async {
    final client = ApiClient(_MemoryTokenStorage(), _MemoryEndpointStorage());
    client.dio.httpClientAdapter = _ApiErrorAdapter(
      'bad_request',
      'Invalid username or password',
    );

    try {
      await client.get('/api/v1/dashboard');
      fail('request should fail');
    } on ApiException catch (e) {
      expect(e.message, 'اسم المستخدم أو كلمة المرور غير صحيحة.');
      expect(e.message, isNot(contains('Invalid')));
    }
  });
}
