class DeviceFingerprint {
  const DeviceFingerprint({
    required this.id,
    required this.mac,
    required this.hostname,
    required this.dhcpClassId,
    required this.osFamily,
    required this.osVersion,
    required this.deviceBrand,
    required this.deviceModel,
    required this.ipAddress,
    this.nasId,
    required this.firstSeenAt,
    required this.lastSeenAt,
  });

  final int id;
  final String mac;
  final String hostname;
  final String dhcpClassId;
  final String osFamily;
  final String osVersion;
  final String deviceBrand;
  final String deviceModel;
  final String ipAddress;
  final int? nasId;
  final String firstSeenAt;
  final String lastSeenAt;

  factory DeviceFingerprint.fromJson(Map<String, dynamic> json) {
    return DeviceFingerprint(
      id: _asInt(json['id']),
      mac: (json['mac'] ?? '').toString(),
      hostname: (json['hostname'] ?? '').toString(),
      dhcpClassId: (json['dhcp_class_id'] ?? '').toString(),
      osFamily: (json['os_family'] ?? '').toString(),
      osVersion: (json['os_version'] ?? '').toString(),
      deviceBrand: (json['device_brand'] ?? '').toString(),
      deviceModel: (json['device_model'] ?? '').toString(),
      ipAddress: (json['ip_address'] ?? '').toString(),
      nasId: _asIntOrNull(json['nas_id']),
      firstSeenAt: (json['first_seen_at'] ?? '').toString(),
      lastSeenAt: (json['last_seen_at'] ?? '').toString(),
    );
  }

  String get title {
    if (hostname.trim().isNotEmpty) return hostname;
    if (deviceModel.trim().isNotEmpty) return deviceModel;
    return mac.isEmpty ? 'جهاز غير معروف' : mac;
  }

  String get deviceLabel {
    final parts = [
      if (deviceBrand.isNotEmpty) deviceBrand,
      if (deviceModel.isNotEmpty) deviceModel,
    ];
    return parts.isEmpty ? 'غير معروف' : parts.join(' ');
  }

  String get osLabel {
    final family = switch (osFamily.toLowerCase()) {
      'android' => 'Android',
      'ios' => 'iOS',
      'windows' => 'Windows',
      'macos' => 'macOS',
      'linux' => 'Linux',
      'other' => 'أخرى',
      _ => 'غير معروف',
    };
    return osVersion.isEmpty ? family : '$family $osVersion';
  }

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [
      mac,
      hostname,
      dhcpClassId,
      osFamily,
      osVersion,
      deviceBrand,
      deviceModel,
      ipAddress,
      '${nasId ?? ''}',
    ].any((value) => value.toLowerCase().contains(q));
  }
}

class DeviceFingerprintsPage {
  const DeviceFingerprintsPage({
    required this.items,
    required this.count,
    required this.total,
    required this.limit,
    required this.offset,
  });

  final List<DeviceFingerprint> items;
  final int count;
  final int total;
  final int limit;
  final int offset;

  factory DeviceFingerprintsPage.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return DeviceFingerprintsPage(
      items: raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map(DeviceFingerprint.fromJson)
              .toList()
          : const [],
      count: _asInt(json['count']),
      total: _asInt(json['total']),
      limit: _asInt(json['limit']),
      offset: _asInt(json['offset']),
    );
  }
}

class DeviceSyncResult {
  const DeviceSyncResult({required this.macsSeen});

  final int macsSeen;

  factory DeviceSyncResult.fromJson(Map<String, dynamic> json) {
    final raw = json['macs_seen'];
    if (raw is List) return DeviceSyncResult(macsSeen: raw.length);
    return DeviceSyncResult(macsSeen: _asInt(raw));
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString()) ?? 0;
}

int? _asIntOrNull(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
