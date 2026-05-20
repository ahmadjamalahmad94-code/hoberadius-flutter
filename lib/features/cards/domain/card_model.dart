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

  int get available => (count - used).clamp(0, count);

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
      );

  static int? _int(Object? v) =>
      v == null ? null : (v is int ? v : int.tryParse(v.toString()));

  static num? _num(Object? v) {
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse(v.toString());
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
