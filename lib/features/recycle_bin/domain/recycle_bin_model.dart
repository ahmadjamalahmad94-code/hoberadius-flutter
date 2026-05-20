class RecycleBinItem {
  const RecycleBinItem({
    required this.entityType,
    required this.id,
    required this.label,
    required this.status,
    required this.deletedAt,
    required this.deletedBy,
    required this.deleteReason,
  });

  final String entityType;
  final int id;
  final String label;
  final String status;
  final DateTime? deletedAt;
  final String deletedBy;
  final String deleteReason;

  factory RecycleBinItem.fromJson(Map<String, dynamic> json) {
    return RecycleBinItem(
      entityType: (json['entity_type'] ?? '').toString(),
      id: _asInt(json['id']),
      label: (json['label'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      deletedAt: DateTime.tryParse((json['deleted_at'] ?? '').toString()),
      deletedBy: (json['deleted_by'] ?? '').toString(),
      deleteReason: (json['delete_reason'] ?? '').toString(),
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
