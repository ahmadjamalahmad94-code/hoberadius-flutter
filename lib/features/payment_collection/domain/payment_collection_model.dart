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

  String get amountLabel =>
      '${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)} $currency';

  String get statusLabel => switch (status) {
        'pending' => 'بانتظار الدفع',
        'proof_submitted' => 'بانتظار مراجعة الإثبات',
        'under_review' => 'قيد المراجعة',
        'paid' => 'مدفوع',
        'rejected' => 'مرفوض',
        'expired' => 'منتهي',
        'cancelled' => 'ملغى',
        'failed' => 'فشل',
        _ => status,
      };

  String get purposeLabel => switch (purpose) {
        'card_purchase' => 'شراء كروت',
        'monthly_subscription' => 'اشتراك شهري',
        'subscriber_renewal' => 'تجديد مشترك',
        'quota_topup' => 'إضافة حصة',
        'time_extension' => 'تمديد وقت',
        'distributor_payment' => 'دفعة موزع',
        'loan_settlement' => 'تسوية سلفة',
        _ => purpose,
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
        _ => serviceApplyStatus,
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

DateTime? _date(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text.replaceFirst('Z', ''));
}
