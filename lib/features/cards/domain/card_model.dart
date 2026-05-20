class CardBatch {
  CardBatch({
    this.id,
    this.batchCode = '',
    this.planId,
    this.count = 0,
    this.generated = 0,
    this.used = 0,
    this.status = 'active',
    this.packageName = '',
    this.serviceName = '',
    this.notes = '',
    this.expireAt,
    this.createdAt,
    this.createdBy = '',
    this.usernamePrefix = '',
    this.usernameSuffix = '',
    this.usernameLength = 8,
    this.passwordLength = 6,
    this.passwordCharset = 'digits',
    this.includeBatchNumber = false,
    this.passwordGenerationType = 'medium',
    this.randomGenerationEnabled = true,
    this.startsWithOrEndsWith = '',
    this.prefixOrSuffixValue = '',
    this.timeValue = 0,
    this.timeUnit = 'days',
    this.deviceCount = 1,
    this.durationMode = 'time_unit',
    this.validityAfterFirstLoginDays = 0,
    this.countBySeconds = false,
    this.countFromFirstConnect = true,
    this.onQuotaExhaust = 'stop',
    this.autoRenewAfterFirstUse = false,
    this.switchToMacOnConnect = false,
    this.lockToMacOnClose = false,
    this.phoneOnlyLogin = false,
    this.pricePerCard = 0,
    this.priceBulk = 0,
    this.totalPrice = 0,
    this.totalQuotaMb = 0,
    this.managerId = 0,
    this.distributorId,
    this.distributorName = '',
    this.distributorDisplayName = '',
    this.planName = '',
    this.planCurrency = '',
    this.planSpeedDownKbps,
    this.planSpeedUpKbps,
    this.operationalStatus = '',
    this.availableCount = 0,
    this.activeCount = 0,
    this.expiredCount = 0,
    this.revokedCount = 0,
    this.remainingCount = 0,
    this.sessionsCount = 0,
    this.uniqueMacs = 0,
    this.onlineSessions = 0,
    this.speedRulesCount = 0,
    this.activeSpeedRules = 0,
    this.estimatedUnitPrice = 0,
  });

  final int? id;
  final String batchCode;
  final int? planId;
  final int count;
  final int generated;
  final int used;
  final String status;
  final String packageName;
  final String serviceName;
  final String notes;
  final DateTime? expireAt;
  final DateTime? createdAt;
  final String createdBy;
  final String usernamePrefix;
  final String usernameSuffix;
  final int usernameLength;
  final int passwordLength;
  final String passwordCharset;
  final bool includeBatchNumber;
  final String passwordGenerationType;
  final bool randomGenerationEnabled;
  final String startsWithOrEndsWith;
  final String prefixOrSuffixValue;
  final int timeValue;
  final String timeUnit;
  final int deviceCount;
  final String durationMode;
  final int validityAfterFirstLoginDays;
  final bool countBySeconds;
  final bool countFromFirstConnect;
  final String onQuotaExhaust;
  final bool autoRenewAfterFirstUse;
  final bool switchToMacOnConnect;
  final bool lockToMacOnClose;
  final bool phoneOnlyLogin;
  final num pricePerCard;
  final num priceBulk;
  final num totalPrice;
  final int totalQuotaMb;
  final int managerId;
  final int? distributorId;
  final String distributorName;
  final String distributorDisplayName;
  final String planName;
  final String planCurrency;
  final int? planSpeedDownKbps;
  final int? planSpeedUpKbps;
  final String operationalStatus;
  final int availableCount;
  final int activeCount;
  final int expiredCount;
  final int revokedCount;
  final int remainingCount;
  final int sessionsCount;
  final int uniqueMacs;
  final int onlineSessions;
  final int speedRulesCount;
  final int activeSpeedRules;
  final num estimatedUnitPrice;

  int get available => availableCount;

  num get estimatedValue {
    if (totalPrice > 0) return totalPrice;
    return estimatedUnitPrice * (generated > 0 ? generated : count);
  }

  String get displayName {
    if (packageName.isNotEmpty) return packageName;
    if (planName.isNotEmpty) return planName;
    return batchCode;
  }

  String get displayStatus =>
      operationalStatus.isNotEmpty ? operationalStatus : status;

  factory CardBatch.fromJson(Map<String, dynamic> j) => CardBatch(
        id: j['id'] as int?,
        batchCode: (j['batch_code'] ?? '').toString(),
        planId: j['plan_id'] as int?,
        count: _int(j['count']) ?? 0,
        generated: _int(j['generated']) ?? 0,
        used: _int(j['used']) ?? 0,
        status: (j['status'] ?? 'active').toString(),
        packageName: (j['package_name'] ?? '').toString(),
        serviceName: (j['service_name'] ?? '').toString(),
        notes: (j['notes'] ?? '').toString(),
        expireAt: _parseDt(j['expire_at']),
        createdAt: _parseDt(j['created_at']),
        createdBy: (j['created_by'] ?? '').toString(),
        usernamePrefix: (j['username_prefix'] ?? '').toString(),
        usernameSuffix: (j['username_suffix'] ?? '').toString(),
        usernameLength: _int(j['username_length']) ?? 8,
        passwordLength: _int(j['password_length']) ?? 6,
        passwordCharset: (j['password_charset'] ?? 'digits').toString(),
        includeBatchNumber: _bool(j['include_batch_number']),
        passwordGenerationType:
            (j['password_generation_type'] ?? 'medium').toString(),
        randomGenerationEnabled: j.containsKey('random_generation_enabled')
            ? _bool(j['random_generation_enabled'])
            : true,
        startsWithOrEndsWith: (j['starts_with_or_ends_with'] ?? '').toString(),
        prefixOrSuffixValue: (j['prefix_or_suffix_value'] ?? '').toString(),
        timeValue: _int(j['time_value']) ?? 0,
        timeUnit: (j['time_unit'] ?? 'days').toString(),
        deviceCount: _int(j['device_count']) ?? 1,
        durationMode: (j['duration_mode'] ?? 'time_unit').toString(),
        validityAfterFirstLoginDays:
            _int(j['validity_after_first_login_days']) ?? 0,
        countBySeconds: _bool(j['count_by_seconds']),
        countFromFirstConnect: j.containsKey('count_from_first_connect')
            ? _bool(j['count_from_first_connect'])
            : true,
        onQuotaExhaust: (j['on_quota_exhaust'] ?? 'stop').toString(),
        autoRenewAfterFirstUse: _bool(j['auto_renew_after_first_use']),
        switchToMacOnConnect: _bool(j['switch_to_mac_on_connect']),
        lockToMacOnClose: _bool(j['lock_to_mac_on_close']),
        phoneOnlyLogin: _bool(j['phone_only_login']),
        pricePerCard: _num(j['price_per_card']) ?? 0,
        priceBulk: _num(j['price_bulk']) ?? 0,
        totalPrice: _num(j['total_price']) ?? 0,
        totalQuotaMb: _int(j['total_quota_mb']) ?? 0,
        managerId: _int(j['manager_id']) ?? 0,
        distributorId: _int(j['distributor_id']),
        distributorName: (j['distributor_name'] ?? '').toString(),
        distributorDisplayName:
            (j['distributor_display_name'] ?? '').toString(),
        planName: (j['plan_name'] ?? '').toString(),
        planCurrency: (j['plan_currency'] ?? '').toString(),
        planSpeedDownKbps: _int(j['plan_speed_down_kbps']),
        planSpeedUpKbps: _int(j['plan_speed_up_kbps']),
        operationalStatus: (j['operational_status'] ?? '').toString(),
        availableCount: _int(j['available_count']) ?? _availableFallback(j),
        activeCount: _int(j['active_count']) ?? 0,
        expiredCount: _int(j['expired_count']) ?? 0,
        revokedCount: _int(j['revoked_count']) ?? 0,
        remainingCount: _int(j['remaining_count']) ?? _availableFallback(j),
        sessionsCount: _int(j['sessions_count']) ?? 0,
        uniqueMacs: _int(j['unique_macs']) ?? 0,
        onlineSessions: _int(j['online_sessions']) ?? 0,
        speedRulesCount: _int(j['speed_rules_count']) ?? 0,
        activeSpeedRules: _int(j['active_speed_rules']) ?? 0,
        estimatedUnitPrice: _num(j['estimated_unit_price']) ?? 0,
      );

  static int? _int(Object? v) =>
      v == null ? null : (v is int ? v : int.tryParse(v.toString()));

  static num? _num(Object? v) {
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse(v.toString());
  }

  static int _availableFallback(Map<String, dynamic> j) {
    final total = _int(j['count']) ?? 0;
    final consumed = _int(j['used']) ?? 0;
    return (total - consumed).clamp(0, total).toInt();
  }

  static bool _bool(Object? v) =>
      v == true || v == 1 || v == '1' || v == 'true' || v == 'on';

  static DateTime? _parseDt(Object? v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString().replaceAll('Z', ''));
    } catch (_) {
      return null;
    }
  }
}

