class PaymentRequestPage {
  const PaymentRequestPage({required this.items, required this.count});

  final List<PaymentRequestRecord> items;
  final int count;

  factory PaymentRequestPage.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    final items = _list(data['items'])
        .map((item) => PaymentRequestRecord.fromJson(_map(item)))
        .toList();
    return PaymentRequestPage(items: items, count: _int(data['count']));
  }
}

class PaymentCollectionSettings {
  const PaymentCollectionSettings({
    required this.id,
    required this.provider,
    required this.enabled,
    required this.walletNumber,
    required this.walletOwnerName,
    required this.currency,
    required this.confirmationMode,
    required this.autoApply,
    required this.allowCards,
    required this.allowMonthlySubscriptions,
    required this.allowDistributorPayments,
    required this.minAmount,
    required this.maxAmount,
    required this.paymentRequestTtlMinutes,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String provider;
  final bool enabled;
  final String walletNumber;
  final String walletOwnerName;
  final String currency;
  final String confirmationMode;
  final bool autoApply;
  final bool allowCards;
  final bool allowMonthlySubscriptions;
  final bool allowDistributorPayments;
  final double? minAmount;
  final double? maxAmount;
  final int paymentRequestTtlMinutes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory PaymentCollectionSettings.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    final settings = _map(data['settings']);
    final source = settings.isEmpty ? data : settings;
    return PaymentCollectionSettings(
      id: _int(source['id']),
      provider: _string(source['provider'], fallback: 'manual_wallet'),
      enabled: _bool(source['enabled']),
      walletNumber: _string(source['wallet_number']),
      walletOwnerName: _string(source['wallet_owner_name']),
      currency: _string(source['currency'], fallback: 'ILS'),
      confirmationMode:
          _string(source['confirmation_mode'], fallback: 'manual'),
      autoApply: _bool(source['auto_apply']),
      allowCards: _bool(source['allow_cards']),
      allowMonthlySubscriptions: _bool(source['allow_monthly_subscriptions']),
      allowDistributorPayments: _bool(source['allow_distributor_payments']),
      minAmount: _nullableDouble(source['min_amount']),
      maxAmount: _nullableDouble(source['max_amount']),
      paymentRequestTtlMinutes: _int(source['payment_request_ttl_minutes']) == 0
          ? 1440
          : _int(source['payment_request_ttl_minutes']),
      createdAt: _date(source['created_at']),
      updatedAt: _date(source['updated_at']),
    );
  }

  Map<String, dynamic> toApiJson() {
    return {
      'provider': provider,
      'enabled': enabled,
      'wallet_number': walletNumber,
      'wallet_owner_name': walletOwnerName,
      'currency': currency,
      'confirmation_mode': confirmationMode,
      'auto_apply': autoApply,
      'allow_cards': allowCards,
      'allow_monthly_subscriptions': allowMonthlySubscriptions,
      'allow_distributor_payments': allowDistributorPayments,
      'min_amount': minAmount,
      'max_amount': maxAmount,
      'payment_request_ttl_minutes': paymentRequestTtlMinutes,
    };
  }

  String get providerLabel => switch (provider) {
        'manual_wallet' => 'محفظة يدوية',
        'jawwal_pay' => 'Jawwal Pay',
        _ => provider.trim().isEmpty ? 'غير محدد' : provider,
      };

  String get confirmationLabel => switch (confirmationMode) {
        'manual' => 'مراجعة يدوية',
        'automatic' => 'اعتماد آلي',
        _ => confirmationMode.trim().isEmpty ? 'غير محدد' : confirmationMode,
      };
}

class PaymentReconciliationSummary {
  const PaymentReconciliationSummary({
    required this.counts,
    required this.paidWithoutLedger,
    required this.paidNotApplied,
    required this.expiredPending,
    required this.duplicateProviderTransactions,
  });

  final Map<String, int> counts;
  final List<PaymentReconciliationItem> paidWithoutLedger;
  final List<PaymentReconciliationItem> paidNotApplied;
  final List<PaymentReconciliationItem> expiredPending;
  final List<PaymentReconciliationItem> duplicateProviderTransactions;

  factory PaymentReconciliationSummary.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    final reconciliation = _map(data['reconciliation']);
    final source = reconciliation.isEmpty ? data : reconciliation;
    return PaymentReconciliationSummary(
      counts: _map(source['counts']).map(
        (key, value) => MapEntry(key, _int(value)),
      ),
      paidWithoutLedger: _list(source['paid_without_ledger'])
          .map((item) => PaymentReconciliationItem.fromJson(_map(item)))
          .toList(),
      paidNotApplied: _list(source['paid_not_applied'])
          .map((item) => PaymentReconciliationItem.fromJson(_map(item)))
          .toList(),
      expiredPending: _list(source['expired_pending'])
          .map((item) => PaymentReconciliationItem.fromJson(_map(item)))
          .toList(),
      duplicateProviderTransactions:
          _list(source['duplicate_provider_transactions'])
              .map((item) => PaymentReconciliationItem.fromJson(_map(item)))
              .toList(),
    );
  }

