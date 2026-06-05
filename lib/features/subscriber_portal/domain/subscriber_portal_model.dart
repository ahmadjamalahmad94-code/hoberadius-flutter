class SubscriberPortalCapabilities {
  const SubscriberPortalCapabilities({
    required this.dashboard,
    required this.requests,
    required this.loanRequest,
    required this.renewalRequest,
    required this.supportRequest,
  });

  final bool dashboard;
  final bool requests;
  final bool loanRequest;
  final bool renewalRequest;
  final bool supportRequest;

  factory SubscriberPortalCapabilities.fromJson(Map<String, dynamic> json) {
    return SubscriberPortalCapabilities(
      dashboard: _bool(json['dashboard']),
      requests: _bool(json['requests']),
      loanRequest: _bool(json['loan_request']),
      renewalRequest: _bool(json['renewal_request']),
      supportRequest: _bool(json['support_request']),
    );
  }

  static const empty = SubscriberPortalCapabilities(
    dashboard: false,
    requests: false,
    loanRequest: false,
    renewalRequest: false,
    supportRequest: false,
  );
}

class SubscriberPortalSubscriber {
  const SubscriberPortalSubscriber({
    required this.id,
    required this.username,
    required this.fullName,
    required this.mobile,
    required this.email,
    required this.status,
    required this.serviceType,
  });

  final int id;
  final String username;
  final String fullName;
  final String mobile;
  final String email;
  final String status;
  final String serviceType;

  String get title => fullName.isNotEmpty ? fullName : username;

  String get statusLabel => _statusLabel(status);

  factory SubscriberPortalSubscriber.fromJson(Map<String, dynamic> json) {
    return SubscriberPortalSubscriber(
      id: _int(json['id']),
      username: _string(json['username']),
      fullName: _string(json['full_name']),
      mobile: _string(json['mobile']),
      email: _string(json['email']),
      status: _string(json['status']),
      serviceType: _string(json['service_type']),
    );
  }
}

class SubscriberPortalLoginResult {
  const SubscriberPortalLoginResult({
    required this.token,
    required this.expiresIn,
    required this.subscriber,
    required this.capabilities,
  });

  final String token;
  final int expiresIn;
  final SubscriberPortalSubscriber subscriber;
  final SubscriberPortalCapabilities capabilities;

  factory SubscriberPortalLoginResult.fromJson(Map<String, dynamic> json) {
    return SubscriberPortalLoginResult(
      token: _string(json['token']),
      expiresIn: _int(json['expires_in']),
      subscriber:
          SubscriberPortalSubscriber.fromJson(_map(json['subscriber'])),
      capabilities:
          SubscriberPortalCapabilities.fromJson(_map(json['capabilities'])),
    );
  }
}

class SubscriberPortalProfile {
  const SubscriberPortalProfile({
    required this.subscriber,
    required this.capabilities,
  });

  final SubscriberPortalSubscriber subscriber;
  final SubscriberPortalCapabilities capabilities;

  factory SubscriberPortalProfile.fromJson(Map<String, dynamic> json) {
    return SubscriberPortalProfile(
      subscriber:
          SubscriberPortalSubscriber.fromJson(_map(json['subscriber'])),
      capabilities:
          SubscriberPortalCapabilities.fromJson(_map(json['capabilities'])),
    );
  }
}

class SubscriberPortalDashboard {
  const SubscriberPortalDashboard({
    required this.subscriber,
    required this.plan,
    required this.subscription,
    required this.usage,
    required this.wallet,
    required this.debt,
    required this.loanPolicy,
    required this.sessions,
    required this.loans,
    required this.payments,
    required this.notifications,
    required this.cards,
    required this.walledGardenNote,
  });

  final SubscriberPortalSubscriber subscriber;
  final SubscriberPortalPlan plan;
  final SubscriberPortalSubscription subscription;
  final SubscriberPortalUsage usage;
  final SubscriberPortalWallet wallet;
  final double debt;
  final SubscriberPortalLoanPolicy loanPolicy;
  final List<SubscriberPortalSession> sessions;
  final List<Map<String, dynamic>> loans;
  final List<Map<String, dynamic>> payments;
  final List<Map<String, dynamic>> notifications;
  final List<Map<String, dynamic>> cards;
  final String walledGardenNote;

  bool get hasDebt => debt > 0;

  factory SubscriberPortalDashboard.fromJson(Map<String, dynamic> json) {
    return SubscriberPortalDashboard(
      subscriber:
          SubscriberPortalSubscriber.fromJson(_map(json['subscriber'])),
      plan: SubscriberPortalPlan.fromJson(_map(json['plan'])),
      subscription:
          SubscriberPortalSubscription.fromJson(_map(json['subscription'])),
      usage: SubscriberPortalUsage.fromJson(_map(json['usage'])),
      wallet: SubscriberPortalWallet.fromJson(_map(json['wallet'])),
      debt: _double(json['debt']),
      loanPolicy: SubscriberPortalLoanPolicy.fromJson(
        _map(json['loan_policy']),
      ),
      sessions: _list(json['sessions'])
          .map(SubscriberPortalSession.fromJson)
          .toList(),
      loans: _list(json['loans']),
      payments: _list(json['payments']),
      notifications: _list(json['notifications']),
      cards: _list(json['cards']),
      walledGardenNote: _string(json['walled_garden_note']),
    );
  }
}

