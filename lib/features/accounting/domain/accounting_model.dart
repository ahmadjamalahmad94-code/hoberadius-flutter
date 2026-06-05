class PaymentTransaction {
  PaymentTransaction({
    required this.id,
    required this.subscriberId,
    required this.username,
    required this.amount,
    required this.currency,
    required this.method,
    required this.status,
    required this.earnedMinutes,
    required this.ledgerEntryId,
    required this.createdAt,
    this.discountAmount = 0,
    this.activationResult = const {},
    this.notes = '',
  });

  final int id;
  final int subscriberId;
  final String username;
  final num amount;
  final String currency;
  final String method;
  final String status;
  final int earnedMinutes;
  final int? ledgerEntryId;
  final DateTime? createdAt;
  final num discountAmount;
  final Map<String, dynamic> activationResult;
  final String notes;

  factory PaymentTransaction.fromJson(Map<String, dynamic> j) {
    return PaymentTransaction(
      id: _int(j['id']) ?? 0,
      subscriberId: _int(j['subscriber_id']) ?? 0,
      username: _string(j['username']),
      amount: _num(j['amount']) ?? 0,
      currency: _string(j['currency'], fallback: 'JOD'),
      method: _string(j['method']),
      status: _string(j['status'], fallback: 'posted'),
      earnedMinutes: _int(j['earned_minutes']) ?? 0,
      ledgerEntryId: _int(j['ledger_entry_id']),
      createdAt: _date(j['created_at']),
      discountAmount: _num(j['discount_amount']) ?? 0,
      activationResult: _map(j['activation_result']),
      notes: _string(j['notes']),
    );
  }
}

class LoanEntry {
  LoanEntry({
    required this.id,
    required this.subscriberId,
    required this.username,
    required this.durationMinutes,
    required this.amount,
    required this.currency,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.startsAt,
    this.endsAt,
    this.settledAt,
    this.approvalStatus = '',
    this.activationResult = const {},
  });

  final int id;
  final int subscriberId;
  final String username;
  final int durationMinutes;
  final num amount;
  final String currency;
  final String reason;
  final String status;
  final DateTime? createdAt;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime? settledAt;
  final String approvalStatus;
  final Map<String, dynamic> activationResult;

  factory LoanEntry.fromJson(Map<String, dynamic> j) {
    return LoanEntry(
      id: _int(j['id']) ?? 0,
      subscriberId: _int(j['subscriber_id']) ?? 0,
      username: _string(j['username']),
      durationMinutes: _int(j['duration_minutes']) ?? 0,
      amount: _num(j['amount']) ?? 0,
      currency: _string(j['currency'], fallback: 'JOD'),
      reason: _string(j['reason']),
      status: _string(j['status'], fallback: 'open'),
      createdAt: _date(j['created_at']),
      startsAt: _date(j['starts_at']),
      endsAt: _date(j['ends_at']),
      settledAt: _date(j['settled_at']),
      approvalStatus: _string(j['approval_status']),
      activationResult: _map(j['activation_result']),
    );
  }

  String get statusLabel => loanStatusLabel(status);

  String get approvalStatusLabel => loanApprovalStatusLabel(approvalStatus);

  bool get isOpen => status == 'open';
}

String loanStatusLabel(String value) {
  return switch (value) {
    '' => 'كل الحالات',
    'open' => 'مفتوحة',
    'settled' => 'مسددة',
    'voided' => 'ملغاة',
    _ => value.trim().isEmpty ? 'غير محددة' : value,
  };
}

String loanApprovalStatusLabel(String value) {
  return switch (value) {
    'approved' => 'معتمدة',
    'pending' => 'بانتظار الاعتماد',
    'not_required' => 'لا يلزم اعتماد',
    _ => value.trim().isEmpty ? 'غير محدد' : value,
  };
}

class LedgerEntry {
  LedgerEntry({
    required this.id,
    required this.entryType,
    required this.direction,
    required this.amount,
    required this.currency,
    required this.username,
    required this.status,
    required this.createdAt,
    this.subscriberId,
    this.reversalOfEntryId,
    this.sourceType = '',
    this.sourceId,
    this.notes = '',
  });

  final int id;
  final String entryType;
  final String direction;
  final num amount;
  final String currency;
  final String username;
  final String status;
  final DateTime? createdAt;
  final int? subscriberId;
  final int? reversalOfEntryId;
  final String sourceType;
  final int? sourceId;
  final String notes;

  factory LedgerEntry.fromJson(Map<String, dynamic> j) {
    return LedgerEntry(
      id: _int(j['id']) ?? 0,
      entryType: _string(j['entry_type']),
      direction: _string(j['direction']),
      amount: _num(j['amount']) ?? 0,
      currency: _string(j['currency'], fallback: 'JOD'),
      username: _string(j['username']),
      status: _string(j['status'], fallback: 'posted'),
      createdAt: _date(j['created_at']),
      subscriberId: _int(j['subscriber_id']),
      reversalOfEntryId: _int(j['reversal_of_entry_id']),
      sourceType: _string(j['source_type']),
      sourceId: _int(j['source_id']),
      notes: _string(j['notes']),
    );
  }
}

String _string(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

num? _num(Object? value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '');
}

DateTime? _date(Object? value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text);
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return const {};
}
