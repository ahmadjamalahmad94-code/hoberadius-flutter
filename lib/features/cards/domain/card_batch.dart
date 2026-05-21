import 'card_parsing.dart';

/// Core card-batch entity returned by the cards repository for list
/// and detail screens. Field names mirror the server payload one-to-one
/// so the screens can drop in without translation.
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
    this.sourceType = 'generated',
    this.originalCount = 0,
    this.settlementCount = 0,
    this.archivedCount = 0,
    this.pendingArchiveCount = 0,
    this.operationalRemainingCount = 0,
    this.archiveSource = '',
    this.archivePolicyId,
    this.retentionExpiresAt,
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
  final String sourceType;
  final int originalCount;
  final int settlementCount;
  final int archivedCount;
  final int pendingArchiveCount;
  final int operationalRemainingCount;
  final String archiveSource;
  final int? archivePolicyId;
  final DateTime? retentionExpiresAt;

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
        count: cardParseInt(j['count']) ?? 0,
        generated: cardParseInt(j['generated']) ?? 0,
        used: cardParseInt(j['used']) ?? 0,
        status: (j['status'] ?? 'active').toString(),
        packageName: (j['package_name'] ?? '').toString(),
        serviceName: (j['service_name'] ?? '').toString(),
        notes: (j['notes'] ?? '').toString(),
        expireAt: cardParseDate(j['expire_at']),
        createdAt: cardParseDate(j['created_at']),
        createdBy: (j['created_by'] ?? '').toString(),
        usernamePrefix: (j['username_prefix'] ?? '').toString(),
        usernameSuffix: (j['username_suffix'] ?? '').toString(),
        usernameLength: cardParseInt(j['username_length']) ?? 8,
        passwordLength: cardParseInt(j['password_length']) ?? 6,
        passwordCharset: (j['password_charset'] ?? 'digits').toString(),
        includeBatchNumber: cardParseBool(j['include_batch_number']),
        passwordGenerationType:
            (j['password_generation_type'] ?? 'medium').toString(),
        randomGenerationEnabled: j.containsKey('random_generation_enabled')
            ? cardParseBool(j['random_generation_enabled'])
            : true,
        startsWithOrEndsWith:
            (j['starts_with_or_ends_with'] ?? '').toString(),
        prefixOrSuffixValue: (j['prefix_or_suffix_value'] ?? '').toString(),
        timeValue: cardParseInt(j['time_value']) ?? 0,
        timeUnit: (j['time_unit'] ?? 'days').toString(),
        deviceCount: cardParseInt(j['device_count']) ?? 1,
        durationMode: (j['duration_mode'] ?? 'time_unit').toString(),
        validityAfterFirstLoginDays:
            cardParseInt(j['validity_after_first_login_days']) ?? 0,
        countBySeconds: cardParseBool(j['count_by_seconds']),
        countFromFirstConnect: j.containsKey('count_from_first_connect')
            ? cardParseBool(j['count_from_first_connect'])
            : true,
        onQuotaExhaust: (j['on_quota_exhaust'] ?? 'stop').toString(),
        autoRenewAfterFirstUse: cardParseBool(j['auto_renew_after_first_use']),
        switchToMacOnConnect: cardParseBool(j['switch_to_mac_on_connect']),
        lockToMacOnClose: cardParseBool(j['lock_to_mac_on_close']),
        phoneOnlyLogin: cardParseBool(j['phone_only_login']),
        pricePerCard: cardParseNum(j['price_per_card']) ?? 0,
        priceBulk: cardParseNum(j['price_bulk']) ?? 0,
        totalPrice: cardParseNum(j['total_price']) ?? 0,
        totalQuotaMb: cardParseInt(j['total_quota_mb']) ?? 0,
        managerId: cardParseInt(j['manager_id']) ?? 0,
        distributorId: cardParseInt(j['distributor_id']),
        distributorName: (j['distributor_name'] ?? '').toString(),
        distributorDisplayName:
            (j['distributor_display_name'] ?? '').toString(),
        planName: (j['plan_name'] ?? '').toString(),
        planCurrency: (j['plan_currency'] ?? '').toString(),
        planSpeedDownKbps: cardParseInt(j['plan_speed_down_kbps']),
        planSpeedUpKbps: cardParseInt(j['plan_speed_up_kbps']),
        operationalStatus: (j['operational_status'] ?? '').toString(),
        availableCount:
            cardParseInt(j['available_count']) ?? cardAvailableFallback(j),
        activeCount: cardParseInt(j['active_count']) ?? 0,
        expiredCount: cardParseInt(j['expired_count']) ?? 0,
        revokedCount: cardParseInt(j['revoked_count']) ?? 0,
        remainingCount:
            cardParseInt(j['remaining_count']) ?? cardAvailableFallback(j),
        sessionsCount: cardParseInt(j['sessions_count']) ?? 0,
        uniqueMacs: cardParseInt(j['unique_macs']) ?? 0,
        onlineSessions: cardParseInt(j['online_sessions']) ?? 0,
        speedRulesCount: cardParseInt(j['speed_rules_count']) ?? 0,
        activeSpeedRules: cardParseInt(j['active_speed_rules']) ?? 0,
        estimatedUnitPrice: cardParseNum(j['estimated_unit_price']) ?? 0,
        sourceType: (j['source_type'] ?? 'generated').toString(),
        originalCount: cardParseInt(j['original_count']) ??
            cardParseInt(j['count']) ??
            cardParseInt(j['generated']) ??
            0,
        settlementCount: cardParseInt(j['settlement_count']) ??
            cardParseInt(j['original_count']) ??
            cardParseInt(j['count']) ??
            0,
        archivedCount: cardParseInt(j['archived_count']) ?? 0,
        pendingArchiveCount: cardParseInt(j['pending_archive_count']) ?? 0,
        operationalRemainingCount:
            cardParseInt(j['operational_remaining_count']) ??
                cardAvailableFallback(j),
        archiveSource: (j['archive_source'] ?? '').toString(),
        archivePolicyId: cardParseInt(j['archive_policy_id']),
        retentionExpiresAt: cardParseDate(j['retention_expires_at']),
      );
}

