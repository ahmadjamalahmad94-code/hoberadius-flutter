import 'card_parsing.dart';
import 'card_session.dart';

/// Top-level card-check payload returned by GET /api/cards/check/<query>.
class CardCheckResult {
  CardCheckResult({
    required this.exists,
    required this.status,
    this.query = '',
    this.id,
    this.username = '',
    this.hasPassword = false,
    this.used = false,
    this.revoked = false,
    this.lockedMac,
    this.disabledReason = '',
    this.createdAt,
    this.startedAt,
    this.expiresAt,
    this.remainingSeconds,
    this.batch,
    this.profile,
    this.assignedTo,
    this.lastSeenAt,
    this.macAddress,
    this.ipAddress,
    this.nasAddress,
    this.activeSession,
    this.lastSessionSeconds,
    CardOperations? operations,
    CardAccountingSummary? accountingSummary,
    List<String>? dataSources,
    List<String>? availableFields,
    List<String>? missingFields,
  })  : operations = operations ?? CardOperations(),
        accountingSummary = accountingSummary ?? CardAccountingSummary(),
        dataSources = dataSources ?? const [],
        availableFields = availableFields ?? const [],
        missingFields = missingFields ?? const [];

  final bool exists;
  final String status;
  final String query;
  final int? id;
  final String username;
  final bool hasPassword;
  final bool used;
  final bool revoked;
  final String? lockedMac;
  final String disabledReason;
  final DateTime? createdAt;
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final int? remainingSeconds;
  final CardCheckBatch? batch;
  final CardCheckProfile? profile;
  final CardAssignedTo? assignedTo;
  final DateTime? lastSeenAt;
  final String? macAddress;
  final String? ipAddress;
  final String? nasAddress;
  final bool? activeSession;
  final int? lastSessionSeconds;
  final CardOperations operations;
  final CardAccountingSummary accountingSummary;
  final List<String> dataSources;
  final List<String> availableFields;
  final List<String> missingFields;

  factory CardCheckResult.fromJson(Map<String, dynamic> json) {
    final batch = json['batch'];
    final profile = json['profile'];
    final assignedTo = json['assigned_to'];
    return CardCheckResult(
      exists: cardParseBool(json['exists']),
      status: (json['status'] ?? 'unknown').toString(),
      query: (json['query'] ?? '').toString(),
      id: cardParseInt(json['id']),
      username: (json['username'] ?? '').toString(),
      hasPassword: cardParseBool(json['has_password']),
      used: cardParseBool(json['used']),
      revoked: cardParseBool(json['revoked']),
      lockedMac: cardParseStringOrNull(json['locked_mac']),
      disabledReason: (json['disabled_reason'] ?? '').toString(),
      createdAt: cardParseDate(json['created_at']),
      startedAt: cardParseDate(json['started_at']),
      expiresAt: cardParseDate(json['expires_at']),
      remainingSeconds: cardParseInt(json['remaining_seconds']),
      batch: batch is Map<String, dynamic>
          ? CardCheckBatch.fromJson(batch)
          : null,
      profile: profile is Map<String, dynamic>
          ? CardCheckProfile.fromJson(profile)
          : null,
      assignedTo: assignedTo is Map<String, dynamic>
          ? CardAssignedTo.fromJson(assignedTo)
          : null,
      lastSeenAt: cardParseDate(json['last_seen_at']),
      macAddress: cardParseStringOrNull(json['mac_address']),
      ipAddress: cardParseStringOrNull(json['ip_address']),
      nasAddress: cardParseStringOrNull(json['nas_address']),
      activeSession: json.containsKey('active_session')
          ? cardParseBool(json['active_session'])
          : null,
      lastSessionSeconds: cardParseInt(json['last_session_seconds']),
      operations: json['operations'] is Map<String, dynamic>
          ? CardOperations.fromJson(json['operations'] as Map<String, dynamic>)
          : CardOperations(),
      accountingSummary: json['accounting_summary'] is Map<String, dynamic>
          ? CardAccountingSummary.fromJson(
              json['accounting_summary'] as Map<String, dynamic>,
            )
          : CardAccountingSummary(),
      dataSources: cardParseStringList(json['data_sources']),
      availableFields: cardParseStringList(json['available_fields']),
      missingFields: cardParseStringList(json['missing_fields']),
    );
  }
}

