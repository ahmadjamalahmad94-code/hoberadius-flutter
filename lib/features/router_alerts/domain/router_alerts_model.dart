class RouterAlertsState {
  const RouterAlertsState({
    required this.settings,
    required this.routers,
    required this.loopProbes,
    required this.counts,
    required this.usageWindows,
  });

  final RouterAlertSettings settings;
  final List<RouterAlertTarget> routers;
  final List<RouterLoopProbe> loopProbes;
  final RouterAlertCounts counts;
  final List<UsageWindowOption> usageWindows;

  factory RouterAlertsState.fromJson(Map<String, dynamic> json) {
    final rawRouters = json['routers'];
    final rawLoopProbes = json['loop_probes'];
    final rawWindows = json['usage_windows'];
    return RouterAlertsState(
      settings: RouterAlertSettings.fromJson(_map(json['settings'])),
      routers: rawRouters is List
          ? rawRouters
              .whereType<Map>()
              .map((item) => RouterAlertTarget.fromJson(_map(item)))
              .toList()
          : const [],
      loopProbes: rawLoopProbes is List
          ? rawLoopProbes
              .whereType<Map>()
              .map((item) => RouterLoopProbe.fromJson(_map(item)))
              .toList()
          : const [],
      counts: RouterAlertCounts.fromJson(_map(json['counts'])),
      usageWindows: rawWindows is List
          ? rawWindows
              .whereType<Map>()
              .map((item) => UsageWindowOption.fromJson(_map(item)))
              .toList()
          : const [
              UsageWindowOption(key: 'day', label: 'يومي'),
              UsageWindowOption(key: 'month', label: 'شهري'),
            ],
    );
  }
}

class RouterAlertSettings {
  const RouterAlertSettings({
    required this.enabled,
    required this.telegram,
    required this.offline,
    required this.highTraffic,
    required this.highUsage,
    required this.loop,
    required this.offlineAfterMin,
    required this.defaultSpeedMbps,
    required this.defaultUsageGb,
    required this.usageWindow,
  });

  final bool enabled;
  final bool telegram;
  final bool offline;
  final bool highTraffic;
  final bool highUsage;
  final bool loop;
  final int offlineAfterMin;
  final int defaultSpeedMbps;
  final int defaultUsageGb;
  final String usageWindow;

  factory RouterAlertSettings.fromJson(Map<String, dynamic> json) {
    return RouterAlertSettings(
      enabled: _bool(json['enabled'], fallback: true),
      telegram: _bool(json['telegram'], fallback: true),
      offline: _bool(json['offline'], fallback: true),
      highTraffic: _bool(json['high_traffic'], fallback: true),
      highUsage: _bool(json['high_usage'], fallback: true),
      loop: _bool(json['loop'], fallback: true),
      offlineAfterMin: _int(json['offline_after_min'], fallback: 6),
      defaultSpeedMbps: _int(json['default_speed_mbps'], fallback: 100),
      defaultUsageGb: _int(json['default_usage_gb'], fallback: 200),
      usageWindow: _string(json['usage_window'], fallback: 'day'),
    );
  }

  RouterAlertSettings copyWith({
    bool? enabled,
    bool? telegram,
    bool? offline,
    bool? highTraffic,
    bool? highUsage,
    bool? loop,
    int? offlineAfterMin,
    int? defaultSpeedMbps,
    int? defaultUsageGb,
    String? usageWindow,
  }) {
    return RouterAlertSettings(
      enabled: enabled ?? this.enabled,
      telegram: telegram ?? this.telegram,
      offline: offline ?? this.offline,
      highTraffic: highTraffic ?? this.highTraffic,
      highUsage: highUsage ?? this.highUsage,
      loop: loop ?? this.loop,
      offlineAfterMin: offlineAfterMin ?? this.offlineAfterMin,
      defaultSpeedMbps: defaultSpeedMbps ?? this.defaultSpeedMbps,
      defaultUsageGb: defaultUsageGb ?? this.defaultUsageGb,
      usageWindow: usageWindow ?? this.usageWindow,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'telegram': telegram,
        'offline': offline,
        'high_traffic': highTraffic,
        'high_usage': highUsage,
        'loop': loop,
        'offline_after_min': offlineAfterMin,
        'default_speed_mbps': defaultSpeedMbps,
        'default_usage_gb': defaultUsageGb,
        'usage_window': usageWindow,
      };
}

class RouterAlertTarget {
  const RouterAlertTarget({
    required this.id,
    required this.name,
    required this.address,
    required this.enabled,
    required this.offlineAfterMin,
    required this.normalSpeedMbps,
    required this.normalUsageGb,
    required this.usageWindow,
    required this.lastPushAt,
    required this.hasOverride,
  });

