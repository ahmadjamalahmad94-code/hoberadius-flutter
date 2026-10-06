// fields-sched (owner decisions 2026-10-06):
//  • Schedule DAYS are now effective on the server → the app shows and edits
//    them (same sat..fri chips as the web; empty = every day).
//  • Schedule CIR was removed → no CIR inputs, and no cir_* keys are sent.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/auth/permissions.dart';
import 'package:hoberadius_app/features/bandwidth_schedules/data/bandwidth_schedules_repository.dart';
import 'package:hoberadius_app/features/bandwidth_schedules/presentation/bandwidth_schedules_screen.dart';
import 'package:hoberadius_app/features/bandwidth_schedules/presentation/widgets/schedule_days_picker.dart';

import 'support/fake_api.dart';

Map<String, dynamic> _sched() => {
      'id': 5,
      'plan_id': 1,
      'target_type': 'plan',
      'priority': 5,
      'name': 'Night',
      'starts_at_time': '22:00',
      'ends_at_time': '02:00',
      'days_csv': 'thu,fri',
      'speed_down_kbps': 2048,
      'speed_up_kbps': 1024,
      'cir_down_kbps': 300,
      'cir_up_kbps': 200,
      'restore_mode': 'profile_default',
      'enabled': 1,
      'notes': '',
    };

RecordingAdapter _api() => RecordingAdapter((r) {
      if (r.path.contains('/bandwidth-schedules') && r.method == 'GET') {
        return FakeResponse.ok({
          'items': [_sched()],
          'count': 1,
        });
      }
      if (r.path.contains('/bandwidth-schedules')) {
        return FakeResponse.ok({'schedule': _sched()});
      }
      return FakeResponse.ok({'items': <dynamic>[], 'total': 0});
    });

Future<void> _pump(WidgetTester tester, RecordingAdapter adapter) async {
  tester.view.physicalSize = const Size(1000, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(fakeApiClient(adapter)),
        permissionsProvider.overrideWith(
          (ref) => PermissionsController(ref)
            ..apply({
              'admin': {
                'id': 1,
                'username': 'owner',
                'is_owner': true,
                'is_co_owner': false,
                'is_original_owner': true,
                'is_super_admin': false,
              },
              'permissions': <String>[],
              'grants': {
                'actions': <String, bool>{},
                'sections': <String, String>{},
                'view_all_subscribers': true,
              },
            }),
        ),
      ],
      child: const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SingleChildScrollView(child: BandwidthSchedulesScreen()),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('schedule days helpers', () {
    test('parse / canonical csv / label', () {
      expect(parseScheduleDays('FRI, sat,xyz'), {'fri', 'sat'});
      expect(scheduleDaysCsv({'fri', 'sat', 'sun'}), 'sat,sun,fri');
      expect(scheduleDaysLabel(''), 'كل الأيام');
      expect(scheduleDaysLabel('fri,thu'), 'الخميس · الجمعة');
    });
  });

  test('create sends days_csv and no CIR keys', () async {
    final adapter = _api();
    final repo = BandwidthSchedulesRepository(fakeApiClient(adapter));
    await repo.create(
      targetType: 'plan',
      planId: 1,
      name: 'n',
      startsAtTime: '22:00',
      endsAtTime: '02:00',
      speedDownKbps: 1,
      speedUpKbps: 1,
      daysCsv: 'fri',
    );
    final body = adapter.where('POST', '/bandwidth-schedules').first.jsonBody;
    expect(body['days_csv'], 'fri');
    expect(body.containsKey('cir_down_kbps'), isFalse);
    expect(body.containsKey('cir_up_kbps'), isFalse);
  });

  testWidgets('list shows the days; no CIR anywhere on the screen',
      (tester) async {
    await _pump(tester, _api());
    expect(find.textContaining('الخميس · الجمعة'), findsWidgets);
    expect(find.textContaining('CIR'), findsNothing);
    expect(find.textContaining('الحد الأدنى للتنزيل'), findsNothing);
    // the create form offers the seven day chips
    expect(find.byKey(const ValueKey('sched-day-fri')), findsOneWidget);
  });

  testWidgets('edit dialog shows stored days and PATCHes the new set',
      (tester) async {
    final adapter = _api();
    await _pump(tester, adapter);
    final edit = find.byKey(const ValueKey('schedule-edit-5'));
    await tester.ensureVisible(edit);
    await tester.tap(edit);
    await tester.pumpAndSettle();
    final dialog = find.byType(AlertDialog);
    final sat = find.descendant(
      of: dialog,
      matching: find.byKey(const ValueKey('sched-day-sat')),
    );
    final thu = find.descendant(
      of: dialog,
      matching: find.byKey(const ValueKey('sched-day-thu')),
    );
    expect(tester.widget<FilterChip>(thu).selected, isTrue);
    expect(tester.widget<FilterChip>(sat).selected, isFalse);
    await tester.ensureVisible(sat);
    await tester.tap(sat);
    await tester.pumpAndSettle();
    await tester.ensureVisible(thu);
    await tester.tap(thu);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('bw-edit-save')));
    await tester.pumpAndSettle();
    final body = adapter.where('PATCH', '/bandwidth-schedules/5').first.jsonBody;
    expect(body['days_csv'], 'sat,fri');
    expect(body.containsKey('cir_down_kbps'), isFalse);
  });
}
