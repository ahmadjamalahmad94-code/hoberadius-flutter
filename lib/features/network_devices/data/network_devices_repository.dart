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

  Future<NetworkScanResult> scanRouter(int routerId) async {
    final res = await _api.post(
      '/api/v1/network-devices/scan',
      body: {'router_id': routerId},
    );
    final data = res['data'];
    return NetworkScanResult.fromJson(
      data is Map<String, dynamic> ? data : const {},
    );
  }

  Future<NetworkDevice> addScannedDevice({
    required int routerId,
    required NetworkScanItem item,
  }) async {
    final res = await _api.post(
      '/api/v1/network-devices/scan/add',
      body: {
        'router_id': routerId,
        'ip': item.address,
        'mac': item.physicalAddress,
        'hostname': item.hostname,
      },
    );
    return _deviceFromResponse(res);
  }

  Future<NetworkDeviceBypassState> bypassState(int id) async {
    final res = await _api.get('/api/v1/network-devices/$id/bypass');
    final data = res['data'];
    return NetworkDeviceBypassState.fromJson(
      data is Map<String, dynamic> ? data : const {},
    );
  }

  Future<NetworkDeviceBypassResult> applyBypass(
    int id, {
    required String dhcpServerName,
    required bool bypassHotspot,
    required bool addToAddressList,
  }) async {
    final res = await _api.post(
      '/api/v1/network-devices/$id/bypass/apply',
      body: {
        'dhcp_server_name': dhcpServerName,
        'bypass_hotspot': bypassHotspot,
        'add_to_address_list': addToAddressList,
      },
    );
    final data = res['data'];
    return NetworkDeviceBypassResult.fromJson(
      data is Map<String, dynamic> ? data : const {},
    );
  }

  Future<NetworkDeviceBypassRemoveResult> removeBypass(int id) async {
    final res = await _api.post('/api/v1/network-devices/$id/bypass/remove');
    final data = res['data'];
    return NetworkDeviceBypassRemoveResult.fromJson(
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
