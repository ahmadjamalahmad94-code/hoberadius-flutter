import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/api/api_endpoint_storage.dart';
import 'package:hoberadius_app/core/auth/token_storage.dart';
import 'package:hoberadius_app/features/network_policy/data/network_policy_repository.dart';
import 'package:hoberadius_app/features/network_policy/domain/network_policy_model.dart';

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
    final data = switch (options.path) {
      String path when path.endsWith('/preview.rsc') => {
          'filename': 'policy-preview.rsc',
          'script': '/ip firewall filter add',
          'script_hash': 'abc',
        },
      String path when path.endsWith('/changes') => {
          'count': 1,
          'items': [
            {
              'id': 7,
              'action_type': 'apply',
              'status': 'succeeded',
              'execution_mode': 'full',
              'rollback_eligible': true,
              'targets': [
                {'router_id': 3, 'status': 'succeeded'},
              ],
            },
          ],
        },
      String path when path.endsWith('/duplicate') => {
          'id': 9,
          'router_id': 3,
          'name': 'نسخة',
          'slug': 'copy',
          'enabled': true,
        },
      _ => {
          'ok': true,
          'change_set_id': 8,
          'status': 'succeeded',
          'reason_ar': 'تم التنفيذ بنجاح.',
        },
    };
    return ResponseBody.fromString(
      jsonEncode({'ok': true, 'data': data}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  test('NetworkPolicyRepository sends runtime actions to API', () async {
    final client = ApiClient(_MemoryTokenStorage(), _MemoryEndpointStorage());
    final adapter = _CaptureAdapter();
    client.dio.httpClientAdapter = adapter;
    final repo = NetworkPolicyRepository(client);
    final kind = networkPolicyKindBySlug('remote-access');

    final script = await repo.script(kind, 5);
    final apply = await repo.apply(
      kind,
      5,
      confirmations: const ['operator_reviewed_preview'],
    );
    final changes = await repo.changes(kind, 5);
    final rollback = await repo.rollback(kind, 5, 7);
    final copy = await repo.duplicate(kind, 5);

    expect(script.filename, 'policy-preview.rsc');
    expect(apply.changeSetId, 8);
    expect(changes.items.single.rollbackEligible, isTrue);
    expect(rollback.status, 'succeeded');
    expect(copy.id, 9);
    expect(
      adapter.requests.map((request) => '${request.method} ${request.path}'),
      [
        'GET /api/v1/network-policy/remote-access/policies/5/preview.rsc',
        'POST /api/v1/network-policy/remote-access/policies/5/apply',
        'GET /api/v1/network-policy/remote-access/policies/5/changes',
        'POST /api/v1/network-policy/remote-access/policies/5/changes/7/rollback',
        'POST /api/v1/network-policy/remote-access/policies/5/duplicate',
      ],
    );
  });
}
