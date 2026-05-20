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
}
