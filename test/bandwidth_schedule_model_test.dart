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
    expect(result.message, contains('Validated'));
    expect(result.schedule?.name, 'Peak hours');
  });
}
