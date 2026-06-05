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

  Future<MikrotikLiveSnapshot> liveSnapshot(int nasId) async {
    final sections = await Future.wait(
      _liveSectionSpecs.map((spec) => _liveSection(nasId, spec)),
    );
    return MikrotikLiveSnapshot(routerId: nasId, sections: sections);
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
