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
    final path = options.path;
    final data = switch (path) {
      String p when p.endsWith('/assistant') => {
          'nas_id': 3,
          'operation': 'backup_save',
          'operation_label_ar': 'حفظ نسخة احتياطية',
          'can_proceed': true,
          'blocking_count': 0,
          'warning_count': 0,
          'operation_choices': [
            {'code': 'backup_save', 'label_ar': 'حفظ نسخة احتياطية'},
          ],
          'steps': [
            {
              'key': 'health',
              'label_ar': 'صحة الراوتر',
              'state': 'ok',
              'detail_ar': 'الحالة سليمة.',
            },
          ],
        },
      String p when p.endsWith('/backups') => {
          'router_id': 3,
          'count': 1,
          'backups': [
            {
              'id': 8,
              'name': 'before-change.backup',
              'router_status': 'on_router',
            },
          ],
        },
      String p when p.endsWith('/manifest') => {
          'id': 8,
          'router_id': 3,
          'manifest_summary': 'Hotspot',
          'manifest': {
            'services': ['hotspot'],
          },
        },
      String p when p.endsWith('/system/backup/save') => {
          'ok': true,
          'router_id': 3,
          'backup_id': 8,
          'backup_name': 'before-change',
        },
      String p when p.endsWith('/system/identity/set') => {
          'ok': true,
          'router_id': 3,
          'new_name': 'branch-router',
        },
      String p when p.endsWith('/system/reboot') => {
          'ok': true,
          'router_id': 3,
          'message': 'تم إرسال أمر إعادة التشغيل.',
        },
      String p when p.endsWith('/restore') => {
          'ok': true,
          'router_id': 3,
          'backup_id': 8,
          'router_filename': 'before-change.backup',
        },
      String p
          when p.endsWith('/ip/dns/cache/flush') ||
              p.endsWith('/system/ntp/sync') =>
        {'ok': true, 'router_id': 3},
      _ => {'deleted': true, 'backup_id': 8},
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
  test('MikrotikRepository sends protected router action requests', () async {
    final client = ApiClient(_MemoryTokenStorage(), _MemoryEndpointStorage());
    final adapter = _CaptureAdapter();
    client.dio.httpClientAdapter = adapter;
    final repo = MikrotikRepository(client);

    final backup = await repo.saveRouterBackup(
      3,
      name: 'before-change',
      notes: 'قبل تعديل السرعات',
    );
    final identity = await repo.setRouterIdentity(
      3,
      name: 'branch-router',
      reason: 'توحيد أسماء الفروع',
    );
    await repo.syncRouterNtp(3);
    await repo.flushRouterDnsCache(3);
    await repo.rebootRouter(3, reason: 'صيانة مجدولة');
    final assistant = await repo.guidedAssistant(
      3,
      operation: 'backup_save',
    );
    final backups = await repo.routerBackups(3);
    final manifest = await repo.routerBackupManifest(3, 8);
    await repo.restoreRouterBackup(3, 8, notes: 'استعادة بعد اختبار');
    await repo.deleteRouterBackup(3, 8);

    expect(backup.backupId, 8);
    expect(identity.newName, 'branch-router');
    expect(assistant.canProceed, isTrue);
    expect(assistant.operation, 'backup_save');
    expect(backups.backups.single.id, 8);
    expect(manifest['manifest_summary'], 'Hotspot');
    expect(
      adapter.requests.map((request) => '${request.method} ${request.path}'),
      [
        'POST /api/v1/mikrotik/3/system/backup/save',
        'POST /api/v1/mikrotik/3/system/identity/set',
        'POST /api/v1/mikrotik/3/system/ntp/sync',
        'POST /api/v1/mikrotik/3/ip/dns/cache/flush',
        'POST /api/v1/mikrotik/3/system/reboot',
        'GET /api/v1/mikrotik/3/assistant',
        'GET /api/v1/mikrotik/3/backups',
        'GET /api/v1/mikrotik/3/backups/8/manifest',
        'POST /api/v1/mikrotik/3/backups/8/restore',
        'DELETE /api/v1/mikrotik/3/backups/8',
      ],
    );
    expect(adapter.requests[1].data, {
      'confirm': true,
      'name': 'branch-router',
      'reason': 'توحيد أسماء الفروع',
    });
    expect(adapter.requests[4].data, {
      'confirm': true,
      'reason': 'صيانة مجدولة',
    });
    expect(adapter.requests[5].queryParameters, {'op': 'backup_save'});
    expect(adapter.requests[8].data, {
      'confirm': true,
      'notes': 'استعادة بعد اختبار',
    });
  });
}
