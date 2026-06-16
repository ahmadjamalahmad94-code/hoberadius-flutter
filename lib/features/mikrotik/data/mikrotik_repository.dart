import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/mikrotik_model.dart';

class MikrotikRepository {
  const MikrotikRepository(this._api);

  final ApiClient _api;

  Future<List<MikrotikConfig>> list() async {
    final res = await _api.get('/api/v1/mikrotik');
    final data = _data(res);
    final raw = data['items'];
    return raw is List
        ? raw
            .whereType<Map<String, dynamic>>()
            .map(MikrotikConfig.fromJson)
            .toList()
        : const [];
  }

  Future<MikrotikConfig> create(
    MikrotikConfig config, {
    required String password,
  }) async {
    final res = await _api.post(
      '/api/v1/mikrotik',
      body: config.toBody(password: password),
    );
    return MikrotikConfig.fromJson(_data(res));
  }

  Future<MikrotikConfig> update(
    MikrotikConfig config, {
    String password = '',
  }) async {
    final id = config.id;
    if (id == null) {
      throw ArgumentError('معرّف اتصال ميكروتك مطلوب قبل التعديل');
    }
    final res = await _api.patch(
      '/api/v1/mikrotik/$id',
      body: config.toBody(password: password),
    );
    return MikrotikConfig.fromJson(_data(res));
  }

  Future<void> delete(int id) async {
    await _api.delete('/api/v1/mikrotik/$id');
  }

  Future<MikrotikTestResult> test(int id) async {
    final res = await _api.post('/api/v1/mikrotik/$id/test');
    return MikrotikTestResult.fromJson(_data(res));
  }

  Future<MikrotikTestResult> testCredentials(
    MikrotikConfig config, {
    required String password,
  }) async {
    final res = await _api.post(
      '/api/v1/mikrotik/test-credentials',
      body: config.toBody(password: password),
    );
    return MikrotikTestResult.fromJson(_data(res));
  }

  Future<MikrotikRouterOverview> routerOverview(int nasId) async {
    final res = await _api.get('/api/v1/mikrotik/$nasId/system/overview');
    return MikrotikRouterOverview.fromJson(_data(res));
  }

  Future<MikrotikGuidedChecklist> guidedAssistant(
    int nasId, {
    String operation = 'programming_hotspot',
  }) async {
    final res = await _api.get(
      '/api/v1/mikrotik/$nasId/assistant',
      query: {'op': operation},
    );
    return MikrotikGuidedChecklist.fromJson(_data(res));
  }

  Future<MikrotikLiveSnapshot> liveSnapshot(int nasId) async {
    final sections = await Future.wait(
      _liveSectionSpecs.map((spec) => _liveSection(nasId, spec)),
    );
    return MikrotikLiveSnapshot(routerId: nasId, sections: sections);
  }

