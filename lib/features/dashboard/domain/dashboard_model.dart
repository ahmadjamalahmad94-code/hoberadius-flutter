/// Dashboard aggregate model.
///
/// Mirrors the payload produced by the web service
/// `radius/services/dashboard_metrics.build_dashboard_metrics` and exposed
/// verbatim by `GET /api/v1/dashboard` (see `app/api/v1/dashboard.py`):
///
/// ```json
/// { "subscribers": {...}, "cards": {...}, "plans": {...}, "nas": {...},
///   "system": {...}, "alerts": [...], "recent_batches": [...] }
/// ```
///
/// Historically this model read `recent`/`audit` for an activity feed, but the
/// API never returns those keys — it returns `recent_batches` (latest card
/// batches) and `alerts` (the "ما يحتاج انتباه" panel). Those are now parsed.
class DashboardMetrics {
  DashboardMetrics({
    this.subscribers = 0,
    this.activeSubscribers = 0,
    this.onlineNow = 0,
    this.expiredSubscribers = 0,
    this.expiringSoon = 0,
    this.suspendedSubscribers = 0,
    this.disabledSubscribers = 0,
    this.bannedSubscribers = 0,
    this.plans = 0,
    this.enabledPlans = 0,
    this.disabledPlans = 0,
    this.topPlanName = '',
    this.topPlanSubs = 0,
    this.totalCards = 0,
    this.usedCards = 0,
    this.availableCards = 0,
    this.totalBatches = 0,
    this.nasDevices = 0,
    this.nasEnabled = 0,
    this.cpuPct,
    this.ramPct,
    this.diskPct,
    this.systemUptime = '',
    this.processUptime = '',
    this.hostname = '',
    this.pingOk,
    this.pingMs,
    this.dnsOk,
    this.dbOk,
    this.radiusOk,
    this.recentBatches = const [],
    this.alerts = const [],
  });

  final int subscribers;
  final int activeSubscribers;
  final int onlineNow;
  final int expiredSubscribers;
  final int expiringSoon;
  final int suspendedSubscribers;
  final int disabledSubscribers;
  final int bannedSubscribers;
  final int plans;
  final int enabledPlans;
  final int disabledPlans;
  final String topPlanName;
  final int topPlanSubs;
  final int totalCards;
  final int usedCards;
  final int availableCards;
  final int totalBatches;
  final int nasDevices;
  final int nasEnabled;
  final double? cpuPct;
  final double? ramPct;
  final double? diskPct;
  final String systemUptime;
  final String processUptime;
  final String hostname;
  final bool? pingOk;
  final double? pingMs;
  final bool? dnsOk;
  final bool? dbOk;
  final bool? radiusOk;
  final List<RecentBatch> recentBatches;
  final List<DashboardAlert> alerts;

  bool get hasTopPlan => topPlanName.isNotEmpty;

