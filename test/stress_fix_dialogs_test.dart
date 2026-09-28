import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/api/idempotency.dart';
import 'package:hoberadius_app/features/subscribers/domain/subscriber_actions_model.dart';
import 'package:hoberadius_app/features/subscribers/presentation/widgets/subscriber_action_dialogs.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'support/fake_api.dart';

SubscriberActionsContext _ctx({double debt = 13.33}) =>
    SubscriberActionsContext.fromJson({
      'username': 'st12_033',
      'status': 'enabled',
      'expire_at': '2026-10-10T21:00:00Z',
      'currency': 'ILS',
      'plan': {'id': 3, 'name': 'شهري', 'price': 120, 'minutes': 43200},
      'effective_price': 120,
      'balance': -debt,
      'debt': debt,
      'open_loans': <dynamic>[],
      'max_free_loan_hours': 72,
    });

Future<void> _open(
  WidgetTester tester,
  RecordingAdapter adapter,
  Widget dialog,
) async {
  tester.view.physicalSize = const Size(390, 844);
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
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showActionDialog(context, dialog),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async => initializeDateFormatting('en'));

  group('M3 — payment hint never deducts more than was paid', () {
    test('10 paid against a 13.33 debt deducts 10', () {
      final hint = paymentCoverageHint(
        amount: 10,
        settledLoans: 0,
        debt: 13.33,
        effectivePrice: 120,
        planMinutes: 43200,
        currency: 'ILS',
      );
      expect(hint, contains('سيُخصم ${formatMoney(10, 'ILS')}'));
      expect(hint, contains('من أصل ${formatMoney(13.33, 'ILS')}'));
      expect(hint, contains('لا يبقى مبلغ'));
      expect(hint, isNot(contains('${formatMoney(13.33, 'ILS')} لتسوية')));
    });

    test('a payment above the debt keeps the rest for time', () {
      final hint = paymentCoverageHint(
        amount: 20,
        settledLoans: 0,
        debt: 5,
        effectivePrice: 30,
        planMinutes: 43200,
        currency: 'ILS',
      );
      expect(hint, contains('سيُخصم ${formatMoney(5, 'ILS')} لتسوية'));
      expect(hint, contains('والباقي ${formatMoney(15, 'ILS')}'));
    });
  });

  testWidgets('5/6 — 503 busy → «إعادة المحاولة» resends with the SAME key',
      (tester) async {
    var calls = 0;
    final adapter = RecordingAdapter((r) {
      calls++;
      if (calls == 1) {
        return FakeResponse.error(
          503,
          'server_busy',
          'الخادم مشغول الآن، أعد المحاولة بعد لحظات.',
          details: {'retryable': true},
        );
      }
      return FakeResponse.ok(
        {
          'payment': {'id': 1},
        },
        status: 201,
      );
    });
    await _open(tester, adapter, PaymentDialog(c: _ctx()));
    await tester.enterText(find.byType(TextField).first, '10');
    await tester.pumpAndSettle();
    await tester.tap(find.text('تسجيل'));
    await tester.pumpAndSettle();
    expect(find.textContaining('الخادم مشغول'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();
    final posts = adapter.where('POST', '/payment').toList();
    expect(posts, hasLength(2));
    final k1 = posts[0].headers[kIdempotencyHeader];
    expect(k1, isA<String>());
    expect(posts[1].headers[kIdempotencyHeader], k1);
    expect(find.byType(PaymentDialog), findsNothing); // closed on success
  });

  testWidgets('5 — a 422 on the loan dialog shows the server message',
      (tester) async {
    final adapter = RecordingAdapter(
      (_) => FakeResponse.error(
        422,
        'validation_error',
        'لا يمكن منح سلفة لهذا المشترك الآن.',
      ),
    );
    await _open(tester, adapter, LoanDialog(c: _ctx()));
    await tester.tap(find.text('إضافة'));
    await tester.pumpAndSettle();
    expect(find.text('لا يمكن منح سلفة لهذا المشترك الآن.'), findsOneWidget);
    expect(find.byType(LoanDialog), findsOneWidget); // stays open
  });

  testWidgets('4f — payment above 1,000,000 is blocked in the dialog',
      (tester) async {
    final adapter = RecordingAdapter((_) => FakeResponse.ok({}));
    await _open(tester, adapter, PaymentDialog(c: _ctx()));
    await tester.enterText(find.byType(TextField).first, '999999999999');
    await tester.pumpAndSettle();
    expect(find.textContaining('كبير جدًا'), findsOneWidget);
    await tester.tap(find.text('تسجيل'));
    await tester.pumpAndSettle();
    expect(adapter.requests, isEmpty);
  });
}
