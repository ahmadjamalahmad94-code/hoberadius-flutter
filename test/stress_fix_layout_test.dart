import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/router/app_page_transitions.dart';
import 'package:hoberadius_app/features/cards/domain/card_batch_operations.dart';
import 'package:hoberadius_app/features/cards/presentation/widgets/cards_list_totals.dart';
import 'package:hoberadius_app/features/notifications/presentation/notification_center_screen.dart';
import 'package:hoberadius_app/features/sessions/presentation/sessions_list_screen.dart';

import 'support/fake_api.dart';

Widget _tall(String name) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < 40; i++)
          SizedBox(height: 60, child: Text('$name $i')),
      ],
    );

/// Same structure as the app shell: ONE scroll view around the inner
/// navigator, pages are content-sized Columns.
GoRouter _router({required bool scoped}) => GoRouter(
      initialLocation: '/list',
      routes: [
        ShellRoute(
          builder: (ctx, st, child) => Scaffold(
            body: SingleChildScrollView(
              child: scoped ? ShellContentScope(child: child) : child,
            ),
          ),
          routes: [
            GoRoute(
              path: '/list',
              builder: (_, __) => _tall('row'),
              routes: [
                GoRoute(path: 'detail', builder: (_, __) => const Text('x')),
              ],
            ),
          ],
        ),
      ],
    );

Future<Object?> _navigate(WidgetTester tester, {required bool fixed}) async {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final base = ThemeData.light(useMaterial3: true);
  final router = _router(scoped: fixed);
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      theme: fixed
          ? base.copyWith(
              pageTransitionsTheme:
                  shellSafePageTransitionsTheme(base.pageTransitionsTheme),
            )
          : base,
    ),
  );
  await tester.pumpAndSettle();
  router.go('/list/detail');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 60));
  final e = tester.takeException();
  await tester.pumpAndSettle();
  return e;
}

void main() {
  _phoneTests();

  testWidgets('control: without the fix a page transition overflows',
      (tester) async {
    final e = await _navigate(tester, fixed: false);
    expect('$e', contains('overflowed'));
  });

  testWidgets('11/L3: shell page transitions no longer overflow',
      (tester) async {
    final e = await _navigate(tester, fixed: true);
    expect(e, isNull);
  });
}

Future<void> _pumpPhone(
  WidgetTester tester,
  Widget child, {
  ApiClient? api,
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [if (api != null) apiClientProvider.overrideWithValue(api)],
      child: MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    // «مباشر» pulses forever: pump a few frames instead of settling.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
}

Map<String, dynamic> _session(int i) => {
      'username': 'u$i',
      'session_id': 's$i',
      'user_type': i.isEven ? 'subscriber' : 'card',
      'state': 'online',
      'started_at': '2026-09-28T10:00:00Z',
    };

void _phoneTests() {
  testWidgets('11: /notifications fits at 360×640', (tester) async {
    final adapter = RecordingAdapter(
      (r) => FakeResponse.ok({
        'items': [
          for (var i = 1; i <= 6; i++)
            {
              'id': i,
              'title': 'انتهاء اشتراك المشترك رقم $i قريبًا جدًا',
              'body': 'اشتراك st12_0$i ينتهي خلال ساعة واحدة — جدّد الآن',
              'category': i.isEven ? 'subscription' : 'system',
              'severity': i == 3 ? 'critical' : 'info',
              'is_read': i > 3,
              'link': '/subscribers/st12_0$i/360',
              'created_at': '2026-09-28T10:00:00Z',
            },
        ],
        'unread_count': 3,
        'limit': 30,
        'offset': 0,
        'has_more': true,
      }),
    );
    await _pumpPhone(
      tester,
      const NotificationCenterScreen(),
      api: fakeApiClient(adapter),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('11: /cards KPI tiles fit at 360×640 (no bottom overflow)',
      (tester) async {
    await _pumpPhone(
      tester,
      CardsListTotals(
        totals: CardBatchOperationsTotals(
          batchCount: 142,
          configuredValue: 1017813,
          usedToday: 1258,
          usedMonth: 30211,
          valueToday: 2101001324.79,
          valueMonth: 99999,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('10/11: /sessions pages with limit/offset and fits at 360',
      (tester) async {
    final adapter = RecordingAdapter((r) {
      if (r.path == '/api/v1/sessions/online') {
        final offset = int.parse('${r.query['offset'] ?? 0}');
        return FakeResponse.ok({
          'items': [
            for (var i = offset; i < offset + 2 && i < 3; i++) _session(i),
          ],
          'total': 520,
          'has_more': offset + 2 < 3,
          'types': {'subscriber': 400, 'card': 120},
        });
      }
      return FakeResponse.ok({'items': <dynamic>[]});
    });
    await _pumpPhone(
      tester,
      const SessionsListScreen(),
      api: fakeApiClient(adapter),
      settle: false,
    );
    expect(tester.takeException(), isNull);
    final online = adapter.where('GET', '/sessions/online').toList();
    expect('${online.first.query['limit']}', '100');
    expect('${online.first.query['offset']}', '0');
    // whole-result counters from the server, not the loaded rows
    expect(find.text('520'), findsOneWidget);
    expect(find.text('400'), findsOneWidget);
  });

  testWidgets('10: an old server (no paging, offset ignored) does not loop',
      (tester) async {
    final adapter = RecordingAdapter((r) {
      if (r.path == '/api/v1/sessions/online') {
        return FakeResponse.ok({
          'items': [for (var i = 0; i < 100; i++) _session(i)],
          'count': 100,
        });
      }
      return FakeResponse.ok({'items': <dynamic>[]});
    });
    await _pumpPhone(
      tester,
      const SessionsListScreen(),
      api: fakeApiClient(adapter),
      settle: false,
    );
    // A full page may have more: scrolling to the end asks once (infinite
    // scroll); that page brings nothing new → the list ends, no loop.
    await tester.ensureVisible(find.textContaining('تحميل المزيد'));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(adapter.where('GET', '/sessions/online').length, 2);
    expect(find.textContaining('نهاية القائمة'), findsOneWidget);
  });
}
