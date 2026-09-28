import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/api/idempotency.dart';
import 'package:hoberadius_app/features/accounting/data/accounting_repository.dart';
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

void main() {
  testWidgets('4a: «معاينة بدون تنفيذ» never calls a money endpoint',
      (tester) async {
    final adapter = RecordingAdapter(_server());
    await _pump(
      tester,
      adapter,
      const SubscriberFinanceScreen(username: 'ali'),
    );
    await tester.enterText(_field('المبلغ'), '5');
    await tester.tap(find.text('معاينة الدفعة'));
    await tester.pumpAndSettle();
    expect(find.textContaining('معاينة فقط'), findsOneWidget);
    await tester.tap(find.text('معاينة السلفة'));
    await tester.pumpAndSettle();
    expect(adapter.requests.where((r) => r.method == 'POST'), isEmpty);
  });

  testWidgets('4a/4b/6: a real payment sends no JOD and an Idempotency-Key',
      (tester) async {
    final adapter = RecordingAdapter(_server());
    await _pump(
      tester,
      adapter,
      const SubscriberFinanceScreen(username: 'ali'),
    );
    // Currency comes from the server (actions-context), never «JOD».
    expect(find.textContaining('JOD'), findsNothing);
    expect(_field('المبلغ (ILS)'), findsOneWidget);
    // Turn the payment preview off (first «معاينة بدون تنفيذ» switch).
    await tester.tap(find.text('معاينة بدون تنفيذ').at(0));
    await tester.pumpAndSettle();
    await tester.enterText(_field('المبلغ'), '5');
    await tester.tap(find.text('تسجيل الدفعة'));
    await tester.pumpAndSettle();
    final posts = adapter.where('POST', '/api/v1/payments').toList();
    expect(posts, hasLength(1));
    expect(posts.single.jsonBody.containsKey('currency'), isFalse);
    expect(posts.single.jsonBody['dry_run'], false);
    expect(posts.single.headers[kIdempotencyHeader], isNotEmpty);
  });

  testWidgets('4f: amount upper bound with an Arabic message', (tester) async {
    final adapter = RecordingAdapter(_server());
    await _pump(
      tester,
      adapter,
      const SubscriberFinanceScreen(username: 'ali'),
    );
    await tester.tap(find.text('معاينة بدون تنفيذ').at(0));
    await tester.pumpAndSettle();
    await tester.enterText(_field('المبلغ'), '999999999999');
    await tester.tap(find.text('تسجيل الدفعة'));
    await tester.pumpAndSettle();
    expect(find.textContaining('كبير جدًا'), findsOneWidget);
    expect(adapter.where('POST', '/payments'), isEmpty);
    expect(validateMoneyAmount(1000000), isNull);
    expect(validateMoneyAmount(1000001), isNotNull);
    expect(validateMoneyAmount(0), isNotNull);
    expect(validateMoneyAmount(double.infinity), isNotNull);
  });

  testWidgets('5: a 422 from the loans endpoint is shown on the card',
      (tester) async {
    final adapter = RecordingAdapter(
      _server(
        onPost: (r) => FakeResponse.error(
          422,
          'validation_error',
          'السلفة المجانية لا تتجاوز 72 ساعة.',
        ),
      ),
    );
    await _pump(
      tester,
      adapter,
      const SubscriberFinanceScreen(username: 'ali'),
    );
    // The loan card's own «معاينة بدون تنفيذ» (second one on the page).
    await tester.tap(find.text('معاينة بدون تنفيذ').at(1));
    await tester.pumpAndSettle();
    await tester.enterText(_field('عدد الساعات'), '500');
    await tester.tap(find.text('منح السلفة'));
    await tester.pumpAndSettle();
    expect(find.text('السلفة المجانية لا تتجاوز 72 ساعة.'), findsWidgets);
  });

  testWidgets('4c: changing only the username reloads for the new subscriber',
      (tester) async {
    final adapter = RecordingAdapter(_server());
    await _pump(
      tester,
      adapter,
      const SubscriberFinanceScreen(username: 'ali'),
    );
    await tester.enterText(_field('المبلغ'), '77');
    expect(find.textContaining('loan of 1'), findsOneWidget);
    await _pump(
      tester,
      adapter,
      const SubscriberFinanceScreen(username: 'omar'),
    );
    expect(find.textContaining('loan of 2'), findsOneWidget);
    expect(find.textContaining('loan of 1'), findsNothing);
    expect(find.text('77'), findsNothing);
    // Settling now targets omar's loan (2012), never ali's (2011).
    await tester.tap(find.text('تسوية'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تأكيد التسوية'));
    await tester.pumpAndSettle();
    final settle = adapter.where('POST', '/settle').single;
    expect(settle.path, '/api/v1/loans/2012/settle');
    expect(settle.jsonBody['amount'], 4); // the outstanding, not the value
    expect(settle.headers[kIdempotencyHeader], isNotEmpty);
  });

  testWidgets('4d: «عكس» is on screen at 360 px', (tester) async {
    final adapter = RecordingAdapter(_server());
    await _pump(
      tester,
      adapter,
      const SubscriberFinanceScreen(username: 'ali'),
    );
    final btn = find.text('عكس');
    expect(btn, findsOneWidget);
    final box = tester.renderObject<RenderBox>(btn);
    final rect = box.localToGlobal(Offset.zero) & box.size;
    expect(rect.left >= 0 && rect.right <= 360, isTrue, reason: '$rect');
    expect(tester.takeException(), isNull);
  });

  test('7: snapshot report types are the server keys', () {
    expect(reportSnapshotType('sales/daily'), 'daily');
    expect(reportSnapshotType('sales/monthly'), 'monthly');
    expect(reportSnapshotType('sales/yearly'), 'yearly');
    expect(reportSnapshotType('payments'), 'subscriber_payments');
    expect(reportSnapshotType('card-sales'), 'card_sales');
    expect(reportSnapshotType('profit-loss'), 'profit_loss');
    expect(reportSnapshotType('distributor-debts'), 'distributor_debts');
    expect(reportSnapshotType('loans'), 'loans');
    expect(reportSnapshotType('activations'), 'activations');
  });

  test('7: createReportSnapshot posts the mapped report_type', () async {
    final adapter = RecordingAdapter(
      (_) => FakeResponse.ok({
        'snapshot': {'id': 1}
      }, status: 201),
    );
    final repo = AccountingRepository(fakeApiClient(adapter));
    await repo.createReportSnapshot('profit-loss');
    await repo.reportSnapshots(reportType: 'sales/daily');
    expect(adapter.requests[0].jsonBody['report_type'], 'profit_loss');
    expect(adapter.requests[1].query['report_type'], 'daily');
  });

  testWidgets('6/F7: loans center shows the SERVER totals of the whole filter',
      (tester) async {
    final adapter = RecordingAdapter((r) {
      final offset = int.parse('${r.query['offset'] ?? 0}');
      return FakeResponse.ok({
        'items': [
          {
            'id': offset + 1,
            'username': 'a${offset + 1}',
            'amount': 10,
            'outstanding': 10,
            'status': 'open',
            'currency': 'ILS',
          },
        ],
        'totals': {
          'count': 919,
          'open_count': 919,
          'total_amount': 184770.11,
          'outstanding': 184770.11,
        },
        'total_count': 919,
        'has_more': offset + 1 < 3,
      });
    });
    await _pump(tester, adapter, const LoansCenterScreen(), width: 1000);
    expect(find.text('919'), findsWidgets);
    expect(find.textContaining('184,770.11'), findsOneWidget);
    // Infinite scroll pulled the next pages with offset (not 100 rows only).
    expect(
      adapter.requests.map((r) => '${r.query['offset']}').toList(),
      ['0', '1', '2'],
    );
    expect(find.textContaining('نهاية القائمة'), findsOneWidget);
  });
}