class CardBatchOperationsPage {
  CardBatchOperationsPage({
    required this.items,
    required this.totals,
    this.total = 0,
    this.count = 0,
    this.page = 1,
    this.perPage = 25,
    this.pages = 1,
  });

  final List<CardBatch> items;
  final CardBatchOperationsTotals totals;
  final int total;
  final int count;
  final int page;
  final int perPage;
  final int pages;

  factory CardBatchOperationsPage.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;
    return CardBatchOperationsPage(
      items: (data['items'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CardBatch.fromJson)
          .toList(),
      totals: CardBatchOperationsTotals.fromJson(
        data['totals'] is Map<String, dynamic>
            ? data['totals'] as Map<String, dynamic>
            : const {},
      ),
      total: _intValue(data['total']) ?? 0,
      count: _intValue(data['count']) ?? 0,
      page: _intValue(data['page']) ?? 1,
      perPage: _intValue(data['per_page']) ?? 25,
      pages: _intValue(data['pages']) ?? 1,
    );
  }
}

class CardBatchOperationsTotals {
  CardBatchOperationsTotals({
    this.batchCount = 0,
    this.configuredValue = 0,
    this.usedToday = 0,
    this.usedMonth = 0,
    this.usedYear = 0,
    this.valueToday = 0,
    this.valueMonth = 0,
    this.valueYear = 0,
  });

