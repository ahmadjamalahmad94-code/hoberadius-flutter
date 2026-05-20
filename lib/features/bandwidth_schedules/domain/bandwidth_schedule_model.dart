class BandwidthSchedule {
  const BandwidthSchedule({
    required this.id,
    required this.planId,
    required this.targetType,
    required this.subscriberUsername,
    required this.cardBatchId,
    required this.priority,
    required this.name,
    required this.startsAtTime,
    required this.endsAtTime,
    required this.speedDownKbps,
    required this.speedUpKbps,
    required this.cirDownKbps,
    required this.cirUpKbps,
    required this.restoreMode,
    required this.enabled,
    required this.notes,
    required this.createdAt,
  });

  final int id;
  final int planId;
  final String targetType;
  final String subscriberUsername;
  final int? cardBatchId;
  final int priority;
  final String name;
  final String startsAtTime;
  final String endsAtTime;
  final int speedDownKbps;
  final int speedUpKbps;
  final int cirDownKbps;
  final int cirUpKbps;
  final String restoreMode;
  final bool enabled;
  final String notes;
  final DateTime? createdAt;

  factory BandwidthSchedule.fromJson(Map<String, dynamic> json) {
    return BandwidthSchedule(
      id: _asInt(json['id']),
      planId: _asInt(json['plan_id']),
      targetType: (json['target_type'] ?? 'plan').toString(),
      subscriberUsername: (json['subscriber_username'] ?? '').toString(),
      cardBatchId: _nullableInt(json['card_batch_id']),
      priority: _asInt(json['priority'], fallback: 100),
      name: (json['name'] ?? '').toString(),
      startsAtTime: (json['starts_at_time'] ?? '').toString(),
      endsAtTime: (json['ends_at_time'] ?? '').toString(),
      speedDownKbps: _asInt(json['speed_down_kbps']),
      speedUpKbps: _asInt(json['speed_up_kbps']),
      cirDownKbps: _asInt(json['cir_down_kbps']),
      cirUpKbps: _asInt(json['cir_up_kbps']),
      restoreMode: (json['restore_mode'] ?? 'profile_default').toString(),
      enabled: _asBool(json['enabled']),
      notes: (json['notes'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
    );
  }
}

class BandwidthApplyResult {
  const BandwidthApplyResult({
    required this.appliedToRadius,
    required this.message,
    required this.schedule,
  });

  final bool appliedToRadius;
  final String message;
  final BandwidthSchedule? schedule;

  factory BandwidthApplyResult.fromJson(Map<String, dynamic> json) {
    final log = json['log'];
    return BandwidthApplyResult(
      appliedToRadius: _asBool(json['applied_to_radius']),
      message: log is Map
          ? (log['message'] ?? '').toString()
          : (json['message'] ?? '').toString(),
      schedule: json['schedule'] is Map<String, dynamic>
          ? BandwidthSchedule.fromJson(json['schedule'] as Map<String, dynamic>)
          : json['schedule'] is Map
              ? BandwidthSchedule.fromJson(
                  (json['schedule'] as Map).map(
                    (key, value) => MapEntry(key.toString(), value),
                  ),
                )
              : null,
    );
  }
}

int _asInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int? _nullableInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool _asBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().toLowerCase() ?? '';
  return text == 'true' || text == '1' || text == 'yes' || text == 'on';
}
