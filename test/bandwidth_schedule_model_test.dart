import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/bandwidth_schedules/domain/bandwidth_schedule_model.dart';

void main() {
  test('BandwidthSchedule parses schedule fields', () {
    final schedule = BandwidthSchedule.fromJson({
      'id': '9',
      'plan_id': '1',
      'target_type': 'subscriber',
      'subscriber_username': 'user123',
      'priority': '10',
      'name': 'Night speed',
      'starts_at_time': '22:00',
      'ends_at_time': '06:00',
      'speed_down_kbps': '3000',
      'speed_up_kbps': 1000,
      'cir_down_kbps': '0',
      'cir_up_kbps': 0,
      'restore_mode': 'profile_default',
      'enabled': 1,
      'notes': 'dry run only',
      'created_at': '2026-05-20T12:00:00Z',
    });

    expect(schedule.id, 9);
    expect(schedule.planId, 1);
    expect(schedule.targetType, 'subscriber');
    expect(schedule.subscriberUsername, 'user123');
    expect(schedule.priority, 10);
    expect(schedule.speedDownKbps, 3000);
    expect(schedule.speedUpKbps, 1000);
    expect(schedule.enabled, isTrue);
    expect(schedule.createdAt, isNotNull);
  });

  test('BandwidthApplyResult preserves dry-run contract', () {
    final result = BandwidthApplyResult.fromJson({
      'applied_to_radius': false,
      'dry_run': true,
      'live_requested': true,
      'live_enabled': false,
      'rate_limit': '1000k/3000k',
      'log': {'message': 'Validated schedule only.'},
      'schedule': {
        'id': 3,
        'plan_id': 1,
        'name': 'Peak hours',
        'starts_at_time': '10:00',
        'ends_at_time': '22:00',
      },
    });

    expect(result.appliedToRadius, isFalse);
    expect(result.dryRun, isTrue);
    expect(result.liveRequested, isTrue);
    expect(result.liveEnabled, isFalse);
    expect(result.rateLimit, '1000k/3000k');
    expect(result.message, contains('Validated'));
    expect(result.schedule?.name, 'Peak hours');
  });

  test('EffectiveBandwidthRuleResult parses precedence response', () {
    final result = EffectiveBandwidthRuleResult.fromJson({
      'has_rule': true,
      'source': 'subscriber',
      'rate_limit': '700k/7000k',
      'precedence': ['subscriber', 'card_batch', 'plan'],
      'effective_rule': {
        'id': 8,
        'plan_id': 1,
        'target_type': 'subscriber',
        'subscriber_username': 'u1',
        'card_batch_id': null,
        'priority': 10,
        'name': 'Subscriber speed',
        'starts_at_time': '08:00',
        'ends_at_time': '14:00',
        'speed_down_kbps': 7000,
        'speed_up_kbps': 700,
        'enabled': true,
      },
    });

    expect(result.hasRule, isTrue);
    expect(result.source, 'subscriber');
    expect(result.rateLimit, '700k/7000k');
    expect(result.precedence, contains('card_batch'));
    expect(result.rule?.speedDownKbps, 7000);
  });
}
