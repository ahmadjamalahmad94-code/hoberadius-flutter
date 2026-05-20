class Distributor {
  const Distributor({
    this.id,
    this.name = '',
    this.displayName = '',
    this.email = '',
    this.phone = '',
    this.status = 'active',
    this.permissions = const [],
    this.scope = const {},
    this.balance = 0,
    this.creditLimit = 0,
    this.debtBalance = 0,
    this.notes = '',
    this.createdAt,
  });

  final int? id;
  final String name;
  final String displayName;
  final String email;
  final String phone;
  final String status;
  final List<String> permissions;
  final Map<String, dynamic> scope;
  final num balance;
  final num creditLimit;
  final num debtBalance;
  final String notes;
  final DateTime? createdAt;

  String get title => displayName.isEmpty ? name : displayName;
  bool get isActive => status == 'active';

  factory Distributor.fromJson(Map<String, dynamic> j) => Distributor(
        id: _int(j['id']),
        name: (j['name'] ?? '').toString(),
        displayName: (j['display_name'] ?? '').toString(),
        email: (j['email'] ?? '').toString(),
        phone: (j['phone'] ?? '').toString(),
        status: (j['status'] ?? 'active').toString(),
        permissions: _stringList(j['permissions_json'] ?? j['permissions']),
        scope: _map(j['scope_json'] ?? j['scope']),
        balance: _num(j['balance']) ?? 0,
        creditLimit: _num(j['credit_limit']) ?? 0,
        debtBalance: _num(j['debt_balance']) ?? 0,
        notes: (j['notes'] ?? '').toString(),
        createdAt: _dt(j['created_at']),
      );

  Map<String, dynamic> toBody() => {
        'name': name,
        'display_name': displayName,
        'email': email,
        'phone': phone,
        'status': status,
        'permissions': permissions,
        'scope': scope.isEmpty ? {'card_batches': 'assigned'} : scope,
        'balance': balance,
        'credit_limit': creditLimit,
        'debt_balance': debtBalance,
        'notes': notes,
      };
}

class DistributorSummary {
  const DistributorSummary({
    required this.distributor,
    this.assignedBatches = 0,
    this.balance = 0,
    this.debtBalance = 0,
    this.creditLimit = 0,
    this.ledgerDebit = 0,
    this.ledgerCredit = 0,
    this.ledgerEntries = 0,
  });

  final Distributor distributor;
  final int assignedBatches;
  final num balance;
  final num debtBalance;
  final num creditLimit;
  final num ledgerDebit;
  final num ledgerCredit;
  final int ledgerEntries;

  factory DistributorSummary.fromJson(Map<String, dynamic> j) {
    final ledger = _map(j['ledger']);
    return DistributorSummary(
      distributor: Distributor.fromJson(_map(j['distributor'])),
      assignedBatches: _int(j['assigned_batches']) ?? 0,
      balance: _num(j['balance']) ?? 0,
      debtBalance: _num(j['debt_balance']) ?? 0,
      creditLimit: _num(j['credit_limit']) ?? 0,
      ledgerDebit: _num(ledger['debit']) ?? 0,
      ledgerCredit: _num(ledger['credit']) ?? 0,
      ledgerEntries: _int(ledger['entries']) ?? 0,
    );
  }
}

class DistributorBatch {
  const DistributorBatch({
    this.id,
    this.batchCode = '',
    this.packageName = '',
    this.count = 0,
    this.used = 0,
    this.status = '',
    this.assignedAt = '',
    this.assignmentNotes = '',
  });

  final int? id;
  final String batchCode;
  final String packageName;
  final int count;
  final int used;
  final String status;
  final String assignedAt;
  final String assignmentNotes;

  int get available => (count - used).clamp(0, count);

  factory DistributorBatch.fromJson(Map<String, dynamic> j) => DistributorBatch(
        id: _int(j['id']),
        batchCode: (j['batch_code'] ?? '').toString(),
        packageName: (j['package_name'] ?? '').toString(),
        count: _int(j['count']) ?? 0,
        used: _int(j['used']) ?? 0,
        status: (j['status'] ?? '').toString(),
        assignedAt: (j['assigned_at'] ?? '').toString(),
        assignmentNotes: (j['assignment_notes'] ?? '').toString(),
      );
}

class DistributorLedgerEntry {
  const DistributorLedgerEntry({
    this.id,
    this.amount = 0,
    this.direction = '',
    this.entryType = '',
    this.notes = '',
    this.createdAt = '',
  });

  final int? id;
  final num amount;
  final String direction;
  final String entryType;
  final String notes;
  final String createdAt;

  factory DistributorLedgerEntry.fromJson(Map<String, dynamic> j) {
    return DistributorLedgerEntry(
      id: _int(j['id']),
      amount: _num(j['amount']) ?? 0,
      direction: (j['direction'] ?? '').toString(),
      entryType: (j['entry_type'] ?? '').toString(),
      notes: (j['notes'] ?? '').toString(),
      createdAt: (j['created_at'] ?? '').toString(),
    );
  }
}

int? _int(Object? v) =>
    v == null ? null : (v is int ? v : int.tryParse(v.toString()));

num? _num(Object? v) {
  if (v == null) return null;
  if (v is num) return v;
  return num.tryParse(v.toString());
}

Map<String, dynamic> _map(Object? v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return v.map((key, value) => MapEntry(key.toString(), value));
  return const {};
}

List<String> _stringList(Object? v) {
  if (v is List) return v.map((item) => item.toString()).toList();
  if (v is String && v.trim().isNotEmpty) {
    return v
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return const [];
}

DateTime? _dt(Object? v) {
  if (v == null) return null;
  try {
    return DateTime.parse(v.toString().replaceAll('Z', ''));
  } catch (_) {
    return null;
  }
}
