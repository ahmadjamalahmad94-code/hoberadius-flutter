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

  factory DashboardMetrics.fromJson(Map<String, dynamic> j) {
    final subscribersMap = _m(j['subscribers']);
    final cardsMap = _m(j['cards']);
    final plansMap = _m(j['plans']);
    final nasMap = _m(j['nas']);
    final systemMap = _m(j['system']);
    return DashboardMetrics(
      subscribers: subscribersMap == null
          ? _i(j['subscribers'])
          : _i(subscribersMap['total']),
      activeSubscribers: _firstInt([
        j['active_subscribers'],
        subscribersMap?['active'],
        subscribersMap?['enabled'],
      ]),
      onlineNow: _firstInt([
        j['online_now'],
        subscribersMap?['online'],
        j['online'],
      ]),
      plans: plansMap == null ? _i(j['plans']) : _i(plansMap['total']),
      totalCards: _firstInt([j['total_cards'], cardsMap?['total']]),
      usedCards: _firstInt([j['used_cards'], cardsMap?['used']]),
      totalBatches: _firstInt([j['total_batches'], cardsMap?['batches']]),
      nasDevices: _firstInt([j['nas_devices'], nasMap?['total']]),
      cpuPct: _firstDouble([j['cpu_pct'], systemMap?['cpu_pct']]),
      ramPct: _firstDouble([j['ram_pct'], systemMap?['ram_pct']]),
      diskPct: _firstDouble([j['disk_pct'], systemMap?['disk_pct']]),
      recentEvents:
          ((j['recent'] ?? j['audit'] ?? const []) as List? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(DashboardEvent.fromJson)
              .toList(),
    );
  }

  static int _i(Object? v) =>
      v == null ? 0 : (v is int ? v : int.tryParse(v.toString()) ?? 0);
  static int _firstInt(List<Object?> values) {
    for (final value in values) {
      if (value != null) return _i(value);
    }
    return 0;
  }

  static double? _d(Object? v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static double? _firstDouble(List<Object?> values) {
    for (final value in values) {
      final parsed = _d(value);
      if (parsed != null) return parsed;
    }
    return null;
  }

  static Map<String, dynamic>? _m(Object? v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }
}

class DashboardEvent {
  DashboardEvent({
    required this.action,
    this.actor = '',
    this.targetType = '',
    this.at,
  });
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
