class LifecyclePolicy {
  const LifecyclePolicy({
    this.id = 0,
    this.entityType = 'card',
    this.triggerType = 'expired_at',
    this.delayValue = 0,
    this.delayUnit = 'days',
    this.action = 'archive',
    this.retentionValue = 90,
    this.retentionUnit = 'days',
    this.enabled = true,
    this.createdBy = '',
    this.updatedBy = '',
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String entityType;
  final String triggerType;
  final int delayValue;
  final String delayUnit;
  final String action;
  final int retentionValue;
  final String retentionUnit;
  final bool enabled;
  final String createdBy;
  final String updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory LifecyclePolicy.fromJson(Map<String, dynamic> json) {
    return LifecyclePolicy(
      id: _int(json['id']) ?? 0,
      entityType: (json['entity_type'] ?? 'card').toString(),
      triggerType: (json['trigger_type'] ?? 'expired_at').toString(),
      delayValue: _int(json['delay_value']) ?? 0,
      delayUnit: (json['delay_unit'] ?? 'days').toString(),
      action: (json['action'] ?? 'archive').toString(),
      retentionValue: _int(json['retention_value']) ?? 90,
      retentionUnit: (json['retention_unit'] ?? 'days').toString(),
      enabled: _bool(json['enabled']),
      createdBy: (json['created_by'] ?? '').toString(),
      updatedBy: (json['updated_by'] ?? '').toString(),
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
    );
  }

  Map<String, dynamic> toBody() => {
        'entity_type': entityType,
        'trigger_type': triggerType,
        'delay_value': delayValue,
        'delay_unit': delayUnit,
        'action': action,
        'retention_value': retentionValue,
        'retention_unit': retentionUnit,
        'enabled': enabled,
      };
}

class LifecyclePreview {
  const LifecyclePreview({
    this.dryRun = true,
    this.policies = const [],
    this.totals = const LifecyclePreviewTotals(),
  });

  final bool dryRun;
  final List<LifecyclePolicyPreview> policies;
  final LifecyclePreviewTotals totals;

  factory LifecyclePreview.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    return LifecyclePreview(
      dryRun: _bool(data['dry_run']),
      policies: (data['policies'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(LifecyclePolicyPreview.fromJson)
          .toList(),
      totals: LifecyclePreviewTotals.fromJson(
        data['totals'] is Map<String, dynamic>
            ? data['totals'] as Map<String, dynamic>
            : const {},
      ),
    );
  }
}

class LifecyclePreviewTotals {
  const LifecyclePreviewTotals({
    this.cards = 0,
    this.subscribers = 0,
    this.batchesImpacted = 0,
    this.pendingArchive = 0,
  });

  final int cards;
  final int subscribers;
  final int batchesImpacted;
  final int pendingArchive;

  factory LifecyclePreviewTotals.fromJson(Map<String, dynamic> json) {
    return LifecyclePreviewTotals(
      cards: _int(json['cards']) ?? 0,
      subscribers: _int(json['subscribers']) ?? 0,
      batchesImpacted: _int(json['batches_impacted']) ?? 0,
      pendingArchive: _int(json['pending_archive']) ?? 0,
    );
  }
}

class LifecyclePolicyPreview {
  const LifecyclePolicyPreview({
    required this.policy,
    this.supported = false,
    this.cutoffAt,
    this.cardsCount = 0,
    this.subscribersCount = 0,
    this.batchImpacts = const [],
    this.sampleItems = const [],
  });

  final LifecyclePolicy policy;
  final bool supported;
  final DateTime? cutoffAt;
  final int cardsCount;
  final int subscribersCount;
  final List<LifecycleBatchImpact> batchImpacts;
  final List<LifecycleSampleItem> sampleItems;

  factory LifecyclePolicyPreview.fromJson(Map<String, dynamic> json) {
    final policyJson = json['policy'] is Map<String, dynamic>
        ? json['policy'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return LifecyclePolicyPreview(
      policy: LifecyclePolicy.fromJson(policyJson),
      supported: _bool(json['supported']),
      cutoffAt: _date(json['cutoff_at']),
      cardsCount: _int(json['cards_count']) ?? 0,
      subscribersCount: _int(json['subscribers_count']) ?? 0,
      batchImpacts: (json['batch_impacts'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(LifecycleBatchImpact.fromJson)
          .toList(),
      sampleItems: (json['sample_items'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(LifecycleSampleItem.fromJson)
          .toList(),
    );
  }
}

class LifecycleBatchImpact {
  const LifecycleBatchImpact({
    this.batchId,
    this.batchCode = '',
    this.packageName = '',
    this.originalCount = 0,
    this.pendingArchiveCount = 0,
  });

  final int? batchId;
  final String batchCode;
  final String packageName;
  final int originalCount;
  final int pendingArchiveCount;

  factory LifecycleBatchImpact.fromJson(Map<String, dynamic> json) {
    return LifecycleBatchImpact(
      batchId: _int(json['batch_id']),
      batchCode: (json['batch_code'] ?? '').toString(),
      packageName: (json['package_name'] ?? '').toString(),
      originalCount: _int(json['original_count']) ?? 0,
      pendingArchiveCount: _int(json['pending_archive_count']) ?? 0,
    );
  }
}

class LifecycleSampleItem {
  const LifecycleSampleItem({
    this.entityType = '',
    this.id,
    this.label = '',
    this.expiresAt,
  });

  final String entityType;
  final int? id;
  final String label;
  final DateTime? expiresAt;

  factory LifecycleSampleItem.fromJson(Map<String, dynamic> json) {
    return LifecycleSampleItem(
      entityType: (json['entity_type'] ?? '').toString(),
      id: _int(json['id']),
      label: (json['label'] ?? '').toString(),
      expiresAt: _date(json['expires_at']),
    );
  }
}

class LifecycleRunResult {
  const LifecycleRunResult({
    this.changed = 0,
    this.skipped = 0,
    this.failed = 0,
  });

  final int changed;
  final int skipped;
  final int failed;

  factory LifecycleRunResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    return LifecycleRunResult(
      changed: _int(data['changed']) ?? 0,
      skipped: _int(data['skipped']) ?? 0,
      failed: _int(data['failed']) ?? 0,
    );
  }
}

int? _int(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool _bool(Object? value) =>
    value == true || value == 1 || value == '1' || value == 'true';

DateTime? _date(Object? value) {
  if (value == null || value.toString().isEmpty) return null;
  try {
    return DateTime.parse(value.toString().replaceAll('Z', ''));
  } catch (_) {
    return null;
  }
}
