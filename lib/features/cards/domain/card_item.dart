import 'card_parsing.dart';

/// A single generated card (one row in `cards`).
class CardItem {
  CardItem({
    this.id,
    required this.username,
    this.password = '',
    this.batchId,
    this.planId,
    this.used = false,
    this.revoked = false,
    this.expireAt,
    this.firstUsedAt,
    this.createdAt,
    this.lockedMac = '',
    this.usedByMac = '',
  });

  /// MAC lock / the device that used the card (updated servers).
  final String lockedMac;
  final String usedByMac;

  final int? id;
  final String username;
  final String password;

  /// permguard: without `scope.view_passwords` / `cards.print` the server
  /// sends the password masked (`••••••`). Never shown, copied or exported
  /// as if it were the real password.
  bool get passwordMasked => isMaskedCardPassword(password);

  final int? batchId;
  final int? planId;
  final bool used;
  final bool revoked;
  final DateTime? expireAt;
  final DateTime? firstUsedAt;
  final DateTime? createdAt;

  factory CardItem.fromJson(Map<String, dynamic> j) => CardItem(
        id: j['id'] as int?,
        username: (j['username'] ?? '').toString(),
        password: (j['password'] ?? '').toString(),
        batchId: j['batch_id'] as int?,
        planId: j['plan_id'] as int?,
        used: j['used'] == true || j['used'] == 1,
        revoked: j['revoked'] == true || j['revoked'] == 1,
        expireAt: cardParseDate(j['expire_at']),
        firstUsedAt: cardParseDate(j['first_used_at']),
        createdAt: cardParseDate(j['created_at']),
        lockedMac: (j['locked_mac'] ?? '').toString(),
        usedByMac: (j['used_by_mac'] ?? '').toString(),
      );
}

/// A password the server masked (only bullets / asterisks), not a real one.
bool isMaskedCardPassword(String value) {
  final v = value.trim();
  return v.isNotEmpty && RegExp(r'^[•\*●∙·]+$').hasMatch(v);
}

/// How a card password reads on screen: the value, or «••••» (hidden by the
/// server — the admin lacks the reveal permission).
String cardPasswordDisplay(String value) =>
    isMaskedCardPassword(value) ? '••••' : value;
