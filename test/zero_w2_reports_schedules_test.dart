// zero-w2 (2026-10-02): app ↔ web parity.
//  • Operational reports send the date range / filters / paging to the SERVER
//    (they used to fetch the newest 300 rows and filter the dates locally).
//  • login-status / manager-login-status show the web's login-attempt log.
//  • Bandwidth schedules can be edited, toggled and deleted from the app.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/auth/permissions.dart';
import 'package:hoberadius_app/features/bandwidth_schedules/data/bandwidth_schedules_repository.dart';
import 'package:hoberadius_app/features/bandwidth_schedules/presentation/bandwidth_schedules_screen.dart';
import 'package:hoberadius_app/features/operational_reports/data/operational_reports_repository.dart';
import 'package:hoberadius_app/features/operational_reports/domain/operational_report_catalog.dart';
import 'package:hoberadius_app/features/operational_reports/presentation/operational_report_detail_screen.dart';
import 'package:hoberadius_app/features/operational_reports/presentation/report_formatting.dart';

import 'support/fake_api.dart';

Map<String, dynamic> _me({List<String> perms = const [], bool owner = false}) =>
    {
      'admin': {
        'id': 7,
        'username': 'm7',
        'is_owner': owner,
        'is_co_owner': false,
        'is_original_owner': owner,
        'is_super_admin': false,
      },
      'permissions': perms,
      'grants': {
        'actions': <String, bool>{},
        'sections': <String, String>{},
        'view_all_subscribers': true,
      },
    };

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  required RecordingAdapter adapter,
  Map<String, dynamic>? me,
}) async {
  tester.view.physicalSize = const Size(1000, 3200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(fakeApiClient(adapter)),
        permissionsProvider.overrideWith(
          (ref) => PermissionsController(ref)..apply(me ?? _me(owner: true)),
        ),
      ],
      child: MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Map<String, dynamic> _loginRow(int i) => {
      'when': '2026-06-08 0${i % 10}:00:00',
      'username': 'u$i',
      'actor_type': 'subscriber',
      'success': i.isEven,
      'reason': i.isEven ? '' : 'كلمة المرور خاطئة',
      'source': 'network',
      'ip': '',
      'mac': 'AA:BB',
      'nas': '10.0.0.1',
      'device': '',
    };

void main() {
  setUpAll(() async => initializeDateFormatting('en'));
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('operational reports — server-side filters', () {
    test('query parameters carry local days, result/source and paging', () {
      final q = OperationalReportQuery(
        query: ' ali ',
        dateFrom: DateTime(2026, 6, 8),
        dateTo: DateTime(2026, 6, 9, 23, 59),
        result: 'fail',
        source: 'network',
      );
      expect(q.toQueryParameters(limit: 100, offset: 200), {
        'limit': 100,
        'offset': 200,
        'q': 'ali',
        'date_from': '2026-06-08',
        'date_to': '2026-06-09',
        'result': 'fail',
        'source': 'network',
      });
      expect(
        const OperationalReportQuery().toQueryParameters(limit: 100, offset: 0),
        {'limit': 100},
      );
    });

    test('repository sends the filters to the API', () async {
      final adapter = RecordingAdapter(
        (r) => FakeResponse.ok({'slug': 'sessions', 'items': <dynamic>[]}),
      );
      await OperationalReportsRepository(fakeApiClient(adapter)).fetch(
        slug: 'sessions',
        filters: OperationalReportQuery(
          dateFrom: DateTime(2025, 1, 2),
          dateTo: DateTime(2025, 1, 3),
        ),
        offset: 100,
      );
      final req = adapter.requests.single;
      expect(req.path, contains('/api/v1/operational-reports/sessions'));
      expect(req.query['date_from'], '2025-01-02');
      expect(req.query['date_to'], '2025-01-03');
      expect(req.query['offset'], 100);
    });

    testWidgets(
        'detail screen pages with «تحميل المزيد» and filters on the '
        'server (login-status)', (tester) async {
      final adapter = RecordingAdapter((r) {
        final offset = int.tryParse('${r.query['offset'] ?? 0}') ?? 0;
        final count = offset == 0 ? 100 : 20;
        return FakeResponse.ok({
          'slug': 'login-status',
          'items': [for (var i = 0; i < count; i++) _loginRow(offset + i)],
          'count': count,
          'matched': 120,
          'limit': 100,
          'offset': offset,
        });
      });
      await _pump(
        tester,
        const OperationalReportDetailScreen(slug: 'login-status'),
        adapter: adapter,
      );
      expect(adapter.requests, hasLength(1));
      expect(adapter.requests.first.query['limit'], 100);
      expect(adapter.requests.first.query.containsKey('offset'), isFalse);
      expect(find.textContaining('معروضة من أصل 120'), findsOneWidget);

      await tester
          .ensureVisible(find.byKey(const ValueKey('report-load-more')));
      await tester.tap(find.byKey(const ValueKey('report-load-more')));
      await tester.pumpAndSettle();
      expect(adapter.requests, hasLength(2));
      expect(adapter.requests.last.query['offset'], 100);
      expect(find.byKey(const ValueKey('report-load-more')), findsNothing);

      // «النتيجة: فشل» → a fresh first page with result=fail (no local filter)
      final resultFilter = find.byKey(const ValueKey('report-result-filter'));
      await tester.ensureVisible(resultFilter);
      await tester.pumpAndSettle();
      await tester.tap(resultFilter);
      await tester.pumpAndSettle();
      await tester.tap(find.text('فشل').last);
      await tester.pumpAndSettle();
      expect(adapter.requests.last.query['result'], 'fail');
      expect(adapter.requests.last.query.containsKey('offset'), isFalse);
    });

    test('login reports use the web login-attempt columns', () {
      for (final slug in ['login-status', 'manager-login-status']) {
        final def = operationalReportBySlug(slug)!;
        final keys = def.columns.map((c) => c.key).toList();
        expect(def.dateKey, 'when', reason: slug);
        expect(keys, containsAll(['when', 'username', 'success', 'reason']));
        expect(keys, isNot(contains('last_login_at')), reason: slug);
        expect(def.resultFilter, isTrue);
      }
      expect(operationalReportBySlug('login-status')!.sourceFilter, isTrue);
      final res = operationalReportBySlug('login-status')!
          .columns
          .firstWhere((c) => c.key == 'success');
      expect(formatReportCell(res, true), 'نجاح');
      expect(formatReportCell(res, false), 'فشل');
    });
  });

  group('bandwidth schedules — edit / toggle / delete', () {
    Map<String, dynamic> sched() => {
          'id': 5,
          'plan_id': 1,
          'target_type': 'plan',
          'priority': 5,
          'name': 'Night',
          'starts_at_time': '22:00',
          'ends_at_time': '06:00',
          'speed_down_kbps': 2048,
          'speed_up_kbps': 1024,
          'cir_down_kbps': 0,
          'cir_up_kbps': 0,
          'restore_mode': 'profile_default',
          'enabled': 1,
          'notes': '',
        };

    test('repository verbs and paths', () async {
      final adapter =
          RecordingAdapter((r) => FakeResponse.ok({'schedule': sched()}));
      final repo = BandwidthSchedulesRepository(fakeApiClient(adapter));
      await repo.update(5, {'speed_down_kbps': 4096});
      await repo.setEnabled(5, false);
      await repo.delete(5);
      final r = adapter.requests;
      expect(r[0].method, 'PATCH');
      expect(r[0].path, endsWith('/api/v1/bandwidth-schedules/5'));
      expect(r[0].jsonBody, {'speed_down_kbps': 4096});
      expect(r[1].method, 'POST');
      expect(r[1].path, endsWith('/api/v1/bandwidth-schedules/5/enabled'));
      expect(r[1].jsonBody, {'enabled': false});
      expect(r[2].method, 'DELETE');
      expect(r[2].path, endsWith('/api/v1/bandwidth-schedules/5'));
    });

    RecordingAdapter screenApi() => RecordingAdapter((r) {
          if (r.path.contains('/bandwidth-schedules') && r.method == 'GET') {
            return FakeResponse.ok({
              'items': [sched()],
              'count': 1,
            });
          }
          if (r.path.contains('/bandwidth-schedules/5')) {
            return FakeResponse.ok({'schedule': sched(), 'deleted': true});
          }
          return FakeResponse.ok({'items': <dynamic>[], 'total': 0});
        });

    testWidgets('delete asks for confirmation, then DELETEs', (tester) async {
      final adapter = screenApi();
      await _pump(tester, const BandwidthSchedulesScreen(), adapter: adapter);
      final del = find.byKey(const ValueKey('schedule-delete-5'));
      await tester.ensureVisible(del);
      await tester.tap(del);
      await tester.pumpAndSettle();
      expect(find.text('حذف جدول «Night»؟ لا يمكن التراجع.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('bw-delete-confirm')));
      await tester.pumpAndSettle();
      expect(adapter.where('DELETE', '/bandwidth-schedules/5'), hasLength(1));
    });

    testWidgets('toggle posts enabled=false', (tester) async {
      final adapter = screenApi();
      await _pump(tester, const BandwidthSchedulesScreen(), adapter: adapter);
      final sw = find.byKey(const ValueKey('schedule-enabled-5'));
      await tester.ensureVisible(sw);
      await tester.tap(sw);
      await tester.pumpAndSettle();
      final posts = adapter.where('POST', '/bandwidth-schedules/5/enabled');
      expect(posts, hasLength(1));
      expect(posts.first.jsonBody, {'enabled': false});
    });

    testWidgets('edit dialog PATCHes the web form fields', (tester) async {
      final adapter = screenApi();
      await _pump(tester, const BandwidthSchedulesScreen(), adapter: adapter);
      final edit = find.byKey(const ValueKey('schedule-edit-5'));
      await tester.ensureVisible(edit);
      await tester.tap(edit);
      await tester.pumpAndSettle();
      expect(find.text('تعديل جدول السرعة'), findsOneWidget);
      await tester.enterText(
          find.byKey(const ValueKey('bw-edit-name')), 'Peak',);
      await tester.tap(find.byKey(const ValueKey('bw-edit-save')));
      await tester.pumpAndSettle();
      final patches = adapter.where('PATCH', '/bandwidth-schedules/5');
      expect(patches, hasLength(1));
      final body = patches.first.jsonBody;
      expect(body['name'], 'Peak');
      expect(body['speed_down_kbps'], 2048);
      expect(body['restore_mode'], 'profile_default');
      expect(body['priority'], 5);
      expect(body['enabled'], true);
    });

    testWidgets(
        'a manager without plans.edit / plans.delete sees no edit, '
        'toggle or delete', (tester) async {
      final adapter = screenApi();
      await _pump(
        tester,
        const BandwidthSchedulesScreen(),
        adapter: adapter,
        me: _me(perms: ['plans.view']),
      );
      expect(find.byKey(const ValueKey('schedule-edit-5')), findsNothing);
      expect(find.byKey(const ValueKey('schedule-delete-5')), findsNothing);
      expect(find.byKey(const ValueKey('schedule-enabled-5')), findsNothing);
    });
  });
}
