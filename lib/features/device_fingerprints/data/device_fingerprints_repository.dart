import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/device_fingerprint_model.dart';

class DeviceFingerprintsRepository {
  const DeviceFingerprintsRepository(this._api);

  final ApiClient _api;

  Future<DeviceFingerprintsPage> list({
    String osFamily = '',
    int limit = 200,
    int offset = 0,
  }) async {
    final res = await _api.get(
      '/api/v1/devices',
      query: {
        'limit': limit,
        'offset': offset,
        if (osFamily.trim().isNotEmpty && osFamily != 'all') 'os': osFamily,
      },
    );
    return DeviceFingerprintsPage.fromJson(_data(res));
  }

  Future<DeviceFingerprint> byMac(String mac) async {
    final res = await _api.get('/api/v1/devices/by-mac/$mac');
    final data = _data(res);
    final device = data['device'];
    return DeviceFingerprint.fromJson(
      device is Map<String, dynamic> ? device : data,
    );
  }

  Future<DeviceSyncResult> syncNow() async {
    final res = await _api.post('/api/v1/devices/sync');
    return DeviceSyncResult.fromJson(_data(res));
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) {
    final data = response['data'];
    return data is Map<String, dynamic> ? data : const {};
  }
}

final deviceFingerprintsRepositoryProvider =
    Provider<DeviceFingerprintsRepository>((ref) {
  return DeviceFingerprintsRepository(ref.watch(apiClientProvider));
});
