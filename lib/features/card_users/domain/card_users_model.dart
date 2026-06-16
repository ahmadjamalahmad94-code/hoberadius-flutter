import '../../../core/format/currency.dart';

class CardUser {
  const CardUser({
    required this.id,
    required this.displayName,
    required this.mobile,
    required this.email,
    required this.status,
    required this.balance,
    required this.pendingBalance,
    required this.spent,
    required this.walletCurrency,
    required this.purchaseCount,
    required this.ownedCardsCount,
    required this.hasPortalPassword,
  });

  final int id;
  final String displayName;
  final String mobile;
  final String email;
  final String status;
  final num balance;
  final num pendingBalance;
  final num spent;
  final String walletCurrency;
  final int purchaseCount;
  final int ownedCardsCount;
  final bool hasPortalPassword;

  factory CardUser.fromJson(Map<String, dynamic> json) {
    return CardUser(
      id: _int(json['id']),
      displayName: _string(json['display_name']),
      mobile: _string(json['mobile']),
      email: _string(json['email']),
      status: _string(json['status'], fallback: 'active'),
      balance: _num(json['balance']),
      pendingBalance: _num(json['pending_balance']),
      spent: _num(json['spent']),
      walletCurrency: _string(json['wallet_currency'], fallback: kDefaultCurrency),
      purchaseCount: _int(json['purchase_count']),
      ownedCardsCount: _int(json['owned_cards_count']),
      hasPortalPassword: _bool(json['has_portal_password']),
    );
  }

  String get title => displayName.isEmpty ? 'مستخدم كروت #$id' : displayName;
  bool get isActive => status == 'active';

  String get statusLabel => switch (status) {
        'active' => 'مفعل',
        'inactive' => 'غير مفعل',
        'disabled' => 'معطل',
        'suspended' => 'موقوف',
        'blocked' => 'محظور',
        _ => status.trim().isEmpty ? 'غير محدد' : 'حالة غير معروفة',
      };
}

class CardUsersSummary {
  const CardUsersSummary({
    required this.users,
    required this.active,
    required this.cards,
    required this.purchases,
    required this.balance,
    required this.currency,
  });

  final int users;
  final int active;
  final int cards;
  final int purchases;
  final num balance;
  final String currency;

  factory CardUsersSummary.fromJson(Map<String, dynamic> json) {
    return CardUsersSummary(
      users: _int(json['users']),
      active: _int(json['active']),
      cards: _int(json['cards']),
      purchases: _int(json['purchases']),
      balance: _num(json['balance']),
      currency: _string(json['currency'], fallback: kDefaultCurrency),
    );
  }
}

class CardUsersPage {
  const CardUsersPage({
    required this.items,
    required this.summary,
  });

  final List<CardUser> items;
  final CardUsersSummary summary;

  factory CardUsersPage.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    final items = (data['items'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CardUser.fromJson)
        .toList();
    return CardUsersPage(
      items: items,
      summary: CardUsersSummary.fromJson(
        data['summary'] is Map<String, dynamic>
            ? data['summary'] as Map<String, dynamic>
            : const {},
      ),
    );
  }
}

class MarketplacePackage {
  const MarketplacePackage({
    required this.id,
    required this.name,
    required this.planName,
    required this.price,
    required this.currency,
    required this.durationMinutes,
    required this.speedDownKbps,
    required this.speedUpKbps,
    required this.quotaTotalMb,
    required this.active,
    required this.cardColor,
  });

  final int id;
  final String name;
  final String planName;
  final num price;
  final String currency;
  final int durationMinutes;
  final int speedDownKbps;
  final int speedUpKbps;
  final int quotaTotalMb;
  final bool active;
  final String cardColor;

  factory MarketplacePackage.fromJson(Map<String, dynamic> json) {
    return MarketplacePackage(
      id: _int(json['id']),
      name: _string(json['name']),
      planName: _string(json['plan_name']),
      price: _num(json['price']),
      currency: _string(json['currency'], fallback: kDefaultCurrency),
      durationMinutes: _int(
        json['display_duration_minutes'] ?? json['duration_minutes'],
      ),
      speedDownKbps: _int(
        json['display_speed_down_kbps'] ?? json['speed_down_kbps'],
      ),
      speedUpKbps: _int(
        json['display_speed_up_kbps'] ?? json['speed_up_kbps'],
      ),
      quotaTotalMb: _int(json['plan_quota_total_mb'] ?? json['quota_total_mb']),
      active: _bool(json['active'], fallback: true),
      cardColor: _string(json['card_color'], fallback: '#14b8a6'),
    );
  }

  String get title => name.isEmpty ? 'باقة كروت #$id' : name;

  String get speedLabel {
    if (speedDownKbps <= 0 && speedUpKbps <= 0) return 'بدون سرعة محددة';
    return '${_kbps(speedDownKbps)} / ${_kbps(speedUpKbps)}';
  }

  String get durationLabel {
    if (durationMinutes <= 0) return 'مدة غير محددة';
    if (durationMinutes % 1440 == 0) return '${durationMinutes ~/ 1440} يوم';
    if (durationMinutes % 60 == 0) return '${durationMinutes ~/ 60} ساعة';
    return '$durationMinutes دقيقة';
  }
}

