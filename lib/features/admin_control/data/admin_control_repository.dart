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
    await _api.patch('/api/v1/settings', body: {
      'settings': {key: value},
    },);
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) {
    final data = response['data'];
    return data is Map<String, dynamic> ? data : const {};
  }
}

final adminControlRepositoryProvider = Provider<AdminControlRepository>((ref) {
  return AdminControlRepository(ref.watch(apiClientProvider));
});
