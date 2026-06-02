import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../domain/network_device_model.dart';

class NetworkDevicesRepository {
  NetworkDevicesRepository(this._api);

  final ApiClient _api;

  Future<NetworkDevicesState> list() async {
    final res = await _api.get('/api/v1/network-devices');
    final data = res['data'];
    return NetworkDevicesState.fromJson(
      data is Map<String, dynamic> ? data : const {},
    );
  }

  Future<NetworkDevice> create(NetworkDeviceDraft draft) async {
    final res = await _api.post(
      '/api/v1/network-devices',
      body: draft.toBody(),
    );
    return _deviceFromResponse(res);
  }

  Future<NetworkDevice> update(int id, NetworkDeviceDraft draft) async {
    final res = await _api.patch(
      '/api/v1/network-devices/$id',
      body: draft.toBody(),
    );
    return _deviceFromResponse(res);
  }

  Future<void> delete(int id) => _api.delete('/api/v1/network-devices/$id');

  Future<NetworkDeviceCheckResult> checkNow(int id) async {
    final res = await _api.post('/api/v1/network-devices/$id/check');
    final data = res['data'];
    return NetworkDeviceCheckResult.fromJson(
      data is Map<String, dynamic> ? data : const {},
    );
  }

  NetworkDevice _deviceFromResponse(Map<String, dynamic> res) {
    final data = res['data'];
    final map = data is Map<String, dynamic> ? data : const <String, dynamic>{};
    final device = map['device'];
    return NetworkDevice.fromJson(
      device is Map<String, dynamic> ? device : const {},
    );
  }
}

final networkDevicesRepositoryProvider =
    Provider<NetworkDevicesRepository>((ref) {
  return NetworkDevicesRepository(ref.watch(apiClientProvider));
});