  Future<MikrotikActionResult> saveRouterBackup(
    int nasId, {
    String name = '',
    String notes = '',
  }) async {
    final res = await _api.post(
      '/api/v1/mikrotik/$nasId/system/backup/save',
      body: {
        if (name.trim().isNotEmpty) 'name': name.trim(),
        if (notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );
    return MikrotikActionResult.fromJson(_data(res));
  }

  Future<MikrotikActionResult> rebootRouter(
    int nasId, {
    String reason = '',
  }) async {
    final res = await _api.post(
      '/api/v1/mikrotik/$nasId/system/reboot',
      body: {
        'confirm': true,
        if (reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
    return MikrotikActionResult.fromJson(_data(res));
  }

  Future<MikrotikActionResult> setRouterIdentity(
    int nasId, {
    required String name,
    String reason = '',
  }) async {
    final res = await _api.post(
      '/api/v1/mikrotik/$nasId/system/identity/set',
      body: {
        'confirm': true,
        'name': name.trim(),
        if (reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
    return MikrotikActionResult.fromJson(_data(res));
  }

  Future<MikrotikActionResult> syncRouterNtp(int nasId) async {
    final res = await _api.post('/api/v1/mikrotik/$nasId/system/ntp/sync');
    return MikrotikActionResult.fromJson(_data(res));
  }

  Future<MikrotikActionResult> flushRouterDnsCache(int nasId) async {
    final res = await _api.post('/api/v1/mikrotik/$nasId/ip/dns/cache/flush');
    return MikrotikActionResult.fromJson(_data(res));
  }

  // ── Diagnostics (mt_diagnostics.html) ──────────────────────────────
  Future<Map<String, dynamic>> pingFromRouter(
    int nasId,
    String target, {
    int count = 4,
  }) async {
    final res = await _api.post(
      '/api/v1/mikrotik/$nasId/tools/ping',
      body: {'target': target, 'count': count},
    );
    return _data(res);
  }

  Future<Map<String, dynamic>> tracerouteFromRouter(
    int nasId,
    String target, {
    int count = 3,
  }) async {
    final res = await _api.post(
      '/api/v1/mikrotik/$nasId/tools/traceroute',
      body: {'target': target, 'count': count},
    );
    return _data(res);
  }

  Future<Map<String, dynamic>> dnsResolveFromRouter(
    int nasId,
    String name, {
    String server = '',
  }) async {
    final res = await _api.post(
      '/api/v1/mikrotik/$nasId/tools/dns-resolve',
      body: {'name': name, if (server.isNotEmpty) 'server': server},
    );
    return _data(res);
  }

  // ── Active-session disconnect from the router ──────────────────────
  Future<MikrotikActionResult> disconnectHotspotSession(
    int nasId,
    String sessionId,
  ) async {
    final res = await _api.post(
      '/api/v1/mikrotik/$nasId/hotspot/active/$sessionId/disconnect',
    );
    return MikrotikActionResult.fromJson(_data(res));
  }

  Future<MikrotikActionResult> disconnectPppSession(
    int nasId,
    String sessionId,
  ) async {
    final res = await _api.post(
      '/api/v1/mikrotik/$nasId/ppp/active/$sessionId/disconnect',
    );
    return MikrotikActionResult.fromJson(_data(res));
  }

  // ── Simple-queue edit (K6) ─────────────────────────────────────────
  Future<MikrotikActionResult> setSimpleQueue(
    int nasId,
    String queueId,
    Map<String, dynamic> changes,
  ) async {
    final res = await _api.put(
      '/api/v1/mikrotik/$nasId/queues/simple/$queueId',
      body: changes,
    );
    return MikrotikActionResult.fromJson(_data(res));
  }

  // ── Firewall address-list CRUD (K6) ────────────────────────────────
  Future<MikrotikActionResult> addAddressListEntry(
    int nasId, {
    required String list,
    required String address,
    String comment = '',
    String timeout = '',
  }) async {
    final res = await _api.post(
      '/api/v1/mikrotik/$nasId/firewall/address-lists',
      body: {
        'list': list,
        'address': address,
        if (comment.isNotEmpty) 'comment': comment,
        if (timeout.isNotEmpty) 'timeout': timeout,
      },
    );
    return MikrotikActionResult.fromJson(_data(res));
  }

  Future<MikrotikActionResult> removeAddressListEntry(
    int nasId,
    String entryId,
  ) async {
    final res = await _api.delete(
      '/api/v1/mikrotik/$nasId/firewall/address-lists/$entryId',
    );
    return MikrotikActionResult.fromJson(_data(res));
  }

  // ── P7 risk signals (loops / flapping / overlap) ───────────────────
  Future<Map<String, dynamic>> routerHealth(int nasId) async {
    final res = await _api.get('/api/v1/mikrotik/$nasId/health');
    return _data(res);
  }

  Future<MikrotikRouterBackupsPage> routerBackups(int nasId) async {
    final res = await _api.get('/api/v1/mikrotik/$nasId/backups');
    return MikrotikRouterBackupsPage.fromJson(_data(res));
  }

  Future<Map<String, dynamic>> routerBackupManifest(
    int nasId,
    int backupId,
  ) async {
    final res =
        await _api.get('/api/v1/mikrotik/$nasId/backups/$backupId/manifest');
    return _data(res);
  }

  Future<MikrotikActionResult> restoreRouterBackup(
    int nasId,
    int backupId, {
    String notes = '',
  }) async {
    final res = await _api.post(
      '/api/v1/mikrotik/$nasId/backups/$backupId/restore',
      body: {
        'confirm': true,
        if (notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );
    return MikrotikActionResult.fromJson(_data(res));
  }

  Future<MikrotikActionResult> deleteRouterBackup(
    int nasId,
    int backupId,
  ) async {
    final res = await _api.delete('/api/v1/mikrotik/$nasId/backups/$backupId');
    return MikrotikActionResult.fromJson(_data(res));
  }

  Future<MikrotikLiveSection> _liveSection(
    int nasId,
    _LiveSectionSpec spec,
  ) async {
    final path = spec.path.replaceAll('{id}', nasId.toString());
    try {
      final res = await _api.get(path, query: spec.query);
      return MikrotikLiveSection.fromJson(
        key: spec.key,
        title: spec.title,
        path: path,
        json: _data(res),
      );
    } catch (error) {
      return MikrotikLiveSection.failed(
        key: spec.key,
        title: spec.title,
        path: path,
        error: error.toString(),
      );
    }
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) {
    final data = response['data'];
    return data is Map<String, dynamic> ? data : const {};
  }
}

final mikrotikRepositoryProvider = Provider<MikrotikRepository>((ref) {
  return MikrotikRepository(ref.watch(apiClientProvider));
});

class _LiveSectionSpec {
  const _LiveSectionSpec(
    this.key,
    this.title,
    this.path, {
    this.query,
  });

  final String key;
  final String title;
  final String path;
  final Map<String, dynamic>? query;
}

const _liveSectionSpecs = <_LiveSectionSpec>[
  _LiveSectionSpec(
    'interfaces',
    'واجهات الراوتر',
    '/api/v1/mikrotik/{id}/interfaces',
  ),
  _LiveSectionSpec(
    'ip_addresses',
    'عناوين IP على الراوتر',
    '/api/v1/mikrotik/{id}/ip/addresses',
  ),
  _LiveSectionSpec(
    'routes',
    'مسارات التوجيه',
    '/api/v1/mikrotik/{id}/routes',
  ),
  _LiveSectionSpec(
    'neighbors',
    'الأجهزة المجاورة',
    '/api/v1/mikrotik/{id}/neighbors',
  ),
  _LiveSectionSpec(
    'hotspot_active',
    'جلسات الهوتسبوت النشطة',
    '/api/v1/mikrotik/{id}/hotspot/active',
  ),
  _LiveSectionSpec(
    'ppp_active',
    'جلسات PPP النشطة',
    '/api/v1/mikrotik/{id}/ppp/active',
  ),
  _LiveSectionSpec(
    'queues',
    'الطوابير والسرعات',
    '/api/v1/mikrotik/{id}/queues/simple',
  ),
  _LiveSectionSpec(
    'firewall_filter',
    'قواعد فلترة الجدار الناري',
    '/api/v1/mikrotik/{id}/firewall/filter',
  ),
  _LiveSectionSpec(
    'firewall_nat',
    'قواعد NAT',
    '/api/v1/mikrotik/{id}/firewall/nat',
  ),
  _LiveSectionSpec(
    'address_lists',
    'قوائم العناوين',
    '/api/v1/mikrotik/{id}/firewall/address-lists',
  ),
  _LiveSectionSpec(
    'logs',
    'آخر سجل من الراوتر',
    '/api/v1/mikrotik/{id}/log',
    query: {'limit': 30},
  ),
  _LiveSectionSpec(
    'files',
    'ملفات الراوتر',
    '/api/v1/mikrotik/{id}/files',
  ),
  _LiveSectionSpec(
    'router_backups',
    'نسخ الراوتر المحفوظة',
    '/api/v1/mikrotik/{id}/backups',
  ),
  _LiveSectionSpec(
    'counters',
    'عدادات التشغيل',
    '/api/v1/mikrotik/{id}/counters',
  ),
];