  final int batchCount;
  final num configuredValue;
  final int usedToday;
  final int usedMonth;
  final int usedYear;
  final num valueToday;
  final num valueMonth;
  final num valueYear;

  factory CardBatchOperationsTotals.fromJson(Map<String, dynamic> json) =>
      CardBatchOperationsTotals(
        batchCount: _intValue(json['batch_count']) ?? 0,
        configuredValue: _numValue(json['configured_value']) ?? 0,
        usedToday: _intValue(json['used_today']) ?? 0,
        usedMonth: _intValue(json['used_month']) ?? 0,
        usedYear: _intValue(json['used_year']) ?? 0,
        valueToday: _numValue(json['value_today']) ?? 0,
        valueMonth: _numValue(json['value_month']) ?? 0,
        valueYear: _numValue(json['value_year']) ?? 0,
      );
}

class CardBatchBulkResult {
  CardBatchBulkResult({
    this.action = '',
    this.requested = 0,
    this.changed = 0,
    this.batchIds = const [],
  });

  final String action;
  final int requested;
  final int changed;
  final List<int> batchIds;

  factory CardBatchBulkResult.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;
    return CardBatchBulkResult(
      action: (data['action'] ?? '').toString(),
      requested: _intValue(data['requested']) ?? 0,
      changed: _intValue(data['changed']) ?? 0,
      batchIds: (data['batch_ids'] as List? ?? const [])
          .map(_intValue)
          .whereType<int>()
          .toList(),
    );
  }
}

class CardItem {
  CardItem({
    this.id,
    required this.username,
    this.password = '',
    this.batchId,
    this.planId,
    this.used = false,
    this.revoked = false,
    this.expireAt,
    this.firstUsedAt,
    this.createdAt,
  });

  final int? id;
  final String username;
  final String password;
  final int? batchId;
  final int? planId;
  final bool used;
  final bool revoked;
  final DateTime? expireAt;
  final DateTime? firstUsedAt;
  final DateTime? createdAt;

