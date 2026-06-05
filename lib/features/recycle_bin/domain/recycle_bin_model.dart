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

  factory RecycleBinItem.fromJson(Map<String, dynamic> json) {
    return RecycleBinItem(
      entityType: (json['entity_type'] ?? '').toString(),
      id: _asInt(json['id']),
      label: (json['label'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      deletedAt: DateTime.tryParse((json['deleted_at'] ?? '').toString()),
      deletedBy: (json['deleted_by'] ?? '').toString(),
      deleteReason: (json['delete_reason'] ?? '').toString(),
      archiveSource: (json['archive_source'] ?? '').toString(),
      archivePolicyId: _asNullableInt(json['archive_policy_id']),
      retentionExpiresAt:
          DateTime.tryParse((json['retention_expires_at'] ?? '').toString()),
      restoreAllowed: _asBool(json['restore_allowed'], fallback: true),
      retentionExpired: _asBool(json['retention_expired']),
    );
  }

  String get statusLabel => switch (status) {
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
