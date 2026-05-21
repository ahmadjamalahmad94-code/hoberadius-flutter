import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/cards/domain/card_model.dart';

void main() {
  test('CardBatch parses editable package and schedule-related fields', () {
    final batch = CardBatch.fromJson({
      'id': 7,
      'batch_code': 'B-20260520-0007',
      'package_name': 'Night cards',
      'plan_id': 2,
      'count': 50,
      'generated': 40,
      'used': 5,
      'status': 'active',
      'price_per_card': '3.5',
      'price_bulk': 120,
      'total_price': '140',
      'total_quota_mb': '2048',
      'password_generation_type': 'strong',
      'include_batch_number': 1,
      'random_generation_enabled': true,
      'starts_with_or_ends_with': 'prefix',
      'prefix_or_suffix_value': 'N-',
      'time_value': '12',
      'time_unit': 'hours',
      'device_count': '3',
      'duration_mode': 'time_unit',
      'count_from_first_connect': 1,
      'on_quota_exhaust': 'reduce_speed',
      'switch_to_mac_on_connect': true,
      'phone_only_login': false,
    });

    expect(batch.id, 7);
    expect(batch.planId, 2);
    expect(batch.packageName, 'Night cards');
    expect(batch.available, 45);
    expect(batch.pricePerCard, 3.5);
    expect(batch.priceBulk, 120);
    expect(batch.totalQuotaMb, 2048);
    expect(batch.passwordGenerationType, 'strong');
    expect(batch.includeBatchNumber, isTrue);
    expect(batch.startsWithOrEndsWith, 'prefix');
    expect(batch.timeUnit, 'hours');
    expect(batch.deviceCount, 3);
    expect(batch.onQuotaExhaust, 'reduce_speed');
    expect(batch.switchToMacOnConnect, isTrue);
    expect(batch.phoneOnlyLogin, isFalse);
  });

  test(
      'UpdateBatchRequest sends editable fields without pretending to regenerate cards',
      () {
    final body = UpdateBatchRequest(
      planId: 2,
      count: 40,
      packageName: 'Edited',
      pricePerCard: 2.5,
      totalQuotaMb: 1024,
      timeValue: 8,
      timeUnit: 'hours',
      deviceCount: 2,
      onQuotaExhaust: 'reduce_speed',
      notes: 'No regeneration',
    ).toBody();

    expect(body['plan_id'], 2);
    expect(body['count'], 40);
    expect(body['package_name'], 'Edited');
    expect(body['time_unit'], 'hours');
    expect(body['device_count'], 2);
    expect(body['on_quota_exhaust'], 'reduce_speed');
    expect(body.containsKey('cards'), isFalse);
  });

  test('CardBatchOperationsPage parses operational counters and totals', () {
    final page = CardBatchOperationsPage.fromJson({
      'data': {
        'items': [
          {
            'id': 9,
            'batch_code': 'B-OPS-9',
            'package_name': 'Cards 4h',
            'plan_name': 'Hotspot Plus',
            'operational_status': 'active',
            'generated': 100,
            'used': 20,
            'available_count': 70,
            'active_count': 12,
            'expired_count': 6,
            'revoked_count': 2,
            'remaining_count': 70,
            'sessions_count': 44,
            'unique_macs': 11,
            'online_sessions': 3,
            'speed_rules_count': 2,
            'active_speed_rules': 1,
            'estimated_unit_price': '2.5',
            'distributor_display_name': 'North reseller',
            'plan_speed_down_kbps': 5000,
            'plan_speed_up_kbps': 1000,
          },
        ],
        'total': 1,
        'count': 1,
        'page': 1,
        'per_page': 25,
        'pages': 1,
        'totals': {
          'batch_count': 1,
          'configured_value': 250,
          'used_today': 3,
          'used_month': 20,
          'used_year': 50,
          'value_today': 7.5,
          'value_month': 50,
          'value_year': 125,
        },
      },
    });

    final batch = page.items.single;
    expect(page.total, 1);
    expect(page.totals.usedToday, 3);
    expect(batch.planName, 'Hotspot Plus');
    expect(batch.available, 70);
    expect(batch.activeCount, 12);
    expect(batch.uniqueMacs, 11);
    expect(batch.activeSpeedRules, 1);
    expect(batch.estimatedValue, 250);
    expect(batch.distributorDisplayName, 'North reseller');
  });

  test('CardBatchImport request and result keep external imports safe', () {
    final request = CardBatchImportRequest(
      planId: 3,
      sourceType: 'external',
      csvText: 'username,password\nc1,p1\n',
      packageName: 'External file',
      syncToRadius: true,
      pricePerCard: 1.5,
    );

    final body = request.toBody();
    expect(body['plan_id'], 3);
    expect(body['source_type'], 'external');
    expect(body['csv_text'], contains('c1,p1'));
    expect(body['sync_to_radius'], isFalse);

    final result = CardBatchImportResult.fromJson({
      'data': {
        'batch': {
          'id': 44,
          'batch_code': 'B-EXT-44',
          'source_type': 'external',
          'original_count': 2,
          'generated': 2,
        },
        'inserted_count': 2,
        'skipped_count': 1,
        'radius_sync_enabled': false,
        'radius_synced_count': 0,
        'skipped': [
          {'row': '3', 'username': 'dup', 'reason': 'duplicate'},
        ],
      },
    });

    expect(result.batch.sourceType, 'external');
    expect(result.batch.originalCount, 2);
    expect(result.insertedCount, 2);
    expect(result.radiusSyncEnabled, isFalse);
    expect(result.skipped.single.reason, 'duplicate');
  });
}
