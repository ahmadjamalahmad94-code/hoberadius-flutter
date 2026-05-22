class SystemStatus {
  const SystemStatus({
    required this.tenantId,
    required this.counts,
    required this.syncQueue,
    required this.webhooks,
    required this.workers,
    required this.routers,
    required this.vps,
    required this.now,
  });

  final int tenantId;
  final Map<String, int> counts;
  final Map<String, int> syncQueue;
  final Map<String, int> webhooks;
  final Map<String, dynamic> workers;
  final List<SystemRouterStatus> routers;
  final VpsStatus vps;
  final String now;

  factory SystemStatus.fromJson(Map<String, dynamic> json) {
    final routersRaw = _map(json['mt_routers']);
    final items = routersRaw['items'];
    return SystemStatus(
      tenantId: _int(json['tenant_id']),
      counts: _intMap(json['counts']),
      syncQueue: _intMap(json['sync_queue']),
      webhooks: _intMap(json['webhook_deliveries']),
      workers: _map(json['workers']),
      routers: items is List
          ? items
              .whereType<Map>()
              .map((e) => SystemRouterStatus.fromJson(_map(e)))
              .toList()
          : const [],
      vps: VpsStatus.fromJson(_map(json['vps'] ?? json['system'])),
      now: _string(json['now']),
    );
  }
}

class VpsStatus {
  const VpsStatus({
    required this.hostname,
    required this.platform,
    required this.processUptime,
    required this.systemUptime,
    required this.cpuPct,
    required this.cpuCount,
    required this.load,
    required this.memory,
    required this.disk,
    required this.network,
  });

  final String hostname;
  final String platform;
  final String processUptime;
  final String systemUptime;
  final double? cpuPct;
  final int cpuCount;
  final Map<String, double?> load;
  final ResourceUsage memory;
  final ResourceUsage disk;
  final NetworkProbe network;

  factory VpsStatus.fromJson(Map<String, dynamic> json) {
    return VpsStatus(
      hostname: _string(json['hostname']),
      platform: _string(json['platform']),
      processUptime: _string(json['process_uptime']),
      systemUptime: _string(json['system_uptime']),
      cpuPct: _double(json['cpu_pct']),
      cpuCount: _int(json['cpu_count']),
      load: {
        'one': _double(_map(json['load'])['one']),
        'five': _double(_map(json['load'])['five']),
        'fifteen': _double(_map(json['load'])['fifteen']),
      },
      memory: ResourceUsage.fromJson(_map(json['memory'])),
      disk: ResourceUsage.fromJson(_map(json['disk'])),
      network: NetworkProbe.fromJson(_map(json['network'])),
    );
  }
}

class ResourceUsage {
  const ResourceUsage({
    required this.percent,
    required this.totalHuman,
    required this.usedHuman,
    required this.availableHuman,
    required this.freeHuman,
    required this.path,
  });

  final double? percent;
  final String totalHuman;
  final String usedHuman;
  final String availableHuman;
  final String freeHuman;
  final String path;

  factory ResourceUsage.fromJson(Map<String, dynamic> json) {
    return ResourceUsage(
      percent: _double(json['percent']),
      totalHuman: _string(json['total_human']),
      usedHuman: _string(json['used_human']),
      availableHuman: _string(json['available_human']),
      freeHuman: _string(json['free_human']),
      path: _string(json['path']),
    );
  }
}

class NetworkProbe {
  const NetworkProbe({
    required this.pingHost,
    required this.pingOk,
    required this.pingMs,
    required this.dnsHost,
    required this.dnsOk,
    required this.dnsIp,
  });

  final String pingHost;
  final bool pingOk;
  final double? pingMs;
  final String dnsHost;
  final bool dnsOk;
  final String dnsIp;

  factory NetworkProbe.fromJson(Map<String, dynamic> json) {
    return NetworkProbe(
      pingHost: _string(json['ping_host']),
      pingOk: _bool(json['ping_ok']),
      pingMs: _double(json['ping_ms']),
      dnsHost: _string(json['dns_host']),
      dnsOk: _bool(json['dns_ok']),
      dnsIp: _string(json['dns_ip']),
    );
  }
}