  factory DashboardMetrics.fromJson(Map<String, dynamic> j) {
    final subscribersMap = _m(j['subscribers']);
    final cardsMap = _m(j['cards']);
    final plansMap = _m(j['plans']);
    final topPlanMap = _m(plansMap?['top']);
    final nasMap = _m(j['nas']);
    final systemMap = _m(j['system']);
    final networkMap = _m(systemMap?['network']);
    return DashboardMetrics(
      subscribers: subscribersMap == null
          ? _firstInt([j['subscribers'], j['total_subscribers']])
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
      expiredSubscribers: _i(subscribersMap?['expired']),
      expiringSoon: _i(subscribersMap?['expiring_soon']),
      suspendedSubscribers: _i(subscribersMap?['suspended']),
      disabledSubscribers: _i(subscribersMap?['disabled']),
      bannedSubscribers: _i(subscribersMap?['banned']),
      plans: plansMap == null
          ? _firstInt([j['plans'], j['plans_total'], j['profiles_total']])
          : _i(plansMap['total']),
      enabledPlans: _i(plansMap?['enabled']),
      disabledPlans: _i(plansMap?['disabled']),
      topPlanName: (topPlanMap?['name'] ?? '').toString(),
      topPlanSubs: _i(topPlanMap?['subs']),
      totalCards: _firstInt([
        j['total_cards'],
        j['cards_total'],
        cardsMap?['total'],
      ]),
      usedCards: _firstInt([j['used_cards'], cardsMap?['used']]),
      availableCards: _firstInt([j['available_cards'], cardsMap?['available']]),
      totalBatches: _firstInt([
        j['total_batches'],
        j['batches_total'],
        cardsMap?['batches'],
      ]),
      nasDevices:
          _firstInt([j['nas_devices'], j['nas_total'], nasMap?['total']]),
      nasEnabled: _i(nasMap?['enabled']),
      cpuPct: _firstDouble([j['cpu_pct'], systemMap?['cpu_pct']]),
      ramPct: _firstDouble([j['ram_pct'], systemMap?['ram_pct']]),
      diskPct: _firstDouble([j['disk_pct'], systemMap?['disk_pct']]),
      systemUptime: (systemMap?['system_uptime'] ?? '').toString(),
      processUptime: (systemMap?['process_uptime'] ?? '').toString(),
      hostname: (systemMap?['hostname'] ?? '').toString(),
      pingOk: _b(networkMap?['ping_ok']),
      pingMs: _d(networkMap?['ping_ms']),
      dnsOk: _b(networkMap?['dns_ok']),
      dbOk: _b(systemMap?['db_ok']),
      radiusOk: _b(systemMap?['radius_ok']),
      recentBatches: ((j['recent_batches'] ?? const []) as List? ?? const [])
          .whereType<Map>()
          .map((e) => RecentBatch.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      alerts: ((j['alerts'] ?? const []) as List? ?? const [])
          .whereType<Map>()
          .map((e) => DashboardAlert.fromJson(Map<String, dynamic>.from(e)))
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

  static bool? _b(Object? v) {
    if (v == null) return null;
    if (v is bool) return v;
    final text = v.toString().trim().toLowerCase();
    if (text == 'true' || text == '1' || text == 'yes') return true;
    if (text == 'false' || text == '0' || text == 'no') return false;
    return null;
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

/// One row of the "آخر الحزم" (latest card batches) panel.
/// Mirrors `get_recent_batches` columns:
/// `id, batch_code, package_name, count, generated, used`.
class RecentBatch {
  RecentBatch({
    this.id = 0,
    this.batchCode = '',
    this.packageName = '',
    this.count = 0,
    this.generated = 0,
    this.used = 0,
  });

  final int id;
  final String batchCode;
  final String packageName;
  final int count;
  final int generated;
  final int used;

  /// Total cards in the batch — `count` with `generated` fallback,
  /// matching the web template `batch.count or batch.generated or 0`.
  int get total => count > 0 ? count : generated;

  factory RecentBatch.fromJson(Map<String, dynamic> j) => RecentBatch(
        id: DashboardMetrics._i(j['id']),
        batchCode: (j['batch_code'] ?? '').toString(),
        packageName: (j['package_name'] ?? '').toString(),
        count: DashboardMetrics._i(j['count']),
        generated: DashboardMetrics._i(j['generated']),
        used: DashboardMetrics._i(j['used']),
      );
}

enum DashboardAlertLevel { danger, warn, info }

/// One operational alert from the "ما يحتاج انتباه" panel.
/// Mirrors `build_alerts` items: `{level, message, link_endpoint?, link_args?}`.
class DashboardAlert {
  DashboardAlert({
    required this.level,
    required this.message,
    this.linkEndpoint = '',
    this.linkArgs = const {},
  });

  final DashboardAlertLevel level;
  final String message;
  final String linkEndpoint;
  final Map<String, dynamic> linkArgs;

  factory DashboardAlert.fromJson(Map<String, dynamic> j) {
    final args = DashboardMetrics._m(j['link_args']);
    return DashboardAlert(
      level: _level((j['level'] ?? '').toString()),
      message: (j['message'] ?? '').toString(),
      linkEndpoint: (j['link_endpoint'] ?? '').toString(),
      linkArgs: args ?? const {},
    );
  }

  static DashboardAlertLevel _level(String value) {
    switch (value.trim().toLowerCase()) {
      case 'danger':
        return DashboardAlertLevel.danger;
      case 'warn':
      case 'warning':
        return DashboardAlertLevel.warn;
      default:
        return DashboardAlertLevel.info;
    }
  }
}
