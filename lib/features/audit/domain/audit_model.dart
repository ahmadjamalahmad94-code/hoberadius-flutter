class AuditEvent {
  AuditEvent({
    this.id,
    required this.actor,
    required this.action,
    this.targetType = '',
    this.targetId = '',
    this.ipAddress = '',
    this.userAgent = '',
    this.payload = const {},
    this.createdAt,
  });

  final int? id;
  final String actor;
  final String action;
  final String targetType;
  final String targetId;
  final String ipAddress;
  final String userAgent;
  final Map<String, dynamic> payload;
  final DateTime? createdAt;

  factory AuditEvent.fromJson(Map<String, dynamic> j) => AuditEvent(
        id: j['id'] as int?,
        actor: (j['actor'] ?? '').toString(),
        action: (j['action'] ?? '').toString(),
        targetType: (j['target_type'] ?? '').toString(),
        targetId: (j['target_id'] ?? '').toString(),
        ipAddress: (j['ip_address'] ?? '').toString(),
        userAgent: (j['user_agent'] ?? '').toString(),
        payload: (j['payload'] is Map<String, dynamic>)
            ? j['payload'] as Map<String, dynamic>
            : const {},
        createdAt: _dt(j['created_at']),
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