  int count(String key) => counts[key] ?? 0;

  int get totalIssues => counts.values.fold(0, (sum, value) => sum + value);

  bool get isClean => totalIssues == 0;
}

class PaymentReconciliationItem {
  const PaymentReconciliationItem({
    required this.id,
    required this.referenceCode,
    required this.amount,
    required this.currency,
    required this.status,
    required this.serviceApplyStatus,
    required this.ledgerEntryId,
    required this.providerTransactionId,
    required this.count,
    required this.paymentRequestIds,
    required this.expiresAt,
    required this.createdAt,
  });

  final int id;
  final String referenceCode;
  final double amount;
  final String currency;
  final String status;
  final String serviceApplyStatus;
  final int ledgerEntryId;
  final String providerTransactionId;
  final int count;
  final String paymentRequestIds;
  final DateTime? expiresAt;
  final DateTime? createdAt;

  factory PaymentReconciliationItem.fromJson(Map<String, dynamic> json) {
    return PaymentReconciliationItem(
      id: _int(json['id']),
      referenceCode: _string(json['reference_code']),
      amount: _double(json['amount']),
      currency: _string(json['currency'], fallback: 'ILS'),
      status: _string(json['status']),
      serviceApplyStatus: _string(json['service_apply_status']),
      ledgerEntryId: _int(json['ledger_entry_id']),
      providerTransactionId: _string(json['provider_transaction_id']),
      count: _int(json['count']),
      paymentRequestIds: _string(json['payment_request_ids']),
      expiresAt: _date(json['expires_at']),
      createdAt: _date(json['created_at']),
    );
  }

  String get amountLabel =>
      amount == 0 ? 'غير محدد' : '${_formatAmount(amount)} $currency';

  String get displayReference {
    if (referenceCode.isNotEmpty) return referenceCode;
    if (providerTransactionId.isNotEmpty) return providerTransactionId;
    if (id > 0) return '#$id';
    return 'غير محدد';
  }
}

class PaymentInstructions {
  const PaymentInstructions({
    required this.amount,
    required this.currency,
    required this.receiverWallet,
    required this.walletOwnerName,
    required this.referenceCode,
    required this.expiresAt,
    required this.instructions,
    required this.status,
  });

  final double amount;
  final String currency;
  final String receiverWallet;
  final String walletOwnerName;
  final String referenceCode;
  final DateTime? expiresAt;
  final String instructions;
  final String status;

  factory PaymentInstructions.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    final source =
        _map(data['instructions']).isEmpty ? json : _map(data['instructions']);
    return PaymentInstructions(
      amount: _double(source['amount']),
      currency: _string(source['currency'], fallback: 'ILS'),
      receiverWallet: _string(source['receiver_wallet']),
      walletOwnerName: _string(source['wallet_owner_name']),
      referenceCode: _string(source['reference_code']),
      expiresAt: _date(source['expires_at']),
      instructions: _string(source['instructions']),
      status: _string(source['status']),
    );
  }

  String get amountLabel => '${_formatAmount(amount)} $currency';

  String get statusLabel => _paymentStatusLabel(status);
}

