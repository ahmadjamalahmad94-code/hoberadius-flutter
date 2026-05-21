import 'card_batch.dart';
import 'card_parsing.dart';

/// Payload shape for POST /api/cards/batches/import.
class CardBatchImportRequest {
  CardBatchImportRequest({
    required this.planId,
    required this.csvText,
    this.sourceType = 'external',
    this.packageName = '',
    this.serviceName = '',
    this.notes = '',
    this.pricePerCard = 0,
    this.totalPrice = 0,
    this.syncToRadius = false,
  });

  final int planId;
  final String csvText;
  final String sourceType;
  final String packageName;
  final String serviceName;
  final String notes;
  final num pricePerCard;
  final num totalPrice;
  final bool syncToRadius;

  Map<String, dynamic> toBody() => {
        'plan_id': planId,
        'source_type': sourceType,
        'csv_text': csvText,
        if (packageName.trim().isNotEmpty) 'package_name': packageName.trim(),
        if (serviceName.trim().isNotEmpty) 'service_name': serviceName.trim(),
        if (notes.trim().isNotEmpty) 'notes': notes.trim(),
        'price_per_card': pricePerCard,
        'total_price': totalPrice,
        'sync_to_radius': syncToRadius && sourceType != 'external',
      };
}

class CardBatchImportResult {
  CardBatchImportResult({
    required this.batch,
    this.insertedCount = 0,
    this.skippedCount = 0,
    this.radiusSyncEnabled = false,
    this.radiusSyncedCount = 0,
    this.skipped = const [],
  });

  final CardBatch batch;
  final int insertedCount;
  final int skippedCount;
  final bool radiusSyncEnabled;
  final int radiusSyncedCount;
  final List<CardBatchImportSkippedRow> skipped;

  factory CardBatchImportResult.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;
    return CardBatchImportResult(
      batch: CardBatch.fromJson(
        data['batch'] is Map<String, dynamic>
            ? data['batch'] as Map<String, dynamic>
            : const {},
      ),
      insertedCount: cardParseInt(data['inserted_count']) ?? 0,
      skippedCount: cardParseInt(data['skipped_count']) ?? 0,
      radiusSyncEnabled: cardParseBool(data['radius_sync_enabled']),
      radiusSyncedCount: cardParseInt(data['radius_synced_count']) ?? 0,
      skipped: (data['skipped'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CardBatchImportSkippedRow.fromJson)
          .toList(),
    );
  }
}

class CardBatchImportSkippedRow {
  CardBatchImportSkippedRow({
    this.row = '',
    this.username = '',
    this.reason = '',
  });

  final String row;
  final String username;
  final String reason;

  factory CardBatchImportSkippedRow.fromJson(Map<String, dynamic> json) =>
      CardBatchImportSkippedRow(
        row: (json['row'] ?? '').toString(),
        username: (json['username'] ?? '').toString(),
        reason: (json['reason'] ?? '').toString(),
      );
}
