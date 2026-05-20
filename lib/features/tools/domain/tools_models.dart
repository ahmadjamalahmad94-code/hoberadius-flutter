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
