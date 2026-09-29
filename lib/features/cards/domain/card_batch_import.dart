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
        'csv_text': normalizeCardImportCsvHeaders(csvText),
        if (packageName.trim().isNotEmpty) 'package_name': packageName.trim(),
        if (serviceName.trim().isNotEmpty) 'service_name': serviceName.trim(),
        if (notes.trim().isNotEmpty) 'notes': notes.trim(),
        'price_per_card': pricePerCard,
        'total_price': totalPrice,
        'sync_to_radius': syncToRadius && sourceType != 'external',
      };
}

String normalizeCardImportCsvHeaders(String csvText) {
  final lines = csvText.split(RegExp(r'\r?\n'));
  if (lines.isEmpty) return csvText;

  final headerCells = lines.first
      .split(',')
      .map((cell) => cell.trim().replaceAll('"', ''))
      .toList();
  if (headerCells.isEmpty) return csvText;

  final normalized = headerCells.map(_normalizeImportHeader).toList();
  final changed = normalized.join(',') != headerCells.join(',');
  if (!changed) return csvText;

  return [normalized.join(','), ...lines.skip(1)].join('\n');
}

String _normalizeImportHeader(String value) {
  switch (value) {
    case 'اسم الدخول':
    case 'اسم المستخدم':
    case 'المستخدم':
    case 'الكرت':
    case 'البطاقة':
      return 'username';
    case 'كلمة المرور':
    case 'كلمة السر':
    case 'الرمز':
      return 'password';
    default:
      return value;
  }
}

class CardBatchImportResult {
  CardBatchImportResult({
    required this.batch,
    this.insertedCount = 0,
    this.skippedCount = 0,
    this.radiusSyncEnabled = false,
    this.radiusSyncedCount = 0,
    this.skipped = const [],
    this.duplicateInFile = 0,
    this.invalid = const [],
  });

  final CardBatch batch;
  final int insertedCount;
  final int skippedCount;
  final bool radiusSyncEnabled;
  final int radiusSyncedCount;
  final List<CardBatchImportSkippedRow> skipped;

  /// Rows repeated inside the file itself (updated servers; 0 on old ones).
  final int duplicateInFile;

  /// Rows refused by the server's checks, grouped by reason (updated
  /// servers): empty name, too long, bad characters…
  final List<CardImportInvalidGroup> invalid;

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
      duplicateInFile: _countOf(data['duplicate_in_file']),
      invalid: (data['invalid'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CardImportInvalidGroup.fromJson)
          .toList(),
    );
  }
}

class CardBatchImportSkippedRow {
  CardBatchImportSkippedRow({
    this.row = '',
    this.username = '',
    this.reason = '',
    this.message = '',
  });

  final String row;
  final String username;
  final String reason;

  /// The server's Arabic explanation (updated servers).
  final String message;

  /// What to show: the Arabic message, else a known reason, else the code.
  String get label {
    if (message.trim().isNotEmpty) return message.trim();
    return kCardImportReasonLabels[reason] ?? reason;
  }

  factory CardBatchImportSkippedRow.fromJson(Map<String, dynamic> json) =>
      CardBatchImportSkippedRow(
        row: (json['row'] ?? '').toString(),
        username: (json['username'] ?? '').toString(),
        reason: (json['reason'] ?? '').toString(),
        message: (json['message'] ?? '').toString(),
      );
}

int _countOf(Object? v) =>
    v is Map ? cardParseInt(v['count']) ?? 0 : cardParseInt(v) ?? 0;

/// Arabic names of the import skip reasons (old servers send codes only).
const kCardImportReasonLabels = <String, String>{
  'duplicate': 'الاسم مستعمل في النظام (بطاقة أو مشترك)',
  'duplicate_in_file': 'مكرّر داخل الملف نفسه',
  'missing_username': 'اسم المستخدم فارغ',
  'empty_username': 'اسم المستخدم فارغ',
  'username_too_long': 'اسم المستخدم طويل جدًّا',
  'invalid_password': 'كلمة المرور تحوي محارف غير مسموحة',
  'password_too_long': 'كلمة المرور أطول من 64 محرفًا',
};

/// One reason the server refused rows for, with how many.
class CardImportInvalidGroup {
  const CardImportInvalidGroup({
    required this.reason,
    required this.label,
    required this.count,
  });
  final String reason;
  final String label;
  final int count;

  factory CardImportInvalidGroup.fromJson(Map<String, dynamic> j) {
    final reason = '${j['reason'] ?? ''}';
    final label = '${j['label'] ?? ''}'.trim();
    return CardImportInvalidGroup(
      reason: reason,
      label: label.isNotEmpty
          ? label
          : (kCardImportReasonLabels[reason] ?? reason),
      count: cardParseInt(j['count']) ?? 0,
    );
  }
}
