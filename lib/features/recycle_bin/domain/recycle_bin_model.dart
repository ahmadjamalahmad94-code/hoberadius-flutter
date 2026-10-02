import 'package:hoberadius_app/core/format/server_time.dart';

class RecycleBinItem {
  const RecycleBinItem({
    required this.entityType,
    required this.id,
    required this.label,
    required this.status,
    required this.deletedAt,
    required this.deletedBy,
    required this.deleteReason,
    required this.archiveSource,
    required this.archivePolicyId,
    required this.retentionExpiresAt,
    required this.restoreAllowed,
    required this.retentionExpired,
    this.serverStatusLabel = '',
    this.deletedByLabel = '',
  });

  final String entityType;
  final int id;
  final String label;
  final String status;
  final DateTime? deletedAt;
  final String deletedBy;
  final String deleteReason;
  final String archiveSource;
  final int? archivePolicyId;
  final DateTime? retentionExpiresAt;
  final bool restoreAllowed;
  final bool retentionExpired;

  /// Server Arabic `status_label` / `deleted_by_label` (optional; older
  /// servers omit them).
  final String serverStatusLabel;
  final String deletedByLabel;

  /// Who deleted it, for display: the server label, else the raw value.
  String get deletedByText => deletedByLabel.isNotEmpty
      ? deletedByLabel
      : (deletedBy.isEmpty ? 'غير معروف' : deletedBy);

  factory RecycleBinItem.fromJson(Map<String, dynamic> json) {
    return RecycleBinItem(
      entityType: (json['entity_type'] ?? '').toString(),
      id: _asInt(json['id']),
      label: (json['label'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      deletedAt: parseServerDateTime(json['deleted_at']),
      deletedBy: (json['deleted_by'] ?? '').toString(),
      deleteReason: (json['delete_reason'] ?? '').toString(),
      archiveSource: (json['archive_source'] ?? '').toString(),
      archivePolicyId: _asNullableInt(json['archive_policy_id']),
      retentionExpiresAt: parseServerDateTime(json['retention_expires_at']),
      restoreAllowed: _asBool(json['restore_allowed'], fallback: true),
      retentionExpired: _asBool(json['retention_expired']),
      serverStatusLabel: (json['status_label'] ?? '').toString().trim(),
      deletedByLabel: (json['deleted_by_label'] ?? '').toString().trim(),
    );
  }

  String get statusLabel => serverStatusLabel.isNotEmpty
      ? serverStatusLabel
      : switch (status) {
          'active' => 'نشط',
          'disabled' => 'معطل',
          'deleted' => 'محذوف',
          'archived' => 'مؤرشف',
          'revoked' => 'ملغى',
          'expired' => 'منتهي',
          _ => status.trim().isEmpty ? 'غير محدد' : 'حالة غير معروفة',
        };
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _asNullableInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool _asBool(Object? value, {bool fallback = false}) {
  if (value == null) return fallback;
  return value == true || value == 1 || value == '1' || value == 'true';
}

/// The phrase the operator types to confirm a permanent delete (zero-w3).
const recyclePurgeConfirmPhrase = 'حذف نهائي';

/// Typed confirmation: the phrase, tashkeel and extra spaces ignored.
bool recyclePurgeConfirmMatches(String typed) {
  final t = typed
      .trim()
      .replaceAll(RegExp('[\u064B-\u0652]'), '')
      .replaceAll(RegExp(r'\s+'), ' ');
  return t == recyclePurgeConfirmPhrase;
}

/// «حذف نهائي» exists only where the web has it: card batches already in the
/// bin, owner / co-owner only (web `recycle_bin_purge`). The old
/// «أرشفة نهائية» button called `/archive` on archived rows — always a 404.
bool canPurgeRecycleItem(RecycleBinItem item, {required bool ownerLike}) =>
    ownerLike && item.entityType == 'card_batches';
