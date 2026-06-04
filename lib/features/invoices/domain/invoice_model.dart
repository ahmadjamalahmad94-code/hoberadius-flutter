class InvoicePage {
  const InvoicePage({
    required this.items,
    required this.count,
    required this.stats,
  });

  final List<InvoiceRecord> items;
  final int count;
  final InvoiceStats stats;

  factory InvoicePage.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    final rawItems = data['items'];
    return InvoicePage(
      items: rawItems is List
          ? rawItems
              .whereType<Map>()
              .map((item) => InvoiceRecord.fromJson(_map(item)))
              .toList()
          : const [],
      count: _int(data['count']),
      stats: InvoiceStats.fromJson(_map(data['stats'])),
    );
  }
}

class InvoiceStats {
  const InvoiceStats({
    required this.total,
    required this.paid,
    required this.pending,
    required this.failed,
    required this.refunded,
    required this.canceled,
    required this.count,
  });

  final double total;
  final double paid;
  final double pending;
  final double failed;
  final double refunded;
  final double canceled;
  final int count;

  factory InvoiceStats.fromJson(Map<String, dynamic> json) {
    return InvoiceStats(
      total: _double(json['total']),
      paid: _double(json['paid']),
      pending: _double(json['pending']),
      failed: _double(json['failed']),
      refunded: _double(json['refunded']),
      canceled: _double(json['canceled']),
      count: _int(json['count']),
    );
  }
}

class InvoiceDraft {
  const InvoiceDraft({
    required this.subscriberId,
    required this.username,
    required this.amount,
    required this.planId,
    required this.planName,
    required this.serviceType,
    required this.direction,
    required this.paymentMethod,
    required this.status,
    required this.expirationAt,
    required this.note,
  });

  final int subscriberId;
  final String username;
  final double amount;
  final int? planId;
  final String planName;
  final String serviceType;
  final String direction;
  final String paymentMethod;
  final String status;
  final DateTime? expirationAt;
  final String note;

  Map<String, dynamic> toApiJson() {
    return {
      'subscriber_id': subscriberId,
      'username': username.trim(),
      'amount': amount,
      if (planId != null && planId! > 0) 'plan_id': planId,
      if (planName.trim().isNotEmpty) 'plan_name': planName.trim(),
      'service_type': serviceType,
      'direction': direction,
      'payment_method': paymentMethod,
      'status': status,
      if (expirationAt != null)
        'expiration_at': expirationAt!.toUtc().toIso8601String(),
      if (note.trim().isNotEmpty) 'note': note.trim(),
    };
  }
}

class InvoiceStatusUpdate {
  const InvoiceStatusUpdate({required this.status, required this.note});

  final String status;
  final String note;

  Map<String, dynamic> toApiJson() {
    return {
      'status': status,
      if (note.trim().isNotEmpty) 'note': note.trim(),
    };
  }
}

class InvoiceRecord {
  const InvoiceRecord({
    required this.id,
    required this.invoiceNumber,
    required this.subscriberId,
    required this.username,
    required this.amount,
    required this.adminId,
    required this.planId,
    required this.planName,
    required this.serviceType,
    required this.routerId,
    required this.direction,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.rechargedOn,
    required this.expirationAt,
    required this.paymentMethod,
    required this.paymentGatewayId,
    required this.status,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String invoiceNumber;
  final int subscriberId;
  final String username;
  final double amount;
  final int adminId;
  final int? planId;
  final String planName;
  final String serviceType;
  final int? routerId;
  final String direction;
  final double balanceBefore;
  final double balanceAfter;
  final DateTime? rechargedOn;
  final DateTime? expirationAt;
  final String paymentMethod;
  final int? paymentGatewayId;
  final String status;
  final String note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory InvoiceRecord.fromJson(Map<String, dynamic> json) {
    return InvoiceRecord(
      id: _int(json['id']),
      invoiceNumber: _string(json['invoice_number']),
      subscriberId: _int(json['subscriber_id']),
      username: _string(json['username']),
      amount: _double(json['amount']),
      adminId: _int(json['admin_id']),
      planId: _nullableInt(json['plan_id']),
      planName: _string(json['plan_name']),
      serviceType: _string(json['service_type'], fallback: 'Hotspot'),
      routerId: _nullableInt(json['router_id']),
      direction: _string(json['direction'], fallback: 'charge'),
      balanceBefore: _double(json['balance_before']),
      balanceAfter: _double(json['balance_after']),
      rechargedOn: _date(json['recharged_on']),
      expirationAt: _date(json['expiration_at']),
      paymentMethod: _string(json['payment_method'], fallback: 'cash'),
      paymentGatewayId: _nullableInt(json['payment_gateway_id']),
      status: _string(json['status'], fallback: 'pending'),
      note: _string(json['note']),
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
    );
  }

  String get displayNumber =>
      invoiceNumber.trim().isEmpty ? '#$id' : invoiceNumber;

  String get statusLabel => invoiceStatusLabel(status);

  String get directionLabel => invoiceDirectionLabel(direction);

  String get paymentMethodLabel => invoicePaymentMethodLabel(paymentMethod);

  String get serviceTypeLabel => invoiceServiceTypeLabel(serviceType);
}

String invoiceStatusLabel(String value) {
  return switch (value) {
    '' => 'كل الحالات',
    'paid' => 'مدفوعة',
    'pending' => 'معلقة',
    'failed' => 'فشلت',
    'refunded' => 'مسترجعة',
    'canceled' => 'ملغاة',
    _ => value.trim().isEmpty ? 'غير محددة' : value,
  };
}

String invoiceDirectionLabel(String value) {
  return switch (value) {
    'charge' => 'تحصيل',
    'refund' => 'إرجاع',
    'deposit' => 'إيداع',
    'withdraw' => 'سحب',
    'credit' => 'رصيد',
    _ => value.trim().isEmpty ? 'غير محدد' : value,
  };
}

String invoicePaymentMethodLabel(String value) {
  return switch (value) {
    'cash' => 'نقدًا',
    'transfer' => 'حوالة',
    'card' => 'بطاقة',
    'online' => 'دفع إلكتروني',
    'manual' => 'يدوي',
    _ => value.trim().isEmpty ? 'غير محددة' : value,
  };
}

String invoiceServiceTypeLabel(String value) {
  return switch (value) {
    'Hotspot' => 'بوابة الدخول',
    'PPPoE' => 'برودباند',
    'Balance' => 'رصيد',
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