class SubscriberPortalPlan {
  const SubscriberPortalPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.currency,
    required this.durationMinutes,
  });

  final int id;
  final String name;
  final double price;
  final String currency;
  final int durationMinutes;

  String get title => name.isEmpty ? 'الباقة غير محددة' : name;

  String get priceLabel {
    if (price <= 0) return 'السعر غير محدد';
    final amount = price.toStringAsFixed(price.truncateToDouble() == price ? 0 : 2);
    return currency.isEmpty ? amount : '$amount $currency';
  }

  String get durationLabel {
    if (durationMinutes <= 0) return 'مدة غير محددة';
    if (durationMinutes % 1440 == 0) return '${durationMinutes ~/ 1440} يوم';
    if (durationMinutes % 60 == 0) return '${durationMinutes ~/ 60} ساعة';
    return '$durationMinutes دقيقة';
  }

  factory SubscriberPortalPlan.fromJson(Map<String, dynamic> json) {
    return SubscriberPortalPlan(
      id: _int(json['id']),
      name: _string(json['name']),
      price: _double(json['price']),
      currency: _string(json['currency']),
      durationMinutes: _int(json['duration_minutes']),
    );
  }
}

class SubscriberPortalSubscription {
  const SubscriberPortalSubscription({
    required this.status,
    required this.expireAt,
    required this.remainingDays,
    required this.expiredViewAllowed,
  });

  final String status;
  final DateTime? expireAt;
  final int? remainingDays;
  final bool expiredViewAllowed;

  String get statusLabel => _statusLabel(status);

  String get remainingLabel {
    final days = remainingDays;
    if (days == null) return 'غير محدد';
    if (days < 0) return 'منتهي منذ ${days.abs()} يوم';
    if (days == 0) return 'ينتهي اليوم';
    return 'متبقي $days يوم';
  }

  factory SubscriberPortalSubscription.fromJson(Map<String, dynamic> json) {
    return SubscriberPortalSubscription(
      status: _string(json['status']),
      expireAt: _date(json['expire_at']),
      remainingDays:
          json.containsKey('remaining_days') ? _int(json['remaining_days']) : null,
      expiredViewAllowed: _bool(json['expired_view_allowed']),
    );
  }
}

class SubscriberPortalUsage {
  const SubscriberPortalUsage({
    required this.uploadBytes,
    required this.downloadBytes,
    required this.sessionSeconds,
  });

  final int uploadBytes;
  final int downloadBytes;
  final int sessionSeconds;

  String get uploadLabel => _bytes(uploadBytes);
  String get downloadLabel => _bytes(downloadBytes);
  String get totalLabel => _bytes(uploadBytes + downloadBytes);
  String get sessionLabel => _durationSeconds(sessionSeconds);

  factory SubscriberPortalUsage.fromJson(Map<String, dynamic> json) {
    return SubscriberPortalUsage(
      uploadBytes: _int(json['upload_bytes']),
      downloadBytes: _int(json['download_bytes']),
      sessionSeconds: _int(json['session_seconds']),
    );
  }
}

class SubscriberPortalWallet {
  const SubscriberPortalWallet({
    required this.balance,
    required this.balanceMinor,
    required this.currency,
  });

  final String balance;
  final int balanceMinor;
  final String currency;

  String get balanceLabel {
    if (balance.isNotEmpty) return currency.isEmpty ? balance : '$balance $currency';
    final amount = (balanceMinor / 100).toStringAsFixed(2);
    return currency.isEmpty ? amount : '$amount $currency';
  }

  factory SubscriberPortalWallet.fromJson(Map<String, dynamic> json) {
    return SubscriberPortalWallet(
      balance: _string(json['balance']),
      balanceMinor: _int(json['balance_minor']),
      currency: _string(json['currency']),
    );
  }
}

class SubscriberPortalLoanPolicy {
  const SubscriberPortalLoanPolicy({
    required this.enabled,
    required this.autoApprove,
    required this.allowedMinutes,
    required this.reason,
  });

  final bool enabled;
  final bool autoApprove;
  final int allowedMinutes;
  final String reason;

  String get allowedLabel {
    if (!enabled || allowedMinutes <= 0) return 'السلفة غير متاحة';
    if (allowedMinutes % 1440 == 0) return '${allowedMinutes ~/ 1440} يوم';
    if (allowedMinutes % 60 == 0) return '${allowedMinutes ~/ 60} ساعة';
    return '$allowedMinutes دقيقة';
  }

