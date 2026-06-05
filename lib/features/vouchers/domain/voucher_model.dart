class VoucherPage {
  const VoucherPage({
    required this.items,
    required this.count,
    required this.stats,
  });

  final List<VoucherRecord> items;
  final int count;
  final VoucherStats stats;

  factory VoucherPage.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    final rawItems = data['items'];
    return VoucherPage(
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((item) => VoucherRecord.fromJson(_map(item)))
              .toList()
          : const [],
      count: _int(data['count']),
      stats: VoucherStats.fromJson(_map(data['stats'])),
    );
  }
}

class VoucherStats {
  const VoucherStats({
    required this.active,
    required this.used,
    required this.revoked,
    required this.expired,
    required this.totalAmount,
    required this.totalCount,
  });

  final int active;
  final int used;
  final int revoked;
  final int expired;
  final double totalAmount;
  final int totalCount;

  factory VoucherStats.fromJson(Map<String, dynamic> json) {
    return VoucherStats(
      active: _int(json['active']),
      used: _int(json['used']),
      revoked: _int(json['revoked']),
      expired: _int(json['expired']),
      totalAmount: _double(json['total_amount']),
      totalCount: _int(json['total_count']),
    );
  }
}

class VoucherRecord {
  const VoucherRecord({
    required this.id,
    required this.code,
    required this.amount,
    required this.planId,
    required this.status,
    required this.usedBySubscriberId,
    required this.usedAt,
    required this.expireAt,
    required this.generatedBy,
    required this.createdAt,
  });

  final int id;
  final String code;
  final double amount;
  final int? planId;
  final String status;
  final int? usedBySubscriberId;
  final DateTime? usedAt;
  final DateTime? expireAt;
  final int generatedBy;
  final DateTime? createdAt;

  factory VoucherRecord.fromJson(Map<String, dynamic> json) {
    return VoucherRecord(
      id: _int(json['id']),
      code: _string(json['code']),
      amount: _double(json['amount']),
      planId: _nullableInt(json['plan_id']),
      status: _string(json['status'], fallback: 'active'),
      usedBySubscriberId: _nullableInt(json['used_by_subscriber_id']),
      usedAt: _date(json['used_at']),
      expireAt: _date(json['expire_at']),
      generatedBy: _int(json['generated_by']),
      createdAt: _date(json['created_at']),
    );
  }

  String get statusLabel => voucherStatusLabel(status);

  bool get canRevoke => status == 'active';

  String get planLabel => planId == null ? 'بدون باقة' : 'باقة رقم $planId';
}

class VoucherGenerateDraft {
  const VoucherGenerateDraft({
    required this.amount,
    required this.count,
    required this.planId,
    required this.expireAt,
  });

  final double amount;
  final int count;
  final int? planId;
  final DateTime? expireAt;

  Map<String, dynamic> toApiJson() {
    return {
      'amount': amount,
      'count': count,
      if (planId != null && planId! > 0) 'plan_id': planId,
      if (expireAt != null) 'expire_at': expireAt!.toUtc().toIso8601String(),
    };
  }
}

class VoucherGenerateResult {
  const VoucherGenerateResult({required this.items, required this.count});

  final List<VoucherRecord> items;
  final int count;

  factory VoucherGenerateResult.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    final rawItems = data['items'];
    return VoucherGenerateResult(
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((item) => VoucherRecord.fromJson(_map(item)))
              .toList()
          : const [],
      count: _int(data['count']),
    );
  }
}

class VoucherRevokeResult {
  const VoucherRevokeResult({required this.id, required this.status});

  final int id;
  final String status;

  factory VoucherRevokeResult.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    return VoucherRevokeResult(
      id: _int(data['id']),
      status: _string(data['status'], fallback: 'revoked'),
    );
  }
}

String voucherStatusLabel(String value) {
  return switch (value) {
    '' => 'كل الحالات',
    'active' => 'نشطة',
    'used' => 'مستخدمة',
    'revoked' => 'ملغاة',
    'expired' => 'منتهية',
    _ => value.trim().isEmpty ? 'غير محددة' : value,
  };
}

Map<String, dynamic> _data(Map<String, dynamic> json) {
  return _map(json['data']);
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return const {};
}

String _string(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _nullableInt(Object? value) {
  if (value == null || value.toString().trim().isEmpty) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double _double(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _date(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text.replaceAll('Z', ''));
}
