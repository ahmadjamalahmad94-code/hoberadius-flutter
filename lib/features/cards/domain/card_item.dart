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
  });

  final int? id;
  final String username;
  final String password;
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
      );
}