class PaymentRequestRecord {
  const PaymentRequestRecord({
    required this.id,
    required this.payerType,
    required this.payerId,
    required this.purpose,
    required this.amount,
    required this.currency,
    required this.provider,
    required this.receiverWallet,
    required this.referenceCode,
    required this.status,
    required this.expiresAt,
    required this.serviceApplyStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String payerType;
  final int payerId;
  final String purpose;
  final double amount;
  final String currency;
  final String provider;
  final String receiverWallet;
  final String referenceCode;
  final String status;
  final DateTime? expiresAt;
  final String serviceApplyStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory PaymentRequestRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRequestRecord(
      id: _int(json['id']),
      payerType: _string(json['payer_type']),
      payerId: _int(json['payer_id']),
      purpose: _string(json['purpose']),
      amount: _double(json['amount']),
      currency: _string(json['currency'], fallback: 'ILS'),
      provider: _string(json['provider']),
      receiverWallet: _string(json['receiver_wallet']),
      referenceCode: _string(json['reference_code']),
      status: _string(json['status']),
      expiresAt: _date(json['expires_at']),
      serviceApplyStatus: _string(
        json['service_apply_status'],
        fallback: 'not_applied',
      ),
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
    );
  }

  bool get isReviewable =>
      status == 'proof_submitted' || status == 'under_review';

  bool get isPaid => status == 'paid';

  bool get canApplyService => isPaid && serviceApplyStatus != 'applied';

  String get amountLabel => '${_formatAmount(amount)} $currency';

  String get statusLabel => _paymentStatusLabel(status);

  String get purposeLabel => switch (purpose) {
        'card_purchase' => 'شراء كروت',
        'monthly_subscription' => 'اشتراك شهري',
        'subscriber_renewal' => 'تجديد مشترك',
        'quota_topup' => 'إضافة حصة',
        'time_extension' => 'تمديد وقت',
        'distributor_payment' => 'دفعة موزع',
        'loan_settlement' => 'تسوية سلفة',
        _ => purpose.trim().isEmpty ? 'غير محدد' : 'غرض دفع غير معروف',
      };

  String get payerLabel => switch (payerType) {
        'subscriber' => 'مشترك #$payerId',
        'card_user' => 'مستخدم كرت #$payerId',
        'distributor' => 'موزع #$payerId',
        _ => payerId > 0 ? '$payerType #$payerId' : payerType,
      };

  String get serviceApplyLabel => switch (serviceApplyStatus) {
        'not_applied' => 'لم تطبق الخدمة',
        'pending' => 'بانتظار التطبيق',
        'applied' => 'تم تطبيق الخدمة',
        'failed' => 'فشل تطبيق الخدمة',
        _ => serviceApplyStatus.trim().isEmpty
            ? 'غير محدد'
            : 'حالة تطبيق غير معروفة',
      };
}

class PaymentReviewResult {
  const PaymentReviewResult({
    required this.request,
    required this.applyAttempt,
  });

  final PaymentRequestRecord request;
  final PaymentApplyAttempt? applyAttempt;

  factory PaymentReviewResult.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    return PaymentReviewResult(
      request: PaymentRequestRecord.fromJson(_map(data['request'])),
      applyAttempt: data['apply_attempt'] == null
          ? null
          : PaymentApplyAttempt.fromJson(_map(data['apply_attempt'])),
    );
  }
}

class PaymentApplyAttempt {
  const PaymentApplyAttempt({
    required this.id,
    required this.status,
    required this.result,
  });

  final int id;
  final String status;
  final Map<String, dynamic> result;

  factory PaymentApplyAttempt.fromJson(Map<String, dynamic> json) {
    return PaymentApplyAttempt(
      id: _int(json['id']),
      status: _string(json['status']),
      result: _map(json['result']),
    );
  }

  bool get appliedLocalEntitlement => _bool(result['local_service_apply']);

  String get serviceKey => _string(result['service_key']);

  String get serviceLabel => _string(result['service_label']);

  String get successMessage {
    if (appliedLocalEntitlement) {
      final label = serviceLabel.isNotEmpty ? serviceLabel : serviceKey;
      if (label.isNotEmpty) {
        return 'تم اعتماد خدمة $label داخل عقد التشغيل';
      }
      return 'تم اعتماد الخدمة داخل عقد التشغيل';
    }
    return 'تم تسجيل تطبيق الخدمة بدون تغيير صلاحيات التشغيل';
  }
}

Map<String, dynamic> _data(Map<String, dynamic> json) {
  final data = json['data'];
  if (data is Map<String, dynamic>) return data;
  if (data is Map) {
    return data.map((key, value) => MapEntry(key.toString(), value));
  }
  return json;
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

List<Object?> _list(Object? value) {
  if (value is List) return value;
  return const [];
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

bool _bool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().trim().toLowerCase();
  return text == 'true' || text == '1' || text == 'yes';
}

double _double(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _nullableDouble(Object? value) {
  if (value == null || value.toString().trim().isEmpty) return null;
  return _double(value);
}

String _formatAmount(double amount) {
  return amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
}

String _paymentStatusLabel(String status) {
  return switch (status) {
    'pending' => 'بانتظار الدفع',
    'proof_submitted' => 'بانتظار مراجعة الإثبات',
    'under_review' => 'قيد المراجعة',
    'paid' => 'مدفوع',
    'rejected' => 'مرفوض',
    'expired' => 'منتهي',
    'cancelled' => 'ملغى',
    'failed' => 'فشل',
    _ => status.trim().isEmpty ? 'غير محدد' : 'حالة دفع غير معروفة',
  };
}

DateTime? _date(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text.replaceFirst('Z', ''));
}