class SystemRouterStatus {
  const SystemRouterStatus({
    required this.id,
    required this.name,
    required this.host,
    required this.enabled,
    required this.lastStatus,
    required this.lastSeenAt,
  });

  final int id;
  final String name;
  final String host;
  final bool enabled;
  final String lastStatus;
  final String lastSeenAt;

  factory SystemRouterStatus.fromJson(Map<String, dynamic> json) {
    return SystemRouterStatus(
      id: _int(json['id']),
      name: _string(json['name']),
      host: _string(json['host']),
      enabled: _bool(json['enabled']),
      lastStatus: _string(json['last_status']),
      lastSeenAt: _string(json['last_seen_at']),
    );
  }
}

class SystemDiagnostics {
  const SystemDiagnostics({required this.summary, required this.routers});

  final Map<String, int> summary;
  final List<DiagnosticRouter> routers;

  factory SystemDiagnostics.fromJson(Map<String, dynamic> json) {
    final routersRaw = json['routers'];
    return SystemDiagnostics(
      summary: _intMap(json['summary']),
      routers: routersRaw is List
          ? routersRaw
              .whereType<Map>()
              .map((e) => DiagnosticRouter.fromJson(_map(e)))
              .toList()
          : const [],
    );
  }
}

class DiagnosticRouter {
  const DiagnosticRouter({
    required this.name,
    required this.host,
    required this.status,
    required this.verdict,
    required this.hint,
  });

  final String name;
  final String host;
  final String status;
  final String verdict;
  final String hint;

  factory DiagnosticRouter.fromJson(Map<String, dynamic> json) {
    return DiagnosticRouter(
      name: _string(json['name']),
      host: _string(json['host']),
      status: _string(json['status']),
      verdict: _string(json['verdict']),
      hint: _string(json['hint']),
    );
  }
}

class SyncQueueState {
  const SyncQueueState({
    required this.items,
    required this.stats,
    required this.status,
  });

  final List<SyncJob> items;
  final Map<String, int> stats;
  final String status;

  factory SyncQueueState.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return SyncQueueState(
      items: raw is List
          ? raw.whereType<Map>().map((e) => SyncJob.fromJson(_map(e))).toList()
          : const [],
      stats: _intMap(json['stats']),
      status: _string(json['status']),
    );
  }
}

class SyncJob {
  const SyncJob({
    required this.id,
    required this.kind,
    required this.entityKey,
    required this.status,
    required this.attempts,
    required this.lastError,
    required this.createdAt,
    required this.nextAttemptAt,
  });

  final int id;
  final String kind;
  final String entityKey;
  final String status;
  final int attempts;
  final String lastError;
  final String createdAt;
  final String nextAttemptAt;

  factory SyncJob.fromJson(Map<String, dynamic> json) {
    return SyncJob(
      id: _int(json['id']),
      kind: _string(json['kind']),
      entityKey: _string(json['entity_key']),
      status: _string(json['status']),
      attempts: _int(json['attempts']),
      lastError: _string(json['last_error']),
      createdAt: _string(json['created_at']),
      nextAttemptAt: _string(json['next_attempt_at']),
    );
  }
}

class ReconcileResult {
  const ReconcileResult({required this.stats});

  final Map<String, dynamic> stats;

  factory ReconcileResult.fromJson(Map<String, dynamic> json) {
    return ReconcileResult(stats: _map(json['stats']));
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return const {};
}

Map<String, int> _intMap(Object? value) {
  final source = _map(value);
  return {
    for (final entry in source.entries) entry.key: _int(entry.value),
  };
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString()) ?? 0;
}

double? _double(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse((value ?? '').toString());
}

bool _bool(Object? value) {
  if (value is bool) return value;
  final text = (value ?? '').toString().trim().toLowerCase();
  return {'1', 'true', 'yes', 'on', 'enabled'}.contains(text);
}

String _string(Object? value) => (value ?? '').toString();
