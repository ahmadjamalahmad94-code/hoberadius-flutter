import 'subscriber_model.dart';

class Subscriber360 {
  const Subscriber360({
    required this.subscriber,
    required this.plan,
    required this.overview,
    required this.financial,
    required this.usage,
    required this.services,
    required this.devices,
    required this.timeline,
    required this.loginEvents,
    required this.notes,
  });

  final Subscriber subscriber;
  final Map<String, dynamic> plan;
  final Map<String, dynamic> overview;
  final Subscriber360Financial financial;
  final Subscriber360Usage usage;
  final Map<String, dynamic> services;
  final List<Subscriber360Device> devices;
  final List<Subscriber360TimelineItem> timeline;
  final List<Map<String, dynamic>> loginEvents;
  final String notes;

  factory Subscriber360.fromJson(Map<String, dynamic> json) {
    final devices = json['devices'];
    final timeline = json['timeline'];
    final loginEvents = json['login_events'];
    return Subscriber360(
      subscriber: Subscriber.fromJson(_map(json['subscriber'])),
      plan: _map(json['plan']),
      overview: _map(json['overview']),
      financial: Subscriber360Financial.fromJson(_map(json['financial'])),
      usage: Subscriber360Usage.fromJson(_map(json['usage'])),
      services: _map(json['services']),
      devices: devices is List
          ? devices
              .whereType<Map>()
              .map((item) => Subscriber360Device.fromJson(_map(item)))
              .toList()
          : const [],
      timeline: timeline is List
          ? timeline
              .whereType<Map>()
              .map((item) => Subscriber360TimelineItem.fromJson(_map(item)))
              .toList()
          : const [],
      loginEvents: loginEvents is List
          ? loginEvents.whereType<Map>().map(_map).toList()
          : const [],
      notes: _string(json['notes']),
    );
  }

  String get planName => _string(plan['name'], fallback: 'بدون باقة');
  String get status => subscriber.status;
  String get serviceType =>
      _string(overview['service_type'], fallback: subscriber.serviceType);
  double get walletBalance => _double(overview['wallet_balance']);
  double get openDebt => _double(overview['open_debt']);
  int get sessionCount => _int(overview['session_count']);
}

class Subscriber360Financial {
  const Subscriber360Financial({
    required this.totalPaid,
    required this.totalDiscount,
    required this.openLoanAmount,
    required this.walletBalance,
    required this.payments,
    required this.loans,
    required this.ledger,
  });

  final double totalPaid;
  final double totalDiscount;
  final double openLoanAmount;
  final double walletBalance;
  final List<Map<String, dynamic>> payments;
  final List<Map<String, dynamic>> loans;
  final List<Map<String, dynamic>> ledger;

  factory Subscriber360Financial.fromJson(Map<String, dynamic> json) {
    return Subscriber360Financial(
      totalPaid: _double(json['total_paid']),
      totalDiscount: _double(json['total_discount']),
      openLoanAmount: _double(json['open_loan_amount']),
      walletBalance: _double(json['wallet_balance']),
      payments: _mapList(json['payments']),
      loans: _mapList(json['loans']),
      ledger: _mapList(json['ledger']),
    );
  }
}

class Subscriber360Usage {
  const Subscriber360Usage({
    required this.sessions,
    required this.totalSeconds,
    required this.downloadBytes,
    required this.uploadBytes,
  });

  final List<Map<String, dynamic>> sessions;
  final int totalSeconds;
  final int downloadBytes;
  final int uploadBytes;

  factory Subscriber360Usage.fromJson(Map<String, dynamic> json) {
    return Subscriber360Usage(
      sessions: _mapList(json['sessions']),
      totalSeconds: _int(json['total_seconds']),
      downloadBytes: _int(json['download_bytes']),
      uploadBytes: _int(json['upload_bytes']),
    );
  }

  int get totalBytes => downloadBytes + uploadBytes;
}

class Subscriber360Device {
  const Subscriber360Device({required this.mac, required this.source});

  final String mac;
  final String source;

  factory Subscriber360Device.fromJson(Map<String, dynamic> json) {
    return Subscriber360Device(
      mac: _string(json['mac']),
      source: _string(json['source'], fallback: 'session'),
    );
  }
}

class Subscriber360TimelineItem {
  const Subscriber360TimelineItem({
    required this.createdAt,
    required this.label,
  });

  final String createdAt;
  final String label;

  factory Subscriber360TimelineItem.fromJson(Map<String, dynamic> json) {
    final item = _map(json['item']);
    return Subscriber360TimelineItem(
      createdAt: _string(json['created_at']),
      label: _timelineLabel(item),
    );
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, val) => MapEntry('$key', val));
  return const {};
}

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<Map>().map(_map).toList();
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

double _double(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _timelineLabel(Map<String, dynamic> item) {
  final type = _string(item['entry_type']);
  if (type == 'payment') return 'دفعة مالية';
  if (type == 'renewal') return 'تجديد اشتراك';
  if (type == 'loan') return 'سلفة';
  if (item.containsKey('reply')) {
    return 'محاولة دخول: ${_string(item['reply'])}';
  }
  if (item.containsKey('amount')) return 'حركة مالية';
  return _string(item['message'], fallback: 'حدث على حساب المشترك');
}
