import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/api/api_endpoint_storage.dart';
import 'package:hoberadius_app/core/auth/security_key_storage.dart';
import 'package:hoberadius_app/core/auth/token_storage.dart';

/// One request the app sent through [RecordingAdapter].
class RecordedRequest {
  RecordedRequest({
    required this.method,
    required this.path,
    required this.query,
    required this.headers,
    required this.body,
  });

  final String method;
  final String path;
  final Map<String, dynamic> query;
  final Map<String, dynamic> headers;
  final Object? body;

  Map<String, dynamic> get jsonBody =>
      body is Map<String, dynamic> ? body as Map<String, dynamic> : const {};

  @override
  String toString() => '$method $path $query ${jsonEncode(body)}';
}

/// A canned HTTP answer.
class FakeResponse {
  const FakeResponse(this.status, this.json, {this.headers = const {}});

  factory FakeResponse.ok(Object? data, {int status = 200}) =>
      FakeResponse(status, {'ok': true, 'data': data});

  factory FakeResponse.error(
    int status,
    String code,
    String message, {
    Object? details,
  }) =>
      FakeResponse(status, {
        'ok': false,
        'error': {
          'code': code,
          'message': message,
          if (details != null) 'details': details,
        },
      });

  final int status;
  final Object? json;
  final Map<String, List<String>> headers;
}

typedef FakeHandler = FakeResponse Function(RecordedRequest request);

/// Dio adapter that records every request and answers through [handler].
class RecordingAdapter implements HttpClientAdapter {
  RecordingAdapter(this.handler);

  FakeHandler handler;
  final List<RecordedRequest> requests = [];

  Iterable<RecordedRequest> where(String method, String pathPart) =>
      requests.where((r) => r.method == method && r.path.contains(pathPart));

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final chunks = <int>[];
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        chunks.addAll(chunk);
      }
    }
    Object? body;
    if (chunks.isNotEmpty) {
      try {
        body = jsonDecode(utf8.decode(chunks));
      } catch (_) {
        body = utf8.decode(chunks);
      }
    }
    final req = RecordedRequest(
      method: options.method,
      path: options.path,
      query: Map<String, dynamic>.from(options.queryParameters),
      headers: Map<String, dynamic>.from(options.headers),
      body: body,
    );
    requests.add(req);
    final res = handler(req);
    return ResponseBody.fromString(
      jsonEncode(res.json),
      res.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        ...res.headers,
      },
    );
  }
}

class _MemTokenStorage implements TokenStorage {
  @override
  Future<void> clear() async {}
  @override
  Future<String?> read() async => 'test-token';
  @override
  Future<void> write(String token) async {}
}

class _MemEndpointStorage implements ApiEndpointStorage {
  @override
  Future<String> readBaseUrl() async => 'http://127.0.0.1:5000';
  @override
  Future<void> writeBaseUrl(String baseUrl) async {}
}

class _MemSecurityKeyStorage implements SecurityKeyStorage {
  @override
  Future<void> clear() async {}
  @override
  Future<String?> read() async => null;
  @override
  Future<void> write(String key) async {}
}

/// ApiClient wired to [adapter], with retries off so tests stay fast.
ApiClient fakeApiClient(RecordingAdapter adapter) {
  final client = ApiClient(
    _MemTokenStorage(),
    _MemEndpointStorage(),
    securityKeyStorage: _MemSecurityKeyStorage(),
    config: const ApiClientConfig(maxRetries: 0),
  );
  client.dio.httpClientAdapter = adapter;
  return client;
}
