import 'card_batch.dart';
import 'card_parsing.dart';

/// Paged result for the operations-room batches listing.
class CardBatchOperationsPage {
  CardBatchOperationsPage({
    required this.items,
    required this.totals,
    this.total = 0,
    this.count = 0,
    this.page = 1,
    this.perPage = 25,
    this.pages = 1,
  });

  final List<CardBatch> items;
  final CardBatchOperationsTotals totals;
  final int total;
  final int count;
  final int page;
  final int perPage;
  final int pages;

  factory CardBatchOperationsPage.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;
    return CardBatchOperationsPage(
      items: (data['items'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CardBatch.fromJson)
          .toList(),
      totals: CardBatchOperationsTotals.fromJson(
        data['totals'] is Map<String, dynamic>
            ? data['totals'] as Map<String, dynamic>
            : const {},
      ),
      total: cardParseInt(data['total']) ?? 0,
      count: cardParseInt(data['count']) ?? 0,
      page: cardParseInt(data['page']) ?? 1,
      perPage: cardParseInt(data['per_page']) ?? 25,
      pages: cardParseInt(data['pages']) ?? 1,
    );
  }
}

class CardBatchOperationsTotals {
  CardBatchOperationsTotals({
    this.batchCount = 0,
    this.configuredValue = 0,
    this.usedToday = 0,
    this.usedMonth = 0,
    this.usedYear = 0,
    this.valueToday = 0,
    this.valueMonth = 0,
    this.valueYear = 0,
  });

  final int batchCount;
  final num configuredValue;
  final int usedToday;
  final int usedMonth;
  final int usedYear;
  final num valueToday;
  final num valueMonth;
  final num valueYear;

  factory CardBatchOperationsTotals.fromJson(Map<String, dynamic> json) =>
      CardBatchOperationsTotals(
        batchCount: cardParseInt(json['batch_count']) ?? 0,
        configuredValue: cardParseNum(json['configured_value']) ?? 0,
        usedToday: cardParseInt(json['used_today']) ?? 0,
        usedMonth: cardParseInt(json['used_month']) ?? 0,
        usedYear: cardParseInt(json['used_year']) ?? 0,
        valueToday: cardParseNum(json['value_today']) ?? 0,
        valueMonth: cardParseNum(json['value_month']) ?? 0,
        valueYear: cardParseNum(json['value_year']) ?? 0,
      );
}

class CardBatchBulkResult {
  CardBatchBulkResult({
    this.action = '',
    this.requested = 0,
    this.changed = 0,
    this.batchIds = const [],
  });

  final String action;
  final int requested;
  final int changed;
  final List<int> batchIds;

  factory CardBatchBulkResult.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;
    return CardBatchBulkResult(
      action: (data['action'] ?? '').toString(),
      requested: cardParseInt(data['requested']) ?? 0,
      changed: cardParseInt(data['changed']) ?? 0,
      batchIds: (data['batch_ids'] as List? ?? const [])
          .map(cardParseInt)
          .whereType<int>()
          .toList(),
    );
  }
}
