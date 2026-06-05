class HotspotPortalUser {
  const HotspotPortalUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.phone,
    required this.walletBalance,
    required this.currency,
  });

  final String id;
  final String username;
  final String displayName;
  final String phone;
  final String walletBalance;
  final String currency;

  String get title => displayName.isNotEmpty ? displayName : username;

  String get walletLabel {
    final amount = walletBalance.trim();
    if (amount.isEmpty) return currency;
    return currency.isEmpty ? amount : '$amount $currency';
  }

  factory HotspotPortalUser.fromJson(Map<String, dynamic> json) {
    return HotspotPortalUser(
      id: _string(json['id']),
      username: _string(json['username']),
      displayName: _string(json['display_name']),
      phone: _string(json['phone']),
      walletBalance: _string(json['wallet_balance']),
      currency: _string(json['currency']),
    );
  }
}

class HotspotPortalCapabilities {
  const HotspotPortalCapabilities({
    required this.catalog,
    required this.purchase,
    required this.myCards,
    required this.sms,
  });

  final bool catalog;
  final bool purchase;
  final bool myCards;
  final bool sms;

  factory HotspotPortalCapabilities.fromJson(Map<String, dynamic> json) {
    return HotspotPortalCapabilities(
      catalog: _bool(json['catalog']),
      purchase: _bool(json['purchase']),
      myCards: _bool(json['my_cards']),
      sms: _bool(json['sms']),
    );
  }

  static const empty = HotspotPortalCapabilities(
    catalog: false,
    purchase: false,
    myCards: false,
    sms: false,
  );
}

class HotspotCatalogItem {
  const HotspotCatalogItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.profileName,
    required this.durationLabel,
    required this.quotaLabel,
    required this.available,
  });

  final String id;
  final String name;
  final String description;
  final String price;
  final String currency;
  final String profileName;
  final String durationLabel;
  final String quotaLabel;
  final bool available;

  String get title => name.isNotEmpty ? name : 'باقة كرت إلكتروني';

  String get priceLabel {
    if (price.trim().isEmpty) return 'السعر غير محدد';
    return currency.trim().isEmpty ? price : '$price $currency';
  }

  factory HotspotCatalogItem.fromJson(Map<String, dynamic> json) {
    return HotspotCatalogItem(
      id: _string(json['id']),
      name: _string(json['name']),
      description: _string(json['description']),
      price: _string(json['price']),
      currency: _string(json['currency']),
      profileName: _string(json['profile_name']),
      durationLabel: _string(json['duration_label']),
      quotaLabel: _string(json['quota_label']),
      available: _bool(json['available']),
    );
  }
}

class HotspotPortalCard {
  const HotspotPortalCard({
    required this.username,
    required this.password,
    required this.profileName,
    required this.durationLabel,
    required this.quotaLabel,
    required this.expiresAt,
    required this.used,
    required this.revoked,
  });

  final String username;
  final String password;
  final String profileName;
  final String durationLabel;
  final String quotaLabel;
  final DateTime? expiresAt;
  final bool used;
  final bool revoked;

  bool get expired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now().toUtc());

  String get statusLabel {
    if (revoked) return 'ملغاة';
    if (used) return 'مستخدمة';
    if (expired) return 'منتهية';
    return 'جاهزة';
  }

  factory HotspotPortalCard.fromJson(Map<String, dynamic> json) {
    return HotspotPortalCard(
      username: _string(json['username']),
      password: _string(json['password']),
      profileName: _string(json['profile_name']),
      durationLabel: _string(json['duration_label']),
      quotaLabel: _string(json['quota_label']),
      expiresAt: _date(json['expires_at']),
      used: _bool(json['used']),
      revoked: _bool(json['revoked']),
    );
  }
}

class HotspotOwnedCard {
  const HotspotOwnedCard({
    required this.purchaseId,
    required this.packageId,
    required this.packageName,
    required this.purchasedAt,
    required this.amount,
    required this.currency,
    required this.card,
  });

  final String purchaseId;
  final String packageId;
  final String packageName;
  final DateTime? purchasedAt;
  final String amount;
  final String currency;
  final HotspotPortalCard card;

  String get amountLabel {
    if (amount.trim().isEmpty) return currency;
    return currency.trim().isEmpty ? amount : '$amount $currency';
  }

  factory HotspotOwnedCard.fromJson(Map<String, dynamic> json) {
    return HotspotOwnedCard(
      purchaseId: _string(json['purchase_id']),
      packageId: _string(json['package_id']),
      packageName: _string(json['package_name']),
      purchasedAt: _date(json['purchased_at']),
      amount: _string(json['amount']),
      currency: _string(json['currency']),
      card: HotspotPortalCard.fromJson(_map(json['card'])),
    );
  }
}

class HotspotPortalLoginResult {
  const HotspotPortalLoginResult({
    required this.token,
    required this.expiresIn,
    required this.user,
  });

  final String token;
  final int expiresIn;
  final HotspotPortalUser user;

  factory HotspotPortalLoginResult.fromJson(Map<String, dynamic> json) {
    return HotspotPortalLoginResult(
      token: _string(json['token']),
      expiresIn: _int(json['expires_in']),
      user: HotspotPortalUser.fromJson(_map(json['user'])),
    );
  }
}

class HotspotPortalProfile {
  const HotspotPortalProfile({
    required this.user,
    required this.capabilities,
  });

  final HotspotPortalUser user;
  final HotspotPortalCapabilities capabilities;

  factory HotspotPortalProfile.fromJson(Map<String, dynamic> json) {
    return HotspotPortalProfile(
      user: HotspotPortalUser.fromJson(_map(json['user'])),
      capabilities: HotspotPortalCapabilities.fromJson(
        _map(json['capabilities']),
      ),
    );
  }
}

class HotspotPurchaseResult {
  const HotspotPurchaseResult({
    required this.purchaseId,
    required this.walletBalanceAfter,
    required this.card,
  });

  final String purchaseId;
  final String walletBalanceAfter;
  final HotspotPortalCard card;

  factory HotspotPurchaseResult.fromJson(Map<String, dynamic> json) {
    return HotspotPurchaseResult(
      purchaseId: _string(json['purchase_id']),
      walletBalanceAfter: _string(json['wallet_balance_after']),
      card: HotspotPortalCard.fromJson(_map(json['card'])),
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

String _string(Object? value) => (value ?? '').toString().trim();

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(_string(value)) ?? 0;
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
