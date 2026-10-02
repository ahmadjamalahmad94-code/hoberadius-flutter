import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/features/accounting/presentation/loans_center_screen.dart';
import 'package:hoberadius_app/features/accounting/presentation/subscriber_finance_screen.dart';

import 'support/fake_api.dart';

Map<String, dynamic> _sub(String u, int id) => {
      'id': id,
      'username': u,
      'status': 'enabled',
      'expire_at': '2026-10-22T12:04:02Z',
    };

FakeHandler _server({
  FakeResponse Function(RecordedRequest r)? onPost,
}) {
  return (r) {
    final p = r.path;
    if (r.method == 'GET') {
      if (p.endsWith('/actions-context')) {
        return FakeResponse.ok({
          'username': p.split('/')[4],
          'currency': 'ILS',
          'plan': {'id': 1, 'name': 'شهري', 'price': 30, 'minutes': 43200},
          'effective_price': 30,
        });
      }
      if (p.startsWith('/api/v1/accounts/')) {
        final u = p.split('/')[4];
        return FakeResponse.ok(_sub(u, u == 'ali' ? 1 : 2));
      }
      if (p == '/api/v1/payments') {
        final sid = '${r.query['subscriber_id']}';
        return FakeResponse.ok({
          'items': [
            {
              'id': sid == '1' ? 11 : 22,
              'subscriber_id': int.parse(sid),
              'amount': 5,
              'currency': 'ILS',
              'status': 'posted',
              'earned_minutes': 7200,
              'created_at': '2026-09-28T10:00:00Z',
            },
          ],
        });
      }
      if (p == '/api/v1/loans') {
        final sid = '${r.query['subscriber_id']}';
        return FakeResponse.ok({
          'items': [
            {
              'id': sid == '1' ? 2011 : 2012,
              'subscriber_id': int.parse(sid),
              'amount': 10,
              'outstanding': 4,
              'currency': 'ILS',
              'status': 'open',
              'duration_minutes': 120,
              'reason': 'loan of $sid',
            },
          ],
        });
      }
      return FakeResponse.ok({'items': <dynamic>[]});
    }
    if (onPost != null) return onPost(r);
    return FakeResponse.ok(
      {
        'payment': {'id': 99, 'amount': 5, 'activation_result': {}},
        'loan': {'id': 3000, 'amount': 0},
        'settlement': {'id': 1},
      },
      status: 201,
    );
  };
}

Future<void> _pump(
  WidgetTester tester,
  RecordingAdapter adapter,
  Widget screen, {
  double width = 360,
}) async {
  tester.view.physicalSize = Size(width, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(fakeApiClient(adapter))],
      child: MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: screen,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _field(String label) => find.byWidgetPredicate(
      (w) =>
          w is TextField && (w.decoration?.labelText ?? '').startsWith(label),
    );

/// Parity-b (owner decision 2026-10-02, F11 option «أ»): like the web, a
/// debt loan's value is NEVER typed — it is the plan price × the duration
/// (`price_from_days`), shown read-only; the loans centre has no currency
/// choice (system currency only).
void main() {
  testWidgets('subscriber finance: a debt loan sends price_from_days, amount 0',
      (tester) async {
    final adapter = RecordingAdapter(_server());
    await _pump(tester, adapter, const SubscriberFinanceScreen(username: 'ali'));
    // No free «قيمة السلفة» text input any more.
    expect(_field('قيمة السلفة'), findsNothing);
    await tester.tap(find.text('تسجيل دين (مدين)'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('عدد الأيام'), '2');
    await tester.enterText(_field('عدد الساعات'), '0');
    await tester.pumpAndSettle();
    // 30 ILS / 30 days × 2 days = 2.00 (read-only).
    expect(find.text('2.00'), findsOneWidget);
    await tester.tap(find.text('معاينة بدون تنفيذ').at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('منح السلفة'));
    await tester.pumpAndSettle();
    final post = adapter.where('POST', '/api/v1/loans').single;
    expect(post.jsonBody['price_from_days'], true);
    expect(post.jsonBody['amount'], 0);
    expect(post.jsonBody['days'], 2);
  });

  testWidgets('subscriber finance: a free loan sends no value', (tester) async {
    final adapter = RecordingAdapter(_server());
    await _pump(tester, adapter, const SubscriberFinanceScreen(username: 'ali'));
    await tester.tap(find.text('معاينة بدون تنفيذ').at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('منح السلفة'));
    await tester.pumpAndSettle();
    final post = adapter.where('POST', '/api/v1/loans').single;
    expect(post.jsonBody.containsKey('price_from_days'), isFalse);
    expect(post.jsonBody['amount'], 0);
    expect(post.jsonBody['hours'], 2);
  });

  testWidgets('loans centre: no currency dropdown and no typed amount',
      (tester) async {
    final adapter = RecordingAdapter(_server());
    await _pump(tester, adapter, const LoansCenterScreen(), width: 1000);
    await tester.tap(find.text('تسجيل سلفة أو دين').first);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(DropdownButtonFormField<String>),
      ),
      findsNothing,
    );
    expect(_field('المبلغ'), findsNothing);
    expect(find.text('تسجيل دين (مدين)'), findsOneWidget);
  });
}
