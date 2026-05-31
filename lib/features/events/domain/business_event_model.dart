class BusinessEventsPage {
  const BusinessEventsPage({required this.items, required this.count});

  final List<BusinessEvent> items;
  final int count;

  factory BusinessEventsPage.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    final items = _list(data['items'])
        .map((item) => BusinessEvent.fromJson(_map(item)))
        .toList();
    return BusinessEventsPage(items: items, count: _int(data['count']));
  }
}

class BusinessEvent {
  const BusinessEvent({
    required this.id,
    required this.category,
    required this.severity,
    required this.actorType,
    required this.actorId,
    required this.targetType,
    required this.targetId,
    required this.eventKey,
    required this.message,
    required this.correlationId,
    required this.createdAt,
  });

  final int id;
  final String category;
  final String severity;
  final String actorType;
  final int actorId;
  final String targetType;
  final int targetId;
  final String eventKey;
  final String message;
  final String correlationId;
  final DateTime? createdAt;

  factory BusinessEvent.fromJson(Map<String, dynamic> json) {
    return BusinessEvent(
      id: _int(json['id']),
      category: _string(json['category'], fallback: 'system'),
      severity: _string(json['severity'], fallback: 'info'),
      actorType: _string(json['actor_type']),
      actorId: _int(json['actor_id']),
      targetType: _string(json['target_type']),
      targetId: _int(json['target_id']),
      eventKey: _string(json['event_key']),
      message: _string(json['message']),
      correlationId: _string(json['correlation_id']),
      createdAt: _date(json['created_at']),
    );
  }

  String get categoryLabel => businessEventCategoryLabel(category);
  String get severityLabel => businessEventSeverityLabel(severity);
  String get eventKeyLabel => businessEventKeyLabel(eventKey);
  String get actorLabel => _entityLabel(actorType, actorId);
  String get targetLabel => _entityLabel(targetType, targetId);

  String get messageLabel {
    if (message.trim().isEmpty) return eventKeyLabel;
    return _containsArabic(message) ? message : eventKeyLabel;
  }

  String get createdAtLabel => dateTimeLabel(createdAt);
}

class BusinessSummary {
  const BusinessSummary({
    required this.wallets,
    required this.walletBalance,
    required this.ledgerEntries,
    required this.ledgerTotal,
    required this.events,
    required this.priceSnapshots,
    required this.revenueRecords,
  });

  final int wallets;
  final String walletBalance;
  final int ledgerEntries;
  final String ledgerTotal;
  final int events;
  final int priceSnapshots;
  final int revenueRecords;

  factory BusinessSummary.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    return BusinessSummary(
      wallets: _int(data['wallets']),
      walletBalance: _string(data['wallet_balance'], fallback: '0.00'),
      ledgerEntries: _int(data['ledger_entries']),
      ledgerTotal: _string(data['ledger_total'], fallback: '0.00'),
      events: _int(data['events']),
      priceSnapshots: _int(data['price_snapshots']),
      revenueRecords: _int(data['revenue_records']),
    );
  }
}

class EventFilterOption {
  const EventFilterOption(this.value, this.label);

  final String value;
  final String label;
}

const businessEventCategoryOptions = <EventFilterOption>[
  EventFilterOption('', 'كل الفئات'),
  EventFilterOption('manager', 'الإدارة'),
  EventFilterOption('subscriber', 'المشتركين'),
  EventFilterOption('card', 'الكروت'),
  EventFilterOption('financial', 'المالية'),
  EventFilterOption('system', 'النظام'),
  EventFilterOption('security', 'الأمان'),
  EventFilterOption('radius', 'الريدياس'),
  EventFilterOption('notification', 'التنبيهات'),
];

const businessEventSeverityOptions = <EventFilterOption>[
  EventFilterOption('', 'كل الخطورات'),
  EventFilterOption('debug', 'تشخيص'),
  EventFilterOption('info', 'معلومة'),
  EventFilterOption('warning', 'تنبيه'),
  EventFilterOption('error', 'خطأ'),
  EventFilterOption('critical', 'حرجة'),
];

String businessEventCategoryLabel(String value) {
  return switch (value) {
    'manager' => 'الإدارة',
    'subscriber' => 'المشتركين',
    'card' => 'الكروت',
    'financial' => 'المالية',
    'system' => 'النظام',
    'security' => 'الأمان',
    'radius' => 'الريدياس',
    'notification' => 'التنبيهات',
    _ => value.trim().isEmpty ? 'النظام' : 'فئة غير مصنفة',
  };
}

String businessEventSeverityLabel(String value) {
  return switch (value) {
    'debug' => 'تشخيص',
    'info' => 'معلومة',
    'warning' => 'تنبيه',
    'error' => 'خطأ',
    'critical' => 'حرجة',
    _ => value.trim().isEmpty ? 'معلومة' : 'غير محددة',
  };
}

String businessEventKeyLabel(String value) {
  return switch (value) {
    'ledger.payment' => 'تسجيل دفعة مالية',
    'ledger.renewal' => 'تجديد مالي',
    'ledger.debt' => 'تسجيل دين',
    'ledger.loan' => 'تسجيل سلفة',
    'ledger.discount' => 'تسجيل خصم',
    'ledger.wallet_recharge' => 'شحن محفظة',
    'ledger.card_sale' => 'بيع كروت',
    'ledger.batch_creation' => 'إنشاء حزمة كروت',
    'ledger.profit_share' => 'توزيع أرباح',
    'ledger.reversal' => 'قيد عكسي',
    'ledger.correction' => 'تصحيح مالي',
    'wallet.created' => 'إنشاء محفظة',
    'wallet.credit' => 'إضافة رصيد للمحفظة',
    'wallet.debit' => 'خصم رصيد من المحفظة',
    'price_snapshot.captured' => 'حفظ سعر مرجعي',
    'operator.review' => 'مراجعة تشغيل',
    _ => value.trim().isEmpty ? 'حدث نظام' : 'حدث نظام',
  };
}

String eventTypeDetail(String value) {
  final text = value.trim();
  return text.isEmpty ? 'لا يوجد مفتاح داخلي' : text;
}

String _entityLabel(String type, int id) {
  final label = switch (type) {
    'admin' => 'مدير',
    'api_token' => 'مفتاح ربط',
    'subscriber' => 'مشترك',
    'card_user' => 'مستخدم كرت',
    'card' => 'كرت',
    'batch' => 'حزمة كروت',
    'router' || 'nas' => 'راوتر',
    'wallet' => 'محفظة',
    'ledger' => 'قيد مالي',
    'system' => 'النظام',
    _ => type.trim().isEmpty ? 'غير محدد' : 'عنصر نظام',
  };
  return id > 0 ? '$label #$id' : label;
}

String dateTimeLabel(DateTime? date) {
  if (date == null) return 'غير محدد';
  String two(int value) => value.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)} '
      '${two(date.hour)}:${two(date.minute)}';
}

Map<String, dynamic> _data(Map<String, dynamic> json) {
  final data = json['data'];
  return data is Map<String, dynamic>
      ? data
      : _map(data).isEmpty
          ? json
          : _map(data);
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

DateTime? _date(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text.replaceFirst('Z', ''));
}

bool _containsArabic(String value) {
  return value.runes.any(
    (r) =>
        (r >= 0x0600 && r <= 0x06FF) ||
        (r >= 0x0750 && r <= 0x077F) ||
        (r >= 0x08A0 && r <= 0x08FF) ||
        (r >= 0xFB50 && r <= 0xFDFF) ||
        (r >= 0xFE70 && r <= 0xFEFF),
  );
}