  final int id;
  final String name;
  final String address;
  final bool enabled;
  final int offlineAfterMin;
  final int normalSpeedMbps;
  final int normalUsageGb;
  final String usageWindow;
  final String lastPushAt;
  final bool hasOverride;

  factory RouterAlertTarget.fromJson(Map<String, dynamic> json) {
    return RouterAlertTarget(
      id: _int(json['id']),
      name: _string(json['name']),
      address: _string(json['address']),
      enabled: _bool(json['enabled'], fallback: true),
      offlineAfterMin: _int(json['offline_after_min'], fallback: 6),
      normalSpeedMbps: _int(json['normal_speed_mbps'], fallback: 100),
      normalUsageGb: _int(json['normal_usage_gb'], fallback: 200),
      usageWindow: _string(json['usage_window'], fallback: 'day'),
      lastPushAt: _string(json['last_push_at']),
      hasOverride: _bool(json['has_override']),
    );
  }

  RouterAlertTarget copyWith({
    bool? enabled,
    int? offlineAfterMin,
    int? normalSpeedMbps,
    int? normalUsageGb,
    String? usageWindow,
  }) {
    return RouterAlertTarget(
      id: id,
      name: name,
      address: address,
      enabled: enabled ?? this.enabled,
      offlineAfterMin: offlineAfterMin ?? this.offlineAfterMin,
      normalSpeedMbps: normalSpeedMbps ?? this.normalSpeedMbps,
      normalUsageGb: normalUsageGb ?? this.normalUsageGb,
      usageWindow: usageWindow ?? this.usageWindow,
      lastPushAt: lastPushAt,
      hasOverride: hasOverride,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'enabled': enabled,
        'offline_after_min': offlineAfterMin,
        'normal_speed_mbps': normalSpeedMbps,
        'normal_usage_gb': normalUsageGb,
        'usage_window': usageWindow,
      };
}

class RouterAlertCounts {
  const RouterAlertCounts({
    required this.routers,
    required this.pushing,
    required this.overrides,
    required this.loopProbes,
    required this.loopDetected,
    required this.loopRouters,
  });

  final int routers;
  final int pushing;
  final int overrides;
  final int loopProbes;
  final int loopDetected;
  final int loopRouters;

  factory RouterAlertCounts.fromJson(Map<String, dynamic> json) {
    return RouterAlertCounts(
      routers: _int(json['routers']),
      pushing: _int(json['pushing']),
      overrides: _int(json['overrides']),
      loopProbes: _int(json['loop_probes']),
      loopDetected: _int(json['loop_detected']),
      loopRouters: _int(json['loop_routers']),
    );
  }
}

class RouterLoopProbe {
  const RouterLoopProbe({
    required this.routerId,
    required this.routerName,
    required this.interfaceName,
    required this.enabled,
    required this.status,
    required this.leaseIp,
    required this.serverIp,
    required this.lastReadingAt,
    required this.loopDetected,
  });

  final int routerId;
  final String routerName;
  final String interfaceName;
  final bool enabled;
  final String status;
  final String leaseIp;
  final String serverIp;
  final String lastReadingAt;
  final bool loopDetected;

  factory RouterLoopProbe.fromJson(Map<String, dynamic> json) {
    return RouterLoopProbe(
      routerId: _int(json['router_id']),
      routerName: _string(json['router_name']),
      interfaceName: _string(json['interface']),
      enabled: _bool(json['enabled'], fallback: true),
      status: _string(json['status']),
      leaseIp: _string(json['lease_ip']),
      serverIp: _string(json['server_ip']),
      lastReadingAt: _string(json['last_reading_at']),
      loopDetected: _bool(json['loop_detected']),
    );
  }
}

class UsageWindowOption {
  const UsageWindowOption({required this.key, required this.label});

  final String key;
  final String label;

  factory UsageWindowOption.fromJson(Map<String, dynamic> json) {
    return UsageWindowOption(
      key: _string(json['key'], fallback: 'day'),
      label: _string(json['label'], fallback: 'يومي'),
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

String _string(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

int _int(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

bool _bool(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  final text = value?.toString().trim().toLowerCase();
  if (text == null || text.isEmpty) return fallback;
  if (['1', 'true', 'yes', 'on'].contains(text)) return true;
  if (['0', 'false', 'no', 'off'].contains(text)) return false;
  return fallback;
}
