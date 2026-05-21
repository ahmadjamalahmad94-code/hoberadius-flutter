import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/cards/domain/card_model.dart';
import 'package:hoberadius_app/features/lifecycle/domain/lifecycle_model.dart';
import 'package:hoberadius_app/features/recycle_bin/domain/recycle_bin_model.dart';

void main() {
  test('lifecycle preview parses policy totals and impacted batches', () {
    final preview = LifecyclePreview.fromJson({
      'ok': true,
      'data': {
        'dry_run': true,
        'totals': {
          'cards': 3,
          'subscribers': 2,
          'batches_impacted': 1,
          'pending_archive': 5,
        },
        'policies': [
          {
            'supported': true,
            'cutoff_at': '2026-05-20T10:00:00Z',
            'cards_count': 3,
            'subscribers_count': 0,
            'policy': {
              'id': 7,
              'entity_type': 'card',
              'trigger_type': 'expired_at',
              'delay_value': 2,
              'delay_unit': 'days',
              'action': 'archive',
              'retention_value': 90,
              'retention_unit': 'days',
              'enabled': 1,
            },
            'batch_impacts': [
              {
                'batch_id': 4,
                'batch_code': 'B-1',
                'package_name': 'ملف تجريبي',
                'original_count': 4000,
                'pending_archive_count': 800,
              },
            ],
          },
        ],
      },
    });

    expect(preview.dryRun, isTrue);
    expect(preview.totals.pendingArchive, 5);
    expect(preview.policies.single.policy.id, 7);
    expect(preview.policies.single.batchImpacts.single.originalCount, 4000);
  });

  test('card batch keeps original and archive counters separate', () {
    final batch = CardBatch.fromJson({
      'id': 1,
      'batch_code': 'B-20260520',
      'count': 4000,
      'generated': 4000,
      'original_count': 4000,
      'settlement_count': 4000,
      'available_count': 1200,
      'expired_count': 1000,
      'archived_count': 800,
      'pending_archive_count': 200,
      'operational_remaining_count': 1400,
      'source_type': 'external',
    });

    expect(batch.originalCount, 4000);
    expect(batch.archivedCount, 800);
    expect(batch.pendingArchiveCount, 200);
    expect(batch.operationalRemainingCount, 1400);
    expect(batch.sourceType, 'external');
  });

  test('recycle bin parses retention metadata', () {
    final item = RecycleBinItem.fromJson({
      'entity_type': 'cards',
      'id': 12,
      'label': 'card-12',
      'status': 'archived',
      'deleted_at': '2026-05-20T10:00:00Z',
      'deleted_by': 'system:lifecycle',
      'delete_reason': 'auto archive',
      'archive_source': 'auto',
      'archive_policy_id': 9,
      'retention_expires_at': '2026-08-20T10:00:00Z',
      'restore_allowed': true,
      'retention_expired': false,
    });

    expect(item.archiveSource, 'auto');
    expect(item.archivePolicyId, 9);
    expect(item.restoreAllowed, isTrue);
    expect(item.retentionExpiresAt, isNotNull);
  });
}
