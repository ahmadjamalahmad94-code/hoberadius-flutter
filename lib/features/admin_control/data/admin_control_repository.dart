import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/admin_control_model.dart';

class AdminControlRepository {
  AdminControlRepository(this._api);

  final ApiClient _api;

  Future<SettingsSnapshot> settings() async {
    final res = await _api.get('/api/v1/settings');
    return SettingsSnapshot.fromJson(_data(res));
  }

  Future<void> updateSetting(String key, String value) async {
    await _api.patch('/api/v1/settings', body: {'settings': {key: value}});
  }

  Future<List<TenantRecord>> tenants() async {
    final res = await _api.get('/api/v1/tenants');
    final items = _data(res)['items'];
    return items is List
        ? items
            .whereType<Map>()
            .map((item) => TenantRecord.fromJson(_map(item)))
            .toList()
        : const [];
  }

  Future<TenantRecord> createTenant(TenantRecord tenant) async {
    final res = await _api.post(
      '/api/v1/tenants',
      body: tenant.toBody(includeSlug: true),
    );
    return TenantRecord.fromJson(_data(res));
  }

  Future<TenantRecord> updateTenant(TenantRecord tenant) async {
    final res = await _api.patch(
      '/api/v1/tenants/${tenant.id}',
      body: tenant.toBody(),
    );
    return TenantRecord.fromJson(_data(res));
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) {
    final data = response['data'];
    return data is Map<String, dynamic> ? data : const {};
  }

  Map<String, dynamic> _map(Map source) {
    return source.map((key, value) => MapEntry('$key', value));
  }
}

final adminControlRepositoryProvider = Provider<AdminControlRepository>((ref) {
  return AdminControlRepository(ref.watch(apiClientProvider));
});
