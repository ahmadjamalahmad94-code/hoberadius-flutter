import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/tools/domain/tools_models.dart';

void main() {
  test('parses radius log entries without secrets', () {
    final snapshot = RadiusLogSnapshot.fromJson({
      'count': 1,
      'items': [
        {
          'id': 7,
          'authdate': '2026-05-20T10:00:00Z',
          'username': 'card1',
          'reply': 'Access-Accept',
          'nas': '10.0.0.1',
          'reason': 'ok',
          'ok': true,
          'pass': 'hidden',
        }
      ],
    });

    expect(snapshot.count, 1);
    expect(snapshot.items.single.username, 'card1');
    expect(snapshot.items.single.ok, isTrue);
  });

  test('parses maintenance preview confirmation data', () {
    final preview = MaintenancePreview.fromJson({
      'action': 'vacuum',
      'days': 90,
      'estimated_rows': 0,
      'table': 'database',
      'destructive': false,
      'confirm_phrase': 'RUN_MAINTENANCE',
      'confirm_token': 'abc',
    });

    expect(preview.action, 'vacuum');
    expect(preview.confirmPhrase, 'RUN_MAINTENANCE');
    expect(preview.confirmToken, 'abc');
  });

  test('parses speed change result', () {
    final result = SetSpeedsResult.fromJson({
      'dry_run': true,
      'changed': 0,
      'matched': 1,
      'changes': [
        {
          'plan_id': 1,
          'name': 'ساعة',
          'before': {'speed_down_kbps': 4000, 'speed_up_kbps': 2000},
          'after': {'speed_down_kbps': 5000, 'speed_up_kbps': 3000},
        }
      ],
    });

    expect(result.dryRun, isTrue);
    expect(result.changes.single.afterDown, 5000);
  });
}
