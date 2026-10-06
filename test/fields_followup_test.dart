// FIELDS follow-up (owner decisions 2026-10-06, second pass):
//  • «IP ثابت» + «IP PPPoE» merged into ONE field (static_ip, IPv4 only):
//    no PPPoE section; a stored non-IPv4 value shows an Arabic fix-it hint.
//  • Bandwidth schedule «طريقة الرجوع»: exactly two modes — «رجوع مباشر بدون
//    فصل» (profile_default) and «فصل الجلسة» (disconnect); legacy stored
//    values read as «رجوع مباشر».
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/auth/permissions.dart';
import 'package:hoberadius_app/features/bandwidth_schedules/domain/bandwidth_schedule_model.dart';
import 'package:hoberadius_app/features/bandwidth_schedules/presentation/bandwidth_schedules_screen.dart';
import 'package:hoberadius_app/features/subscribers/presentation/widgets/subscriber_form_sections.dart';
import 'package:hoberadius_app/shared/widgets/hub_speed_rules_panel.dart';

import 'support/fake_api.dart';

Map<String, dynamic> _sched({String restore = 'keep_current'}) => {
      'id': 5,
      'plan_id': 1,
      'target_type': 'plan',
      'priority': 5,
      'name': 'Night',
      'starts_at_time': '22:00',
      'ends_at_time': '02:00',
      'days_csv': '',
      'speed_down_kbps': 2048,
      'speed_up_kbps': 1024,
      'restore_mode': restore,
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
        return FakeResponse.ok({'schedule': _sched(restore: 'disconnect')});
      }
      return FakeResponse.ok({'items': <dynamic>[], 'total': 0});
    });

Future<void> _pumpSchedules(
  WidgetTester tester,
  RecordingAdapter adapter,
) async {
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

Future<void> _pumpLock(WidgetTester tester, String original) async {
  final c = {
    for (final k in ['mac_lock', 'static_ip', 'device_count'])
      k: TextEditingController(),
  };
  c['static_ip']!.text = original;
  addTearDown(() {
    for (final v in c.values) {
      v.dispose();
    }
  });
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: SingleChildScrollView(
            child: SubscriberLockSection(
              controllers: c,
              originalStaticIp: original,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (find.byType(TextFormField).evaluate().isEmpty) {
    // collapsed by default — open it
    await tester.tap(find.text('الشبكة وقيود الاتصال'));
    await tester.pumpAndSettle();
  }
}

void main() {
  group('«طريقة الرجوع»: two modes', () {
    test('constants, legacy mapping and the shared panel enum', () {
      expect(
        kScheduleRestoreModes.keys.toList(),
        ['profile_default', 'disconnect'],
      );
      expect(kScheduleRestoreModes['profile_default'], 'رجوع مباشر بدون فصل');
      expect(kScheduleRestoreModes['disconnect'], 'فصل الجلسة');
      for (final legacy in [
        'keep_current',
        'previous_value',
        'manual',
        '',
        null,
      ]) {
        expect(normalizeScheduleRestoreMode(legacy), 'profile_default');
      }
      expect(normalizeScheduleRestoreMode('DISCONNECT'), 'disconnect');
      expect(
        BandwidthSchedule.fromJson(_sched()).restoreMode,
        'profile_default',
      );
      expect(SpeedRestoreMode.values.length, 2);
      expect(
        kSpeedRestoreCodes.values.toList(),
        ['profile_default', 'disconnect'],
      );
    });

    testWidgets('create card and edit dialog offer exactly the two modes',
        (tester) async {
      final adapter = _api();
      await _pumpSchedules(tester, adapter);
      expect(find.text('إبقاء آخر سرعة'), findsNothing);
      expect(find.text('الرجوع للسرعة الأساسية'), findsNothing);
      final create = find.byKey(const ValueKey('bw-restore-mode'));
      await tester.ensureVisible(create);
      await tester.tap(create);
      await tester.pumpAndSettle();
      expect(find.text('رجوع مباشر بدون فصل'), findsWidgets);
      expect(find.text('فصل الجلسة'), findsWidgets);
      expect(find.text('إبقاء آخر سرعة'), findsNothing);
      await tester.tap(find.text('رجوع مباشر بدون فصل').last);
      await tester.pumpAndSettle();

      // edit: a legacy keep_current row opens as «رجوع مباشر»; pick «فصل الجلسة»
      final edit = find.byKey(const ValueKey('schedule-edit-5'));
      await tester.ensureVisible(edit);
      await tester.tap(edit);
      await tester.pumpAndSettle();
      final dd = find.byKey(const ValueKey('bw-edit-restore-mode'));
      expect(
        find.descendant(of: dd, matching: find.text('رجوع مباشر بدون فصل')),
        findsOneWidget,
      );
      await tester.ensureVisible(dd);
      await tester.tap(dd);
      await tester.pumpAndSettle();
      expect(find.text('إبقاء آخر سرعة'), findsNothing);
      await tester.tap(find.text('فصل الجلسة').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('bw-edit-save')));
      await tester.pumpAndSettle();
      final body =
          adapter.where('PATCH', '/bandwidth-schedules/5').first.jsonBody;
      expect(body['restore_mode'], 'disconnect');
    });
  });

  group('«IP ثابت» — one IPv4 field', () {
    // the network section opens (remembered state = expanded)
    setUp(
      () => SharedPreferences.setMockInitialValues({'section.sub.macip': true}),
    );
    testWidgets('a stored IPv6 value shows the Arabic fix-it hint',
        (tester) async {
      await _pumpLock(tester, '2001:db8::7');
      expect(
        find.byKey(const ValueKey('static-ip-legacy-hint')),
        findsOneWidget,
      );
      expect(find.text(kStaticIpLegacyHint), findsOneWidget);
    });

    testWidgets('an IPv4 value shows no hint; typing IPv6 is refused',
        (tester) async {
      await _pumpLock(tester, '10.0.0.5');
      expect(
        find.byKey(const ValueKey('static-ip-legacy-hint')),
        findsNothing,
      );
      final field = find.widgetWithText(TextFormField, '10.0.0.5');
      await tester.enterText(field, 'fe80::1');
      await tester.pumpAndSettle();
      expect(find.textContaining('IPv6 غير مدعوم'), findsOneWidget);
    });

    test('the single field carries the IPv4 help', () {
      expect(kStaticIpHint, contains('IPv4'));
      expect(validateStaticIp('10.1.2.3'), isNull);
    });
  });
}