  factory SubscriberPortalLoanPolicy.fromJson(Map<String, dynamic> json) {
    return SubscriberPortalLoanPolicy(
      enabled: _bool(json['enabled']),
      autoApprove: _bool(json['auto_approve']),
      allowedMinutes: _int(json['allowed_minutes']),
      reason: _string(json['reason']),
    );
  }

  static const empty = SubscriberPortalLoanPolicy(
    enabled: false,
    autoApprove: false,
    allowedMinutes: 0,
    reason: '',
  );
}

class SubscriberPortalSession {
  const SubscriberPortalSession({
    required this.id,
    required this.nasIp,
    required this.framedIp,
    required this.startedAt,
    required this.stoppedAt,
    required this.seconds,
    required this.uploadBytes,
    required this.downloadBytes,
  });

  final String id;
  final String nasIp;
  final String framedIp;
  final DateTime? startedAt;
  final DateTime? stoppedAt;
  final int seconds;
  final int uploadBytes;
  final int downloadBytes;

  bool get online => stoppedAt == null;
  String get durationLabel => _durationSeconds(seconds);
  String get trafficLabel => _bytes(uploadBytes + downloadBytes);

  factory SubscriberPortalSession.fromJson(Map<String, dynamic> json) {
    return SubscriberPortalSession(
      id: _string(json['acctsessionid']),
      nasIp: _string(json['nasipaddress']),
      framedIp: _string(json['framedipaddress']),
      startedAt: _date(json['acctstarttime']),
      stoppedAt: _date(json['acctstoptime']),
      seconds: _int(json['acctsessiontime']),
      uploadBytes: _int(json['acctinputoctets']),
      downloadBytes: _int(json['acctoutputoctets']),
    );
  }
}

class SubscriberPortalRequest {
  const SubscriberPortalRequest({
    required this.id,
    required this.type,
    required this.status,
    required this.reason,
    required this.createdAt,
    required this.result,
  });

  final int id;
  final String type;
  final String status;
  final String reason;
  final DateTime? createdAt;
  final Map<String, dynamic> result;

  String get typeLabel => switch (type) {
        'loan' => 'طلب سلفة',
        'renewal' => 'طلب تجديد',
        'support' => 'طلب دعم',
        _ => 'طلب خدمة',
      };

  String get statusLabel => switch (status) {
        'auto_approved' => 'معتمد تلقائيًا',
        'requires_approval' => 'بانتظار مراجعة الإدارة',
        'pending' => 'بانتظار المراجعة',
        'approved' => 'مقبول',
        'rejected' => 'مرفوض',
        'closed' => 'مغلق',
        _ => _statusLabel(status),
      };

  factory SubscriberPortalRequest.fromJson(Map<String, dynamic> json) {
    return SubscriberPortalRequest(
      id: _int(json['id']),
      type: _string(json['request_type']),
      status: _string(json['status']),
      reason: _string(json['reason']),
      createdAt: _date(json['created_at']),
      result: _map(json['result']),
    );
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return const {};
}

List<Map<String, dynamic>> _list(Object? value) {
  if (value is! List) return const [];
  return value.whereType<Map>().map(_map).toList();
}

String _string(Object? value) => (value ?? '').toString().trim();

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(_string(value)) ?? 0;
}

double _double(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(_string(value)) ?? 0;
}

bool _bool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = _string(value).toLowerCase();
  return {'1', 'true', 'yes', 'on', 'enabled', 'active'}.contains(text);
}

DateTime? _date(Object? value) {
  final text = _string(value);
  if (text.isEmpty) return null;
  return DateTime.tryParse(text)?.toUtc();
}

String _statusLabel(String value) {
  final key = value.trim().toLowerCase();
  return switch (key) {
    'enabled' || 'active' => 'مفعّل',
    'disabled' || 'inactive' => 'موقوف',
    'expired' => 'منتهي',
    'pending' => 'بانتظار المراجعة',
    'suspended' => 'معلّق',
    _ => key.isEmpty ? 'غير محدد' : value,
  };
}

String _bytes(int value) {
  if (value <= 0) return '0 ب';
  const units = ['ب', 'ك.ب', 'م.ب', 'ج.ب', 'ت.ب'];
  var size = value.toDouble();
  var unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit++;
  }
  final text = size >= 10 ? size.toStringAsFixed(0) : size.toStringAsFixed(1);
  return '$text ${units[unit]}';
}

String _durationSeconds(int seconds) {
  if (seconds <= 0) return '0 دقيقة';
  final minutes = seconds ~/ 60;
  if (minutes < 60) return '$minutes دقيقة';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours < 24) return rest == 0 ? '$hours ساعة' : '$hours ساعة و$rest دقيقة';
  final days = hours ~/ 24;
  final restHours = hours % 24;
  return restHours == 0 ? '$days يوم' : '$days يوم و$restHours ساعة';
}
