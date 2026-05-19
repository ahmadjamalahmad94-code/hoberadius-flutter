class DashboardMetrics {
  DashboardMetrics({
    this.subscribers = 0,
    this.activeSubscribers = 0,
    this.onlineNow = 0,
    this.plans = 0,
    this.totalCards = 0,
    this.usedCards = 0,
    this.totalBatches = 0,
    this.nasDevices = 0,
    this.cpuPct,
    this.ramPct,
    this.diskPct,
    this.recentEvents = const [],
  });

  final int subscribers;
  final int activeSubscribers;
  final int onlineNow;
  final int plans;
  final int totalCards;
  final int usedCards;
  final int totalBatches;
  final int nasDevices;
  final double? cpuPct;
  final double? ramPct;
  final double? diskPct;
  final List<DashboardEvent> recentEvents;

  factory DashboardMetrics.fromJson(Map<String, dynamic> j) => DashboardMetrics(
        subscribers: _i(j['subscribers']),
        activeSubscribers: _i(j['active_subscribers']),
        onlineNow: _i(j['online_now']),
        plans: _i(j['plans']),
        totalCards: _i(j['total_cards']),
        usedCards: _i(j['used_cards']),
        totalBatches: _i(j['total_batches']),
        nasDevices: _i(j['nas_devices']),
        cpuPct: _d(j['cpu_pct']),
        ramPct: _d(j['ram_pct']),
        diskPct: _d(j['disk_pct']),
        recentEvents: ((j['recent'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(DashboardEvent.fromJson)
            .toList(),
      );

  static int _i(Object? v) =>
      v == null ? 0 : (v is int ? v : int.tryParse(v.toString()) ?? 0);
  static double? _d(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}

class DashboardEvent {
  DashboardEvent({required this.action, this.actor = '', this.targetType = '', this.at});
  final String action;
  final String actor;
  final String targetType;
  final DateTime? at;

  factory DashboardEvent.fromJson(Map<String, dynamic> j) => DashboardEvent(
        action: (j['action'] ?? '').toString(),
        actor: (j['actor'] ?? '').toString(),
        targetType: (j['target_type'] ?? '').toString(),
        at: _dt(j['at'] ?? j['created_at']),
      );

  static DateTime? _dt(Object? v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString().replaceAll('Z', ''));
    } catch (_) {
      return null;
    }
  }
}
