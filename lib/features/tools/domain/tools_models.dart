class ToolSpeedChange {
  const ToolSpeedChange({
    required this.planId,
    required this.name,
    required this.beforeDown,
    required this.beforeUp,
    required this.afterDown,
    required this.afterUp,
  });

  final int planId;
  final String name;
  final int beforeDown;
  final int beforeUp;
  final int afterDown;
  final int afterUp;

  factory ToolSpeedChange.fromJson(Map<String, dynamic> json) {
    final before = json['before'] is Map<String, dynamic>
        ? json['before'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final after = json['after'] is Map<String, dynamic>
        ? json['after'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return ToolSpeedChange(
      planId: _asInt(json['plan_id']),
      name: (json['name'] ?? '').toString(),
      beforeDown: _asInt(before['speed_down_kbps']),
      beforeUp: _asInt(before['speed_up_kbps']),
      afterDown: _asInt(after['speed_down_kbps']),
      afterUp: _asInt(after['speed_up_kbps']),
    );
  }
}

class SetSpeedsResult {
  const SetSpeedsResult({
    required this.dryRun,
    required this.changed,
    required this.matched,
    required this.changes,
  });

  final bool dryRun;
  final int changed;
  final int matched;
  final List<ToolSpeedChange> changes;

  factory SetSpeedsResult.fromJson(Map<String, dynamic> json) {
    final raw = json['changes'];
    return SetSpeedsResult(
      dryRun: json['dry_run'] == true,
      changed: _asInt(json['changed']),
      matched: _asInt(json['matched']),
      changes: raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map(ToolSpeedChange.fromJson)
              .toList()
          : const [],
    );
  }
}

class RadiusLogEntry {
  const RadiusLogEntry({
    required this.id,
    required this.authdate,
    required this.username,
    required this.reply,
    required this.nas,
    required this.reason,
    required this.ok,
  });

  final int id;
  final String authdate;
  final String username;
  final String reply;
  final String nas;
  final String reason;
  final bool ok;

  factory RadiusLogEntry.fromJson(Map<String, dynamic> json) {
    return RadiusLogEntry(
      id: _asInt(json['id']),
      authdate: (json['authdate'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      reply: (json['reply'] ?? '').toString(),
      nas: (json['nas'] ?? '').toString(),
      reason: (json['reason'] ?? '').toString(),
      ok: json['ok'] == true,
    );
  }
}

class RadiusLogSnapshot {
  const RadiusLogSnapshot({required this.items, required this.count});

  final List<RadiusLogEntry> items;
  final int count;

  factory RadiusLogSnapshot.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    return RadiusLogSnapshot(
      count: _asInt(json['count']),
      items: raw is List
          ? raw
              .whereType<Map<String, dynamic>>()
              .map(RadiusLogEntry.fromJson)
              .toList()
          : const [],
    );
  }
}

class AuthTestDecision {
  const AuthTestDecision({
    required this.ok,
    required this.reason,
    required this.message,
    required this.replyAttrs,
  });

  final bool ok;
  final String reason;
  final String message;
  final Map<String, dynamic> replyAttrs;

  factory AuthTestDecision.fromJson(Map<String, dynamic> json) {
    return AuthTestDecision(
      ok: json['ok'] == true,
      reason: (json['reason'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      replyAttrs: json['reply_attrs'] is Map<String, dynamic>
          ? json['reply_attrs'] as Map<String, dynamic>
          : const {},
    );
  }
}

class MaintenancePreview {
  const MaintenancePreview({
    required this.action,
    required this.days,
    required this.estimatedRows,
    required this.table,
    required this.destructive,
    required this.confirmPhrase,
    required this.confirmToken,
  });

  final String action;
  final int days;
  final int estimatedRows;
  final String table;
  final bool destructive;
  final String confirmPhrase;
  final String confirmToken;

  factory MaintenancePreview.fromJson(Map<String, dynamic> json) {
    return MaintenancePreview(
      action: (json['action'] ?? '').toString(),
      days: _asInt(json['days']),
      estimatedRows: _asInt(json['estimated_rows']),
      table: (json['table'] ?? '').toString(),
      destructive: json['destructive'] == true,
      confirmPhrase: (json['confirm_phrase'] ?? '').toString(),
      confirmToken: (json['confirm_token'] ?? '').toString(),
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse((value ?? '').toString()) ?? 0;
}

/// One account of a general-adjustments run/preview.
class AdjustmentItem {
  const AdjustmentItem({
    required this.username,
    required this.ok,
    this.status = '',
    this.message = '',
    this.newExpireAt = '',
  });

  final String username;
  final bool ok;

  /// ok | not_found | no_change (preview) …
  final String status;

  /// `error` (Arabic, real run) or `note`.
  final String message;
  final String newExpireAt;

  factory AdjustmentItem.fromJson(Map<String, dynamic> j) => AdjustmentItem(
        username: (j['username'] ?? '').toString(),
        ok: j['ok'] == true,
        status: (j['status'] ?? '').toString(),
        message: (j['error'] ?? j['note'] ?? '').toString(),
        newExpireAt: (j['new_expire_at'] ?? '').toString(),
      );

  String get statusLabel => switch (status) {
        'ok' => ok ? 'سينجح' : 'نجح',
        'not_found' => 'غير موجود',
        'no_change' => 'بلا تغيير',
        _ => ok ? 'نجح' : 'فشل',
      };
}

/// `/tools/general-adjustments` answer. Updated servers send a real preview
/// for `dry_run` (targets, not_found, would_succeed, would_fail, items[]);
/// older servers only the flat counters, kept in [raw].
class AdjustmentsReport {
  const AdjustmentsReport({
    required this.dryRun,
    this.targets,
    this.notFound = const [],
    this.wouldSucceed,
    this.wouldFail,
    this.items = const [],
    this.raw = const {},
  });

  final bool dryRun;
  final int? targets;
  final List<String> notFound;
  final int? wouldSucceed;
  final int? wouldFail;
  final List<AdjustmentItem> items;
  final Map<String, dynamic> raw;

  bool get hasDetails => items.isNotEmpty || targets != null;

  factory AdjustmentsReport.fromJson(Map<String, dynamic> j) {
    int? n(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');
    final nf = j['not_found'];
    final items = j['items'];
    return AdjustmentsReport(
      dryRun: j['dry_run'] == true,
      targets: n(
        j['targets'] is List ? (j['targets'] as List).length : j['targets'],
      ),
      notFound: nf is List ? nf.map((e) => '$e').toList() : const [],
      wouldSucceed: n(j['would_succeed']),
      wouldFail: n(j['would_fail']),
      items: items is List
          ? items
              .whereType<Map>()
              .map((m) => AdjustmentItem.fromJson(Map<String, dynamic>.from(m)))
              .toList()
          : const [],
      raw: j,
    );
  }
}
