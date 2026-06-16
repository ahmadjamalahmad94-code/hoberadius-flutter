import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/api/api_endpoint_storage.dart';
import 'package:hoberadius_app/core/auth/token_storage.dart';
import 'package:hoberadius_app/features/mikrotik/data/mikrotik_repository.dart';

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

class _ControlAdapter implements HttpClientAdapter {
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
    if (options.path.endsWith('/download')) {
      // Binary stream — not a JSON envelope.
      return ResponseBody.fromBytes(
        Uint8List.fromList([1, 2, 3, 4, 5]),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/octet-stream'],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode({
        'ok': true,
        'data': {'ok': true, 'router_id': 3, 'message': 'تم'},
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  test('MikrotikRepository wires K5/K6/K8 control mutations', () async {
    final client = ApiClient(_MemoryTokenStorage(), _MemoryEndpointStorage());
    final adapter = _ControlAdapter();
    client.dio.httpClientAdapter = adapter;
    final repo = MikrotikRepository(client);

    await repo.disconnectHotspotSession(3, '*1A');
    await repo.disconnectPppSession(3, '*2B');
    await repo
        .setSimpleQueue(3, '*7', {'max-limit': '10M/10M', 'disabled': false});
    await repo.addAddressListEntry(
      3,
      list: 'blocked',
      address: '192.168.1.5',
      comment: 'test',
      timeout: '1h',
    );
    await repo.removeAddressListEntry(3, '*9');
    final bytes = await repo.downloadRouterFile(3, 'backup file.backup');

    expect(bytes, [1, 2, 3, 4, 5]);
    expect(
      adapter.requests.map((r) => '${r.method} ${r.path}'),
      [
        'POST /api/v1/mikrotik/3/hotspot/active/*1A/disconnect',
        'POST /api/v1/mikrotik/3/ppp/active/*2B/disconnect',
        'PUT /api/v1/mikrotik/3/queues/simple/*7',
        'POST /api/v1/mikrotik/3/firewall/address-lists',
        'DELETE /api/v1/mikrotik/3/firewall/address-lists/*9',
        // Filename is URL-encoded (space → %20).
        'GET /api/v1/mikrotik/3/files/backup%20file.backup/download',
      ],
    );
    expect(adapter.requests[2].data, {
      'max-limit': '10M/10M',
      'disabled': false,
    });
    expect(adapter.requests[3].data, {
      'list': 'blocked',
      'address': '192.168.1.5',
      'comment': 'test',
      'timeout': '1h',
    });
  });
}