  factory CardItem.fromJson(Map<String, dynamic> j) => CardItem(
        id: j['id'] as int?,
        username: (j['username'] ?? '').toString(),
        password: (j['password'] ?? '').toString(),
        batchId: j['batch_id'] as int?,
        planId: j['plan_id'] as int?,
        used: j['used'] == true || j['used'] == 1,
        revoked: j['revoked'] == true || j['revoked'] == 1,
        expireAt: _parseDt(j['expire_at']),
        firstUsedAt: _parseDt(j['first_used_at']),
        createdAt: _parseDt(j['created_at']),
      );

  static DateTime? _parseDt(Object? v) {
    if (v == null) return null;
    try {
      return DateTime.parse(v.toString().replaceAll('Z', ''));
    } catch (_) {
      return null;
    }
  }
}

class GenerateBatchRequest {
  GenerateBatchRequest({
    required this.planId,
    required this.count,
    this.packageName = '',
    this.usernamePrefix = '',
    this.usernameSuffix = '',
    this.startsWithOrEndsWith = '',
    this.prefixOrSuffixValue = '',
    this.usernameLength = 8,
    this.passwordLength = 6,
    this.passwordGenerationType = 'medium',
    this.timeValue = 0,
    this.timeUnit = 'days',
    this.deviceCount = 1,
    this.pricePerCard = 0,
    this.totalPrice = 0,
    this.totalQuotaMb = 0,
    this.serviceName = '',
    this.notes = '',
  });

  final int planId;
  final int count;
  final String packageName;
  final String usernamePrefix;
  final String usernameSuffix;
  final String startsWithOrEndsWith;
  final String prefixOrSuffixValue;
  final int usernameLength;
  final int passwordLength;
  final String passwordGenerationType;
  final int timeValue;
  final String timeUnit;
  final int deviceCount;
  final num pricePerCard;
  final num totalPrice;
  final int totalQuotaMb;
  final String serviceName;
  final String notes;

  Map<String, dynamic> toBody() => {
        'plan_id': planId,
        'count': count,
        if (packageName.isNotEmpty) 'package_name': packageName,
        if (usernamePrefix.isNotEmpty) 'username_prefix': usernamePrefix,
        if (usernameSuffix.isNotEmpty) 'username_suffix': usernameSuffix,
        if (startsWithOrEndsWith.isNotEmpty)
          'starts_with_or_ends_with': startsWithOrEndsWith,
        if (prefixOrSuffixValue.isNotEmpty)
          'prefix_or_suffix_value': prefixOrSuffixValue,
        'username_length': usernameLength,
        'password_length': passwordLength,
        'password_generation_type': passwordGenerationType,
        'time_value': timeValue,
        'time_unit': timeUnit,
        'device_count': deviceCount,
        'price_per_card': pricePerCard,
        'total_price': totalPrice,
        'total_quota_mb': totalQuotaMb,
        if (serviceName.isNotEmpty) 'service_name': serviceName,
        'notes': notes,
      };
}

class UpdateBatchRequest {
  UpdateBatchRequest({
    required this.planId,
    required this.count,
    this.packageName = '',
    this.status = 'active',
    this.pricePerCard = 0,
    this.priceBulk = 0,
    this.totalPrice = 0,
    this.totalQuotaMb = 0,
    this.serviceName = '',
    this.managerId = 0,
    this.usernamePrefix = '',
    this.usernameSuffix = '',
    this.usernameLength = 8,
    this.passwordLength = 6,
    this.passwordGenerationType = 'medium',
    this.includeBatchNumber = false,
    this.startsWithOrEndsWith = '',
    this.prefixOrSuffixValue = '',
    this.timeValue = 0,
    this.timeUnit = 'days',
    this.deviceCount = 1,
    this.durationMode = 'time_unit',
    this.validityAfterFirstLoginDays = 0,
    this.countBySeconds = false,
    this.countFromFirstConnect = true,
    this.onQuotaExhaust = 'stop',
    this.autoRenewAfterFirstUse = false,
    this.switchToMacOnConnect = false,
    this.lockToMacOnClose = false,
    this.phoneOnlyLogin = false,
    this.notes = '',
  });

