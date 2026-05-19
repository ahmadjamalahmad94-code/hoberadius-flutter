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
    this.timeValue = 0,
    this.timeUnit = 'days',
    this.deviceCount = 1,
    this.pricePerCard = 0,
    this.totalPrice = 0,
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
  final int timeValue;
  final String timeUnit;
  final int deviceCount;
  final num pricePerCard;
  final num totalPrice;

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
        timeValue: _int(j['time_value']) ?? 0,
        timeUnit: (j['time_unit'] ?? 'days').toString(),
        deviceCount: _int(j['device_count']) ?? 1,
        pricePerCard: _num(j['price_per_card']) ?? 0,
        totalPrice: _num(j['total_price']) ?? 0,
      );

  static int? _int(Object? v) =>
      v == null ? null : (v is int ? v : int.tryParse(v.toString()));

  static num? _num(Object? v) {
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse(v.toString());
  }

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
    this.notes = '',
  });

  final int planId;
  final int count;
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
  final String notes;

  Map<String, dynamic> toBody() => {
        'plan_id': planId,
        'count': count,
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
        'notes': notes,
      };
}
