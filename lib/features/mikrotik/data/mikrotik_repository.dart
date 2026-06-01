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
      throw ArgumentError('معرّف اتصال MikroTik مطلوب قبل التعديل');
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

  Map<String, dynamic> _data(Map<String, dynamic> response) {
    final data = response['data'];
    return data is Map<String, dynamic> ? data : const {};
  }
}

final mikrotikRepositoryProvider = Provider<MikrotikRepository>((ref) {
  return MikrotikRepository(ref.watch(apiClientProvider));
});