class CardCheckBatch {
  CardCheckBatch({
    this.id,
    this.batchCode = '',
    this.packageName = '',
    this.status = '',
    this.count = 0,
    this.generated = 0,
    this.used = 0,
    this.managerId,
    this.createdBy,
    this.createdAt,
    this.expiresAt,
    this.deletedAt,
  });

  final int? id;
  final String batchCode;
  final String packageName;
  final String status;
  final int count;
  final int generated;
  final int used;
  final int? managerId;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final DateTime? deletedAt;

  factory CardCheckBatch.fromJson(Map<String, dynamic> json) => CardCheckBatch(
        id: cardParseInt(json['id']),
        batchCode: (json['batch_code'] ?? '').toString(),
        packageName: (json['package_name'] ?? '').toString(),
        status: (json['status'] ?? '').toString(),
        count: cardParseInt(json['count']) ?? 0,
        generated: cardParseInt(json['generated']) ?? 0,
        used: cardParseInt(json['used']) ?? 0,
        managerId: cardParseInt(json['manager_id']),
        createdBy: cardParseStringOrNull(json['created_by']),
        createdAt: cardParseDate(json['created_at']),
        expiresAt: cardParseDate(json['expires_at']),
        deletedAt: cardParseDate(json['deleted_at']),
      );
}

class CardCheckProfile {
  CardCheckProfile({
    this.id,
    this.name = '',
    this.code = '',
    this.serviceType,
    this.planType,
    this.speedDownKbps,
    this.speedUpKbps,
    this.quotaTotalMb,
    this.quotaDailyMb,
    this.quotaMonthlyMb,
    this.durationMinutes,
    this.validityDays,
  });

  final int? id;
  final String name;
  final String code;
  final String? serviceType;
  final String? planType;
  final int? speedDownKbps;
  final int? speedUpKbps;
  final int? quotaTotalMb;
  final int? quotaDailyMb;
  final int? quotaMonthlyMb;
  final int? durationMinutes;
  final int? validityDays;

  factory CardCheckProfile.fromJson(Map<String, dynamic> json) =>
      CardCheckProfile(
        id: cardParseInt(json['id']),
        name: (json['name'] ?? '').toString(),
        code: (json['code'] ?? '').toString(),
        serviceType: cardParseStringOrNull(json['service_type']),
        planType: cardParseStringOrNull(json['plan_type']),
        speedDownKbps: cardParseInt(json['speed_down_kbps']),
        speedUpKbps: cardParseInt(json['speed_up_kbps']),
        quotaTotalMb: cardParseInt(json['quota_total_mb']),
        quotaDailyMb: cardParseInt(json['quota_daily_mb']),
        quotaMonthlyMb: cardParseInt(json['quota_monthly_mb']),
        durationMinutes: cardParseInt(json['duration_minutes']),
        validityDays: cardParseInt(json['validity_days']),
      );
}

class CardAssignedTo {
  CardAssignedTo({
    this.subscriberId,
    this.username = '',
    this.fullName = '',
    this.mobile = '',
    this.status,
  });

  final int? subscriberId;
  final String username;
  final String fullName;
  final String mobile;
  final String? status;

  factory CardAssignedTo.fromJson(Map<String, dynamic> json) => CardAssignedTo(
        subscriberId: cardParseInt(json['subscriber_id']),
        username: (json['username'] ?? '').toString(),
        fullName: (json['full_name'] ?? '').toString(),
        mobile: (json['mobile'] ?? '').toString(),
        status: cardParseStringOrNull(json['status']),
      );
}

class CardOperations {
  CardOperations({
    this.canDisconnect = false,
    this.canLockMac = false,
    this.canResetUsage = false,
    this.canDisable = false,
    this.canEnable = false,
    this.canDeletePermanently = false,
  });

  final bool canDisconnect;
  final bool canLockMac;
  final bool canResetUsage;
  final bool canDisable;
  final bool canEnable;
  final bool canDeletePermanently;

  factory CardOperations.fromJson(Map<String, dynamic> json) => CardOperations(
        canDisconnect: cardParseBool(json['can_disconnect']),
        canLockMac: cardParseBool(json['can_lock_mac']),
        canResetUsage: cardParseBool(json['can_reset_usage']),
        canDisable: cardParseBool(json['can_disable']),
        canEnable: cardParseBool(json['can_enable']),
        canDeletePermanently: cardParseBool(json['can_delete_permanently']),
      );
}