  final int planId;
  final int count;
  final String packageName;
  final String status;
  final num pricePerCard;
  final num priceBulk;
  final num totalPrice;
  final int totalQuotaMb;
  final String serviceName;
  final int managerId;
  final String usernamePrefix;
  final String usernameSuffix;
  final int usernameLength;
  final int passwordLength;
  final String passwordGenerationType;
  final bool includeBatchNumber;
  final String startsWithOrEndsWith;
  final String prefixOrSuffixValue;
  final int timeValue;
  final String timeUnit;
  final int deviceCount;
  final String durationMode;
  final int validityAfterFirstLoginDays;
  final bool countBySeconds;
  final bool countFromFirstConnect;
  final String onQuotaExhaust;
  final bool autoRenewAfterFirstUse;
  final bool switchToMacOnConnect;
  final bool lockToMacOnClose;
  final bool phoneOnlyLogin;
  final String notes;

  Map<String, dynamic> toBody() => {
        'plan_id': planId,
        'count': count,
        'package_name': packageName,
        'status': status,
        'price_per_card': pricePerCard,
        'price_bulk': priceBulk,
        'total_price': totalPrice,
        'total_quota_mb': totalQuotaMb,
        'service_name': serviceName,
        'manager_id': managerId,
        'username_prefix': usernamePrefix,
        'username_suffix': usernameSuffix,
        'username_length': usernameLength,
        'password_length': passwordLength,
        'password_generation_type': passwordGenerationType,
        'include_batch_number': includeBatchNumber,
        'starts_with_or_ends_with': startsWithOrEndsWith,
        'prefix_or_suffix_value': prefixOrSuffixValue,
        'time_value': timeValue,
        'time_unit': timeUnit,
        'device_count': deviceCount,
        'duration_mode': durationMode,
        'validity_after_first_login_days': validityAfterFirstLoginDays,
        'count_by_seconds': countBySeconds,
        'count_from_first_connect': countFromFirstConnect,
        'on_quota_exhaust': onQuotaExhaust,
        'auto_renew_after_first_use': autoRenewAfterFirstUse,
        'switch_to_mac_on_connect': switchToMacOnConnect,
        'lock_to_mac_on_close': lockToMacOnClose,
        'phone_only_login': phoneOnlyLogin,
        'notes': notes,
      };
}

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
      exists: _boolValue(json['exists']),
      status: (json['status'] ?? 'unknown').toString(),
      query: (json['query'] ?? '').toString(),
      id: _intValue(json['id']),
      username: (json['username'] ?? '').toString(),
      hasPassword: _boolValue(json['has_password']),
      used: _boolValue(json['used']),
      revoked: _boolValue(json['revoked']),
      lockedMac: _stringOrNull(json['locked_mac']),
      disabledReason: (json['disabled_reason'] ?? '').toString(),
      createdAt: _dateValue(json['created_at']),
      startedAt: _dateValue(json['started_at']),
      expiresAt: _dateValue(json['expires_at']),
      remainingSeconds: _intValue(json['remaining_seconds']),
      batch:
          batch is Map<String, dynamic> ? CardCheckBatch.fromJson(batch) : null,
      profile: profile is Map<String, dynamic>
          ? CardCheckProfile.fromJson(profile)
          : null,
      assignedTo: assignedTo is Map<String, dynamic>
          ? CardAssignedTo.fromJson(assignedTo)
          : null,
      lastSeenAt: _dateValue(json['last_seen_at']),
      macAddress: _stringOrNull(json['mac_address']),
      ipAddress: _stringOrNull(json['ip_address']),
      nasAddress: _stringOrNull(json['nas_address']),
      activeSession: json.containsKey('active_session')
          ? _boolValue(json['active_session'])
          : null,
      lastSessionSeconds: _intValue(json['last_session_seconds']),
      operations: json['operations'] is Map<String, dynamic>
          ? CardOperations.fromJson(json['operations'] as Map<String, dynamic>)
          : CardOperations(),
      accountingSummary: json['accounting_summary'] is Map<String, dynamic>
          ? CardAccountingSummary.fromJson(
              json['accounting_summary'] as Map<String, dynamic>,
            )
          : CardAccountingSummary(),
      dataSources: _stringList(json['data_sources']),
      availableFields: _stringList(json['available_fields']),
      missingFields: _stringList(json['missing_fields']),
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
        id: _intValue(json['id']),
        batchCode: (json['batch_code'] ?? '').toString(),
        packageName: (json['package_name'] ?? '').toString(),
        status: (json['status'] ?? '').toString(),
        count: _intValue(json['count']) ?? 0,
        generated: _intValue(json['generated']) ?? 0,
        used: _intValue(json['used']) ?? 0,
        managerId: _intValue(json['manager_id']),
        createdBy: _stringOrNull(json['created_by']),
        createdAt: _dateValue(json['created_at']),
        expiresAt: _dateValue(json['expires_at']),
        deletedAt: _dateValue(json['deleted_at']),
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
        id: _intValue(json['id']),
        name: (json['name'] ?? '').toString(),
        code: (json['code'] ?? '').toString(),
        serviceType: _stringOrNull(json['service_type']),
        planType: _stringOrNull(json['plan_type']),
        speedDownKbps: _intValue(json['speed_down_kbps']),
        speedUpKbps: _intValue(json['speed_up_kbps']),
        quotaTotalMb: _intValue(json['quota_total_mb']),
        quotaDailyMb: _intValue(json['quota_daily_mb']),
        quotaMonthlyMb: _intValue(json['quota_monthly_mb']),
        durationMinutes: _intValue(json['duration_minutes']),
        validityDays: _intValue(json['validity_days']),
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
        subscriberId: _intValue(json['subscriber_id']),
        username: (json['username'] ?? '').toString(),
        fullName: (json['full_name'] ?? '').toString(),
        mobile: (json['mobile'] ?? '').toString(),
        status: _stringOrNull(json['status']),
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
        canDisconnect: _boolValue(json['can_disconnect']),
        canLockMac: _boolValue(json['can_lock_mac']),
        canResetUsage: _boolValue(json['can_reset_usage']),
        canDisable: _boolValue(json['can_disable']),
        canEnable: _boolValue(json['can_enable']),
        canDeletePermanently: _boolValue(json['can_delete_permanently']),
      );
}

