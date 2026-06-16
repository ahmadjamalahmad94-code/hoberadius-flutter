import '../../../core/format/currency.dart';

class WalletPage {
  const WalletPage({required this.items, required this.count});

  final List<WalletRecord> items;
  final int count;

  factory WalletPage.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    final rawItems = data['items'];
    return WalletPage(
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((item) => WalletRecord.fromJson(_map(item)))
              .toList()
          : const [],
      count: _int(data['count']),
    );
  }
}

class WalletRecord {
  const WalletRecord({
    required this.id,
    required this.ownerType,
    required this.ownerId,
    required this.currency,
    required this.balance,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String ownerType;
  final int? ownerId;
  final String currency;
  final String balance;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory WalletRecord.fromJson(Map<String, dynamic> json) {
    return WalletRecord(
      id: _int(json['id']),
      ownerType: _string(json['owner_type'], fallback: 'company'),
      ownerId: _nullableInt(json['owner_id']),
      currency: _string(json['currency'], fallback: kDefaultCurrency),
      balance: _moneyString(json['balance']),
      status: _string(json['status'], fallback: 'active'),
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
    );
  }

  String get ownerLabel {
    final base = walletOwnerTypeLabel(ownerType);
    return ownerId == null ? base : '$base #$ownerId';
  }

  String get statusLabel => walletStatusLabel(status);
}

class WalletCreateDraft {
  const WalletCreateDraft({
    required this.ownerType,
    required this.ownerId,
    required this.currency,
  });

  final String ownerType;
  final int? ownerId;
  final String currency;

  Map<String, dynamic> toApiJson() {
    return {
      'owner_type': ownerType,
      if (ownerId != null && ownerId! > 0) 'owner_id': ownerId,
      'currency': normalizeCurrency(currency),
    };
  }
}

class WalletChangeDraft {
  const WalletChangeDraft({
    required this.amount,
    required this.referenceType,
    required this.referenceId,
    required this.notes,
  });

  final double amount;
  final String referenceType;
  final int? referenceId;
  final String notes;

  Map<String, dynamic> toApiJson() {
    return {
      'amount': amount,
      'reference_type': referenceType,
      if (referenceId != null && referenceId! > 0) 'reference_id': referenceId,
      if (notes.trim().isNotEmpty) 'notes': notes.trim(),
    };
  }
}

class WalletChangeResult {
  const WalletChangeResult({
    required this.wallet,
    required this.transaction,
  });

  final WalletRecord wallet;
  final WalletTransaction transaction;

  factory WalletChangeResult.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    return WalletChangeResult(
      wallet: WalletRecord.fromJson(_map(data['wallet'])),
      transaction: WalletTransaction.fromJson(_map(data['transaction'])),
    );
  }
}

class WalletTransactionsPage {
  const WalletTransactionsPage({required this.items, required this.count});

  final List<WalletTransaction> items;
  final int count;

  factory WalletTransactionsPage.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    final rawItems = data['items'];
    return WalletTransactionsPage(
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((item) => WalletTransaction.fromJson(_map(item)))
              .toList()
          : const [],
      count: _int(data['count']),
    );
  }
}

class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.walletId,
    required this.transactionType,
    required this.amount,
    required this.beforeBalance,
    required this.afterBalance,
    required this.currency,
    required this.referenceType,
    required this.referenceId,
    required this.actorType,
    required this.actorId,
    required this.notes,
    required this.createdAt,
  });

  final int id;
  final int walletId;
  final String transactionType;
  final String amount;
  final String beforeBalance;
  final String afterBalance;
  final String currency;
  final String referenceType;
  final int? referenceId;
  final String actorType;
  final int? actorId;
  final String notes;
  final DateTime? createdAt;

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: _int(json['id']),
      walletId: _int(json['wallet_id']),
      transactionType: _string(json['transaction_type']),
      amount: _moneyString(json['amount']),
      beforeBalance: _moneyString(json['before_balance']),
      afterBalance: _moneyString(json['after_balance']),
      currency: _string(json['currency'], fallback: kDefaultCurrency),
      referenceType: _string(json['reference_type']),
      referenceId: _nullableInt(json['reference_id']),
      actorType: _string(json['actor_type']),
      actorId: _nullableInt(json['actor_id']),
      notes: _string(json['notes']),
      createdAt: _date(json['created_at']),
    );
  }

  String get typeLabel => walletTransactionTypeLabel(transactionType);

  String get referenceLabel => walletReferenceTypeLabel(referenceType);
}

String walletOwnerTypeLabel(String value) {
  return switch (value) {
    'company' => 'الشركة',
    'manager' => 'مدير',
    'distributor' => 'موزع',
    'subscriber' => 'مشترك',
    'card_user' => 'مستخدم كروت',
    '' => 'كل المالكين',
    _ => 'مالك غير مصنف',
  };
}

String walletStatusLabel(String value) {
  return switch (value) {
    '' => 'كل الحالات',
    'active' => 'نشطة',
    'suspended' => 'موقوفة',
    'closed' => 'مغلقة',
    _ => 'حالة غير مصنفة',
  };
}

String walletTransactionTypeLabel(String value) {
  return switch (value) {
    'credit' => 'شحن',
    'debit' => 'خصم',
    'transfer' => 'تحويل',
    'hold' => 'حجز',
    'release' => 'فك حجز',
    'reversal' => 'عكس قيد',
    _ => 'حركة مالية',
  };
}

String walletReferenceTypeLabel(String value) {
  return switch (value) {
    'manual' => 'تسجيل يدوي',
    'subscriber_payment' => 'دفعة مشترك',
    'card_sale' => 'بيع كروت',
    'invoice' => 'فاتورة',
    'voucher' => 'كوبون',
    'wallet_transaction' => 'حركة محفظة',
    _ => value.trim().isEmpty ? 'غير محدد' : 'مرجع مالي',
  };
}

Map<String, dynamic> _data(Map<String, dynamic> json) {
  return _map(json['data']);
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry('$key', val));
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

String _moneyString(Object? value) {
  if (value is num) return value.toStringAsFixed(2);
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? '0.00' : text;
}

DateTime? _date(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text.replaceAll('Z', ''));
}
