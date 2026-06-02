class NetworkDevicesState {
  const NetworkDevicesState({
    required this.items,
    required this.summary,
    required this.routers,
  });

  final List<NetworkDevice> items;
  final NetworkDevicesSummary summary;
  final List<NetworkDeviceRouter> routers;

  factory NetworkDevicesState.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final rawRouters = json['routers'];
    return NetworkDevicesState(
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((item) => NetworkDevice.fromJson(_map(item)))
              .toList()
          : const [],
      summary: NetworkDevicesSummary.fromJson(_map(json['summary'])),
      routers: rawRouters is List
          ? rawRouters
              .whereType<Map>()
              .map((item) => NetworkDeviceRouter.fromJson(_map(item)))
              .toList()
          : const [],
    );
  }
}

class NetworkDeviceRouter {
  const NetworkDeviceRouter({
    required this.id,
    required this.name,
    required this.address,
  });

  final int id;
  final String name;
  final String address;

  factory NetworkDeviceRouter.fromJson(Map<String, dynamic> json) {
    return NetworkDeviceRouter(
      id: _int(json['id']),
      name: _string(json['name']),
      address: _string(json['address']),
    );
  }
}

class NetworkDevicesSummary {
  const NetworkDevicesSummary({
    required this.total,
    required this.up,
    required this.down,
    required this.unknown,
    required this.watched,
    required this.critical,
    required this.alerts,
  });

  final int total;
  final int up;
  final int down;
  final int unknown;
  final int watched;
  final int critical;
  final int alerts;

  factory NetworkDevicesSummary.fromJson(Map<String, dynamic> json) {
    return NetworkDevicesSummary(
      total: _int(json['total']),
      up: _int(json['up']),
      down: _int(json['down']),
      unknown: _int(json['unknown']),
      watched: _int(json['watched']),
      critical: _int(json['critical']),
      alerts: _int(json['alerts']),
    );
  }
}

class NetworkDevice {
  const NetworkDevice({
    required this.id,
    required this.routerId,
    required this.routerName,
    required this.routerAddress,
    required this.name,
    required this.deviceType,
    required this.deviceTypeLabel,
    required this.address,
    required this.physicalAddress,
    required this.location,
    required this.managementPort,
    required this.notes,
    required this.isCritical,
    required this.watchEnabled,
    required this.alertEnabled,
    required this.lastStatus,
    required this.lastStatusLabel,
    required this.lastCheckedAt,
    this.lastLatencyMs,
  });

  final int id;
  final int routerId;
  final String routerName;
  final String routerAddress;
  final String name;
  final String deviceType;
  final String deviceTypeLabel;
  final String address;
  final String physicalAddress;
  final String location;
  final int managementPort;
  final String notes;
  final bool isCritical;
  final bool watchEnabled;
  final bool alertEnabled;
  final String lastStatus;
  final String lastStatusLabel;
  final String lastCheckedAt;
  final num? lastLatencyMs;

  factory NetworkDevice.fromJson(Map<String, dynamic> json) {
    return NetworkDevice(
      id: _int(json['id']),
      routerId: _int(json['router_id']),
      routerName: _string(json['router_name']),
      routerAddress: _string(json['router_address']),
      name: _string(json['name']),
      deviceType: _string(json['device_type']),
      deviceTypeLabel: _string(json['device_type_label']),
      address: _string(json['ip_address']),
      physicalAddress: _string(json['mac_address']),
      location: _string(json['location']),
      managementPort: _int(json['management_port']),
      notes: _string(json['notes']),
      isCritical: _bool(json['is_critical']),
      watchEnabled: _bool(json['watch_enabled']),
      alertEnabled: _bool(json['alert_enabled']),
      lastStatus: _string(json['last_status']),
      lastStatusLabel: _string(json['last_status_label']),
      lastCheckedAt: _string(json['last_checked_at']),
      lastLatencyMs: json['last_latency_ms'] is num
          ? json['last_latency_ms'] as num
          : num.tryParse(_string(json['last_latency_ms'])),
    );
  }

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [
      name,
      deviceTypeLabel,
      address,
      physicalAddress,
      location,
      routerName,
      routerAddress,
      notes,
    ].any((value) => value.toLowerCase().contains(q));
  }
}

class NetworkDeviceDraft {
  const NetworkDeviceDraft({
    required this.routerId,
    required this.name,
    required this.deviceType,
    required this.address,
    required this.physicalAddress,
    required this.location,
    required this.managementPort,
    required this.notes,
    required this.isCritical,
    required this.watchEnabled,
    required this.alertEnabled,
  });

  final int routerId;
  final String name;
  final String deviceType;
  final String address;
  final String physicalAddress;
  final String location;
  final int managementPort;
  final String notes;
  final bool isCritical;
  final bool watchEnabled;
  final bool alertEnabled;

  factory NetworkDeviceDraft.fromDevice(NetworkDevice device) {
    return NetworkDeviceDraft(
      routerId: device.routerId,
      name: device.name,
      deviceType: device.deviceType.isEmpty ? 'other' : device.deviceType,
      address: device.address,
      physicalAddress: device.physicalAddress,
      location: device.location,
      managementPort: device.managementPort == 0 ? 80 : device.managementPort,
      notes: device.notes,
      isCritical: device.isCritical,
      watchEnabled: device.watchEnabled,
      alertEnabled: device.alertEnabled,
    );
  }

  Map<String, dynamic> toBody() => {
        'router_id': routerId,
        'name': name.trim(),
        'device_type': deviceType,
        'ip_address': address.trim(),
        'mac_address': physicalAddress.trim(),
        'location': location.trim(),
        'management_port': managementPort,
        'notes': notes.trim(),
        'is_critical': isCritical,
        'watch_enabled': watchEnabled,
        'alert_enabled': alertEnabled,
      };
}

class NetworkDeviceCheckResult {
  const NetworkDeviceCheckResult({
    required this.ok,
    required this.status,
    required this.message,
    this.latencyMs,
  });

  final bool ok;
  final String status;
  final String message;
  final num? latencyMs;

  factory NetworkDeviceCheckResult.fromJson(Map<String, dynamic> json) {
    return NetworkDeviceCheckResult(
      ok: _bool(json['ok']),
      status: _string(json['status']),
      message: _string(json['message']),
      latencyMs: json['latency_ms'] is num
          ? json['latency_ms'] as num
          : num.tryParse(_string(json['latency_ms'])),
    );
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return const {};
}

String _string(Object? value) => (value ?? '').toString();

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(_string(value)) ?? 0;
}

bool _bool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = _string(value).trim().toLowerCase();
  return {'1', 'true', 'yes', 'on', 'enabled'}.contains(text);
}