class CardAccountingSummary {
  CardAccountingSummary({
    this.sessionsCount = 0,
    this.onlineSessions = 0,
    this.uniqueMacs = 0,
    this.uniqueIps = 0,
    this.uniqueNas = 0,
    this.totalSessionSeconds = 0,
    this.totalUploadBytes = 0,
    this.totalDownloadBytes = 0,
    this.firstSessionAt,
    this.lastSessionAt,
    List<CardMacSummary>? macs,
    List<CardSession>? latestSessions,
  })  : macs = macs ?? const [],
        latestSessions = latestSessions ?? const [];

  final int sessionsCount;
  final int onlineSessions;
  final int uniqueMacs;
  final int uniqueIps;
  final int uniqueNas;
  final int totalSessionSeconds;
  final int totalUploadBytes;
  final int totalDownloadBytes;
  final DateTime? firstSessionAt;
  final DateTime? lastSessionAt;
  final List<CardMacSummary> macs;
  final List<CardSession> latestSessions;

  factory CardAccountingSummary.fromJson(Map<String, dynamic> json) =>
      CardAccountingSummary(
        sessionsCount: _intValue(json['sessions_count']) ?? 0,
        onlineSessions: _intValue(json['online_sessions']) ?? 0,
        uniqueMacs: _intValue(json['unique_macs']) ?? 0,
        uniqueIps: _intValue(json['unique_ips']) ?? 0,
        uniqueNas: _intValue(json['unique_nas']) ?? 0,
        totalSessionSeconds: _intValue(json['total_session_seconds']) ?? 0,
        totalUploadBytes: _intValue(json['total_upload_bytes']) ?? 0,
        totalDownloadBytes: _intValue(json['total_download_bytes']) ?? 0,
        firstSessionAt: _dateValue(json['first_session_at']),
        lastSessionAt: _dateValue(json['last_session_at']),
        macs: (json['macs'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(CardMacSummary.fromJson)
            .toList(),
        latestSessions: (json['latest_sessions'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(CardSession.fromJson)
            .toList(),
      );
}

class CardMacSummary {
  CardMacSummary({
    this.mac = '',
    this.sessionsCount = 0,
    this.onlineSessions = 0,
    this.lastSeenAt,
  });

  final String mac;
  final int sessionsCount;
  final int onlineSessions;
  final DateTime? lastSeenAt;

  factory CardMacSummary.fromJson(Map<String, dynamic> json) => CardMacSummary(
        mac: (json['mac'] ?? '').toString(),
        sessionsCount: _intValue(json['sessions_count']) ?? 0,
        onlineSessions: _intValue(json['online_sessions']) ?? 0,
        lastSeenAt: _dateValue(json['last_seen_at']),
      );
}

class CardSession {
  CardSession({
    this.id,
    this.sessionId = '',
    this.uniqueId = '',
    this.startedAt,
    this.updatedAt,
    this.stoppedAt,
    this.online = false,
    this.durationSeconds = 0,
    this.uploadBytes = 0,
    this.downloadBytes = 0,
    this.macAddress,
    this.calledStation,
    this.ipAddress,
    this.ipv6Address,
    this.nasAddress,
    this.nasPort,
    this.nasPortType,
    this.serviceType,
    this.framedProtocol,
    this.connectInfoStart,
    this.connectInfoStop,
    this.terminateCause,
    this.deviceHint,
  });

  final int? id;
  final String sessionId;
  final String uniqueId;
  final DateTime? startedAt;
  final DateTime? updatedAt;
  final DateTime? stoppedAt;
  final bool online;
  final int durationSeconds;
  final int uploadBytes;
  final int downloadBytes;
  final String? macAddress;
  final String? calledStation;
  final String? ipAddress;
  final String? ipv6Address;
  final String? nasAddress;
  final String? nasPort;
  final String? nasPortType;
  final String? serviceType;
  final String? framedProtocol;
  final String? connectInfoStart;
  final String? connectInfoStop;
  final String? terminateCause;
  final String? deviceHint;

  factory CardSession.fromJson(Map<String, dynamic> json) => CardSession(
        id: _intValue(json['id']),
        sessionId: (json['session_id'] ?? '').toString(),
        uniqueId: (json['unique_id'] ?? '').toString(),
        startedAt: _dateValue(json['started_at']),
        updatedAt: _dateValue(json['updated_at']),
        stoppedAt: _dateValue(json['stopped_at']),
        online: _boolValue(json['online']),
        durationSeconds: _intValue(json['duration_seconds']) ?? 0,
        uploadBytes: _intValue(json['upload_bytes']) ?? 0,
        downloadBytes: _intValue(json['download_bytes']) ?? 0,
        macAddress: _stringOrNull(json['mac_address']),
        calledStation: _stringOrNull(json['called_station']),
        ipAddress: _stringOrNull(json['ip_address']),
        ipv6Address: _stringOrNull(json['ipv6_address']),
        nasAddress: _stringOrNull(json['nas_address']),
        nasPort: _stringOrNull(json['nas_port']),
        nasPortType: _stringOrNull(json['nas_port_type']),
        serviceType: _stringOrNull(json['service_type']),
        framedProtocol: _stringOrNull(json['framed_protocol']),
        connectInfoStart: _stringOrNull(json['connect_info_start']),
        connectInfoStop: _stringOrNull(json['connect_info_stop']),
        terminateCause: _stringOrNull(json['terminate_cause']),
        deviceHint: _stringOrNull(json['device_hint']),
      );
}

int? _intValue(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

num? _numValue(Object? value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString());
}

bool _boolValue(Object? value) =>
    value == true || value == 1 || value == '1' || value == 'true';

DateTime? _dateValue(Object? value) {
  if (value == null || value.toString().isEmpty) return null;
  try {
    return DateTime.parse(value.toString().replaceAll('Z', ''));
  } catch (_) {
    return null;
  }
}

String? _stringOrNull(Object? value) {
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

List<String> _stringList(Object? value) {
  return (value as List? ?? const [])
      .map((item) => item.toString())
      .where((item) => item.isNotEmpty)
      .toList();
}
