import 'card_parsing.dart';

class RechargeDenomination {
  const RechargeDenomination({required this.value, required this.count});

  final num value;
  final int count;

  factory RechargeDenomination.fromJson(Map<String, dynamic> json) {
    return RechargeDenomination(
      value: cardParseNum(json['value'] ?? json['wallet_value']) ?? 0,
      count: cardParseInt(json['count']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'value': value,
        'count': count,
      };
}

class RechargeBatch {
  const RechargeBatch({
    this.id,
    this.batchCode = '',
    this.packageName = '',
    this.notes = '',
    this.status = 'active',
    this.count = 0,
    this.usedCount = 0,
    this.remainingCount = 0,
    this.totalValue = 0,
    this.denominations = const [],
    this.createdAt,
  });

  final int? id;
  final String batchCode;
  final String packageName;
  final String notes;
  final String status;
  final int count;
  final int usedCount;
  final int remainingCount;
  final num totalValue;
  final List<RechargeDenomination> denominations;
  final DateTime? createdAt;

  String get displayName {
    if (packageName.trim().isNotEmpty) return packageName;
    if (batchCode.trim().isNotEmpty) return batchCode;
    return 'حزمة شحن';
  }

  factory RechargeBatch.fromJson(Map<String, dynamic> json) {
    final denoms = (json['denominations'] as List? ?? const [])
        .whereType<Map>()
        .map(
          (item) => RechargeDenomination.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
    return RechargeBatch(
      id: cardParseInt(json['id']),
      batchCode: (json['batch_code'] ?? '').toString(),
      packageName: (json['package_name'] ?? '').toString(),
      notes: (json['notes'] ?? '').toString(),
      status: (json['status'] ?? 'active').toString(),
      count: cardParseInt(json['count']) ?? 0,
      usedCount: cardParseInt(json['used_count']) ?? 0,
      remainingCount: cardParseInt(json['remaining_count']) ?? 0,
      totalValue: cardParseNum(json['total_value']) ?? 0,
      denominations: denoms,
      createdAt: cardParseDate(json['created_at']),
    );
  }
}

class RechargeCard {
  const RechargeCard({
    this.id,
    this.batchId,
    this.username = '',
    this.password = '',
    this.walletValue = 0,
    this.used = false,
    this.firstUsedAt,
    this.createdAt,
  });

  final int? id;
  final int? batchId;
  final String username;
  final String password;
  final num walletValue;
  final bool used;
  final DateTime? firstUsedAt;
  final DateTime? createdAt;

  factory RechargeCard.fromJson(Map<String, dynamic> json) {
    return RechargeCard(
      id: cardParseInt(json['id']),
      batchId: cardParseInt(json['batch_id']),
      username: (json['username'] ?? '').toString(),
      password: (json['password'] ?? '').toString(),
      walletValue: cardParseNum(json['wallet_value']) ?? 0,
      used: cardParseBool(json['used']),
      firstUsedAt: cardParseDate(json['first_used_at']),
      createdAt: cardParseDate(json['created_at']),
    );
  }
}

class RechargeBatchesPage {
  const RechargeBatchesPage({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.perPage = 25,
    this.pages = 1,
    this.defaultDenominations = const [],
  });

  final List<RechargeBatch> items;
  final int total;
  final int page;
  final int perPage;
  final int pages;
  final List<num> defaultDenominations;

  factory RechargeBatchesPage.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] ?? json) as Map<String, dynamic>;
    return RechargeBatchesPage(
      items: (data['items'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => RechargeBatch.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList(),
      total: cardParseInt(data['total']) ?? 0,
      page: cardParseInt(data['page']) ?? 1,
      perPage: cardParseInt(data['per_page']) ?? 25,
      pages: cardParseInt(data['pages']) ?? 1,
      defaultDenominations: (data['default_denominations'] as List? ?? const [])
          .map((item) => cardParseNum(item) ?? 0)
          .where((item) => item > 0)
          .toList(),
    );
  }
}

class RechargeBatchDetail {
  const RechargeBatchDetail({
    required this.batch,
    this.cards = const [],
    this.totalCards = 0,
    this.page = 1,
    this.perPage = 25,
    this.pages = 1,
  });

  final RechargeBatch batch;
  final List<RechargeCard> cards;
  final int totalCards;
  final int page;
  final int perPage;
  final int pages;

  factory RechargeBatchDetail.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] ?? json) as Map<String, dynamic>;
    final batchJson = data['batch'] as Map? ?? const {};
    return RechargeBatchDetail(
      batch: RechargeBatch.fromJson(
        batchJson.map((key, value) => MapEntry(key.toString(), value)),
      ),
      cards: (data['cards'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) => RechargeCard.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList(),
      totalCards: cardParseInt(data['total_cards']) ?? 0,
      page: cardParseInt(data['page']) ?? 1,
      perPage: cardParseInt(data['per_page']) ?? 25,
      pages: cardParseInt(data['pages']) ?? 1,
    );
  }
}

class CreateRechargeBatchRequest {
  const CreateRechargeBatchRequest({
    required this.packageName,
    required this.denominations,
    this.notes = '',
  });

  final String packageName;
  final List<RechargeDenomination> denominations;
  final String notes;

  Map<String, dynamic> toBody() => {
        'package_name': packageName,
        'notes': notes,
        'denominations': denominations.map((item) => item.toJson()).toList(),
      };
}

class RechargeBatchCreateResult {
  const RechargeBatchCreateResult({
    required this.batch,
    this.insertedCount = 0,
    this.totalValue = 0,
  });

  final RechargeBatch batch;
  final int insertedCount;
  final num totalValue;

  factory RechargeBatchCreateResult.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] ?? json) as Map<String, dynamic>;
    final batchJson = data['batch'] as Map? ?? const {};
    return RechargeBatchCreateResult(
      batch: RechargeBatch.fromJson(
        batchJson.map((key, value) => MapEntry(key.toString(), value)),
      ),
      insertedCount: cardParseInt(data['inserted_count']) ?? 0,
      totalValue: cardParseNum(data['total_value']) ?? 0,
    );
  }
}