class CardUserWallet {
  const CardUserWallet({
    required this.id,
    required this.balance,
    required this.currency,
    required this.status,
  });

  final int id;
  final String balance;
  final String currency;
  final String status;

  factory CardUserWallet.fromJson(Map<String, dynamic> json) {
    return CardUserWallet(
      id: _int(json['id']),
      balance: _string(json['balance'], fallback: '0.00'),
      currency: _string(json['currency'], fallback: kDefaultCurrency),
      status: _string(json['status'], fallback: 'active'),
    );
  }
}

class CardUserPurchase {
  const CardUserPurchase({
    required this.id,
    required this.packageId,
    required this.cardId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final int packageId;
  final int cardId;
  final String amount;
  final String currency;
  final String status;
  final DateTime? createdAt;

  factory CardUserPurchase.fromJson(Map<String, dynamic> json) {
    return CardUserPurchase(
      id: _int(json['id']),
      packageId: _int(json['package_id']),
      cardId: _int(json['card_id']),
      amount: _string(json['amount'], fallback: '0.00'),
      currency: _string(json['currency'], fallback: kDefaultCurrency),
      status: _string(json['status']),
      createdAt: _date(json['created_at']),
    );
  }

  String get statusLabel => switch (status) {
        'completed' => 'مكتملة',
        'pending' => 'بانتظار الاعتماد',
        'failed' => 'فشلت',
        'cancelled' || 'canceled' => 'ملغاة',
        'refunded' => 'مسترجعة',
        _ => status.trim().isEmpty ? 'غير محددة' : 'حالة غير معروفة',
      };
}

class CardUserOwnedCard {
  const CardUserOwnedCard({
    required this.id,
    required this.username,
    required this.password,
    required this.used,
    required this.revoked,
    required this.createdAt,
    required this.firstUsedAt,
  });

  final int id;
  final String username;
  final String password;
  final bool used;
  final bool revoked;
  final DateTime? createdAt;
  final DateTime? firstUsedAt;

  factory CardUserOwnedCard.fromJson(Map<String, dynamic> json) {
    return CardUserOwnedCard(
      id: _int(json['id']),
      username: _string(json['username']),
      password: _string(json['password']),
      used: _bool(json['used']),
      revoked: _bool(json['revoked']),
      createdAt: _date(json['created_at']),
      firstUsedAt: _date(json['first_used_at']),
    );
  }

  String get statusLabel {
    if (revoked) return 'ملغاة';
    if (used) return 'مستخدمة';
    return 'جاهزة';
  }
}

class CardUserUsage {
  const CardUserUsage({
    required this.sessionsCount,
    required this.totalSeconds,
    required this.bytesIn,
    required this.bytesOut,
  });

  final int sessionsCount;
  final int totalSeconds;
  final int bytesIn;
  final int bytesOut;

  factory CardUserUsage.fromJson(Map<String, dynamic> json) {
    final sessions = json['sessions'];
    return CardUserUsage(
      sessionsCount: sessions is List ? sessions.length : 0,
      totalSeconds: _int(json['total_seconds']),
      bytesIn: _int(json['bytes_in']),
      bytesOut: _int(json['bytes_out']),
    );
  }
}

class CardUser360 {
  const CardUser360({
    required this.cardUser,
    required this.wallet,
    required this.purchases,
    required this.cards,
    required this.usage,
  });

  final CardUser cardUser;
  final CardUserWallet wallet;
  final List<CardUserPurchase> purchases;
  final List<CardUserOwnedCard> cards;
  final CardUserUsage usage;

  factory CardUser360.fromJson(Map<String, dynamic> json) {
    final data = _data(json);
    return CardUser360(
      cardUser: CardUser.fromJson(
        data['card_user'] is Map<String, dynamic>
            ? data['card_user'] as Map<String, dynamic>
            : const {},
      ),
      wallet: CardUserWallet.fromJson(
        data['wallet'] is Map<String, dynamic>
            ? data['wallet'] as Map<String, dynamic>
            : const {},
      ),
      purchases: (data['purchases'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CardUserPurchase.fromJson)
          .toList(),
      cards: (data['cards'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CardUserOwnedCard.fromJson)
          .toList(),
      usage: CardUserUsage.fromJson(
        data['usage'] is Map<String, dynamic>
            ? data['usage'] as Map<String, dynamic>
            : const {},
      ),
    );
  }
}

Map<String, dynamic> _data(Map<String, dynamic> json) {
  final data = json['data'];
  return data is Map<String, dynamic> ? data : json;
}

String _string(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

num _num(dynamic value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? 0;
}

bool _bool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().trim().toLowerCase();
  if (text == null || text.isEmpty) return fallback;
  return {'1', 'true', 'yes', 'on', 'active'}.contains(text);
}

DateTime? _date(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text.replaceFirst('Z', ''));
}

String _kbps(int value) {
  if (value <= 0) return '0';
  if (value >= 1024 && value % 1024 == 0) return '${value ~/ 1024} Mbps';
  return '$value Kbps';
}
