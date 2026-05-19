class CardBatch {
  CardBatch({
    this.id,
    this.batchCode = '',
    this.planId,
    this.count = 0,
    this.generated = 0,
    this.packageName = '',
    this.notes = '',
  });

  final int? id;
  final String batchCode;
  final int? planId;
  final int count;
  final int generated;
  final String packageName;
  final String notes;

  factory CardBatch.fromJson(Map<String, dynamic> j) => CardBatch(
        id: j['id'] as int?,
        batchCode: (j['batch_code'] ?? '').toString(),
        planId: j['plan_id'] as int?,
        count: (j['count'] ?? 0) is int ? j['count'] : int.tryParse('${j['count']}') ?? 0,
        generated: (j['generated'] ?? 0) is int ? j['generated'] : 0,
        packageName: (j['package_name'] ?? '').toString(),
        notes: (j['notes'] ?? '').toString(),
      );
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
  });

  final int? id;
  final String username;
  final String password;
  final int? batchId;
  final int? planId;
  final bool used;
  final bool revoked;
  final DateTime? expireAt;

  factory CardItem.fromJson(Map<String, dynamic> j) => CardItem(
        id: j['id'] as int?,
        username: (j['username'] ?? '').toString(),
        password: (j['password'] ?? '').toString(),
        batchId: j['batch_id'] as int?,
        planId: j['plan_id'] as int?,
        used: j['used'] == true || j['used'] == 1,
        revoked: j['revoked'] == true || j['revoked'] == 1,
        expireAt: _parseDt(j['expire_at']),
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
