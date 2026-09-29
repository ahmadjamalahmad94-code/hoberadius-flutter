// FIX2 — finance: summary figures, ledger types, revenue totals, loans
// center, finance-page defaults, distributor same-click guard.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_client.dart';
import 'package:hoberadius_app/core/api/idempotency.dart';
import 'package:hoberadius_app/core/format/bidi.dart';
import 'package:hoberadius_app/core/format/currency.dart';
import 'package:hoberadius_app/core/format/panel_time.dart';
import 'package:hoberadius_app/core/l10n/arabic_labels.dart';
import 'package:hoberadius_app/features/accounting/data/accounting_repository.dart';
import 'package:hoberadius_app/features/accounting/domain/accounting_model.dart';
import 'package:hoberadius_app/features/accounting/presentation/financial_reports_screen.dart';
import 'package:hoberadius_app/features/accounting/presentation/loans_center_screen.dart';
import 'package:hoberadius_app/features/accounting/presentation/subscriber_finance_screen.dart';
import 'package:hoberadius_app/features/accounting/presentation/widgets/finance_summary_card.dart';
import 'package:hoberadius_app/features/accounting/presentation/widgets/finance_tables.dart';
import 'package:hoberadius_app/features/distributors/presentation/distributor_detail_screen.dart';
import 'package:hoberadius_app/features/revenue/domain/revenue_model.dart';

import 'support/fake_api.dart';

LoanEntry _loan(
  int id,
  num amount,
  String status, {
  num? outstanding,
  num settled = 0,
}) =>
    LoanEntry(
      id: id,
      subscriberId: 1,
      username: 'u',
      durationMinutes: 60,
      amount: amount,
      currency: 'ILS',
      reason: '',
      status: status,
      createdAt: null,
      outstanding: outstanding,
      settledAmount: settled,
    );

PaymentTransaction _pay(int id, num amount, {String status = 'posted'}) =>
    PaymentTransaction.fromJson({
      'id': id,
      'amount': amount,
      'currency': 'ILS',
      'status': status,
    });

void main() {
  group('5 — finance summary figures', () {
    test('open loans count the outstanding, forgiven is not settled', () {
      final f = FinanceSummaryFigures.compute(
        payments: [_pay(1, 10)],
        loans: [
          _loan(827, 16.67, 'open', outstanding: 11.67, settled: 5),
          _loan(828, 5, 'voided'),
          _loan(829, 3, 'settled', outstanding: 0, settled: 3),
        ],
        balance: 0,
      );
      expect(f.openOutstanding, 11.67);
      expect(f.openCount, 1);
      expect(f.forgivenTotal, 5);
      expect(f.settledTotal, 8); // 5 partial + 3 settled — not the forgiven 5
    });

    test('payments use the server total over every row', () {
      final f = FinanceSummaryFigures.compute(
        payments: [for (var i = 0; i < 100; i++) _pay(i, 10)],
        loans: const [],
        balance: 0,
        serverTotalPaid: 1055.82,
      );
      expect(f.paidTotal, 1055.82);
      expect(f.paidIsServerTotal, isTrue);
    });

    test('«الصافي» counts a balance debt (r10_028: owes 10.33)', () {
      final f = FinanceSummaryFigures.compute(
        payments: [_pay(1, 10)],
        loans: [_loan(1, 7, 'open')],
        balance: -3.33,
      );
      expect(f.net, -10.33);
    });

    test('voided payments are not paid', () {
      final f = FinanceSummaryFigures.compute(
        payments: [_pay(1, 10), _pay(2, 99, status: 'voided')],
        loans: const [],
        balance: 0,
      );
      expect(f.paidTotal, 10);
      expect(f.paidIsServerTotal, isFalse);
    });
  });

  group('5 — ledger types and raw tokens in Arabic', () {
    test('every server entry type has an Arabic label', () {
      for (final t in [
        'payment',
        'loan',
        'settlement',
        'void',
        'adjustment',
        'debt',
        'debt_settlement',
        'time_extension',
        'quota_topup',
        'writeoff',
        'on_account_credit',
        'cash_balance',
        'correction',
        'card_sale',
        'wallet_recharge',
        'batch_creation',
        'something_new',
      ]) {
        final l = ledgerTypeLabel(t);
        expect(l, isNot(contains('غير معروف')), reason: t);
        expect(l, isNot(t), reason: t);
      }
      for (final s in [
        'payment_void',
        'loan_writeoff',
        'ledger_void',
        'subscriber_time_extension',
        'subscriber_quota_topup',
        'subscriber_plan_change',
        'subscriber_daily_quota_reset',
        'subscriber_cash_balance',
        'payment_balance_settlement',
      ]) {
        expect(ledgerSourceLabel(s), isNot('مصدر آخر'), reason: s);
      }
    });

    test('op-report / financial-report tokens', () {
      expect(rawTokenLabel('temporary_speed'), 'سرعة مؤقتة');
      expect(rawTokenLabel('all_failed'), 'فشل الكل');
      expect(rawTokenLabel('panel'), 'لوحة التحكم');
      expect(rawTokenLabel('writeoff'), isNot('writeoff'));
      expect(rawTokenLabel('never_run'), isNot('never_run'));
      expect(rawTokenLabel('skipped'), isNot('skipped'));
      expect(rawTokenLabel('wallet:4'), 'محفظة #4');
      expect(rawTokenLabel('distributor #1'), 'موزّع #1');
      expect(rawTokenLabel('accounting_ledger_entries'), 'دفتر القيود');
    });

    test('a forgiven loan never reads «تمت التسوية»', () {
      expect(loanClosedLabel('settled'), 'تمت التسوية');
      expect(loanClosedLabel('voided'), isNot('تمت التسوية'));
    });

    test('«outstanding» header and report timestamps', () {
      expect(financialReportColumnLabel('outstanding'), 'المتبقّي');
      PanelTimeZone.configure(name: 'Asia/Gaza');
      addTearDown(PanelTimeZone.reset);
      expect(
        formatReportTimestamp('2026-09-29T00:01:08.532034Z'),
        '2026-09-29 03:01',
      );
      expect(formatReportTimestamp(null), '—');
    });
  });

  group('5 — «المركز المالي» per currency, no voided rows', () {
    final page = RevenuePage.fromJson({
      'data': {
        'items': [
          {
            'id': 1,
            'source_type': 'subscriber_payment',
            'collected_amount': 10,
            'net_profit': 10,
            'company_share': 10,
            'currency': 'ILS',
            'status': 'posted',
          },
          {
            'id': 2,
            'source_type': 'subscriber_payment',
            'collected_amount': 2000000,
            'net_profit': 2000000,
            'company_share': 2000000,
            'currency': 'ILS',
            'status': 'voided',
          },
          {
            'id': 3,
            'source_type': 'card_batch',
            'collected_amount': 20,
            'net_profit': 8,
            'company_share': 6,
            'currency': 'USD',
            'status': 'posted',
          },
          {
            'id': 4,
            'source_type': 'card_batch',
            'collected_amount': 50,
            'net_profit': 50,
            'company_share': 50,
            'currency': 'USD',
            'status': 'voided',
          },
        ],
        'count': 4,
        'totals': {
          'collected': 5905.48,
          'mixed_currency': true,
          'by_currency': [
            {'currency': 'ILS', 'total': 5905.48},
            {'currency': 'EUR', 'total': 420.10},
          ],
        },
      },
    });

    test('net profit = server payments + live other rows, per currency', () {
      String show(List<CurrencyAmount> l) =>
          stripBidiMarks(formatCurrencyList(l));
      expect(show(page.netProfitPerCurrency), '5,905.48 ILS · 420.10 EUR · 8 USD');
      expect(show(page.companySharePerCurrency), contains('6 USD'));
      expect(show(page.collectedPerCurrency), contains('20 USD'));
      expect(show(page.netProfitPerCurrency), isNot(contains('2,000')));
    });

    test('each «amount CUR» is an LTR isolate', () {
      final text = formatByCurrency(const [
        CurrencyAmount('ILS', 5905.48),
        CurrencyAmount('USD', 426.31),
      ]);
      expect(kLtrIsolate.allMatches(text).length, 2);
      expect(stripBidiMarks(text), '5,905.48 ILS · 426.31 USD');
    });

    test('filtered rows never sum voided ones', () {
      final s = RevenueSummary.fromItems(page.items);
      expect(s.totalNetProfit, 18);
    });
  });

  group('5 — loans center input + outcome', () {
    test('«-1» is refused, not a 1.00 loan', () {
      expect(
        validateLoanCenterInput(
          username: 'ali',
          daysText: '1',
          hoursText: '0',
          amountText: '-1',
        ),
        contains('السالبة'),
      );
      expect(
        validateFinanceLoanInput(hoursText: '2', amountText: '-1'),
        contains('السالبة'),
      );
      expect(
        validateLoanCenterInput(
          username: 'ali',
          daysText: '400',
          hoursText: '0',
          amountText: '0',
        ),
        contains('سنة'),
      );
      expect(
        validateLoanCenterInput(
          username: 'ali',
          daysText: '0',
          hoursText: '5',
          amountText: '0',
          priceFromDays: true,
        ),
        isNotNull,
      );
    });

    test('the server approval result is what the operator reads', () {
      expect(
        loanCreatedMessage(
          LoanCreateOutcome(
            loan: LoanEntry.fromJson(const {}),
            pendingApproval: true,
            message: 'أُرسلت للاعتماد',
          ),
        ),
        'أُرسلت للاعتماد',
      );
      final msg = loanCreatedMessage(
        LoanCreateOutcome(
          loan: LoanEntry.fromJson(const {
            'id': 5,
            'username': 'ali',
            'amount': 420,
            'currency': 'ILS',
          }),
        ),
      );
      expect(msg, contains('420'));
    });

    test('repository reads a 202 pending answer', () async {
      final adapter = RecordingAdapter(
        (r) => FakeResponse.ok(
          {
            'loan': null,
            'pending_approval': true,
            'message': 'بانتظار موافقة المالك',
          },
          status: 202,
        ),
      );
      final repo = AccountingRepository(fakeApiClient(adapter));
      final o = await repo.createLoanWithOutcome(
        username: 'ali',
        days: 30,
        priceFromDays: true,
      );
      expect(o.pendingApproval, isTrue);
      expect(o.message, 'بانتظار موافقة المالك');
      expect(adapter.requests.single.jsonBody['price_from_days'], true);
    });
  });

  testWidgets('5 — finance page: «تطبيق على الريدياس» is ON by default',
      (tester) async {
    final adapter = RecordingAdapter((r) {
      if (r.method == 'GET') {
        if (r.path.endsWith('/360')) {
          return FakeResponse.ok({
            'financial': {'total_paid': 55.5, 'open_loan_amount': 4},
          });
        }
        if (r.path.startsWith('/api/v1/accounts/')) {
          return FakeResponse.ok({
            'id': 1,
            'username': 'ali',
            'status': 'enabled',
            'balance': -3,
          });
        }
        return FakeResponse.ok({'items': <dynamic>[]});
      }
      return FakeResponse.ok(
        {
          'payment': {'id': 9, 'amount': 5, 'activation_result': {}},
        },
        status: 201,
      );
    });
    tester.view.physicalSize = const Size(390, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(fakeApiClient(adapter)),
        ],
        child: const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: SingleChildScrollView(
                child: SubscriberFinanceScreen(username: 'ali'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Summary uses the 360 totals and the balance debt.
    expect(find.textContaining('55.50'), findsOneWidget);
    expect(find.text('دين على الرصيد'), findsOneWidget);
    // Turn the preview off and record for real.
    await tester.tap(find.text('معاينة بدون تنفيذ').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'المبلغ',
      ),
      '5',
    );
    await tester.tap(find.text('تسجيل الدفعة'));
    await tester.pumpAndSettle();
    final post = adapter.where('POST', '/api/v1/payments').single;
    expect(post.jsonBody['apply_to_radius'], true);
  });

  testWidgets('5 — distributor «تسجيل الحركة»: 3 taps in one frame → 1 POST',
      (tester) async {
    final gate = Completer<void>();
    final adapter = RecordingAdapter((r) {
      if (r.method == 'GET' && r.path.endsWith('/summary')) {
        return FakeResponse.ok({
          'summary': {
            'distributor': {'id': 12, 'name': 'r11_dist'},
            'balance': 15,
            'debt_balance': 30,
          },
        });
      }
      if (r.method == 'GET') return FakeResponse.ok({'items': <dynamic>[]});
      return FakeResponse.ok({'entry': {'id': 1}}, status: 201);
    });
    adapter.beforeRespond = (r) async {
      if (r.method == 'POST') await gate.future;
    };
    tester.view.physicalSize = const Size(390, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(fakeApiClient(adapter)),
        ],
        child: const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: SingleChildScrollView(
                child: DistributorDetailScreen(distributorId: 12),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'المبلغ',
      ),
      '1',
    );
    await tester.pump();
    final button = find.text('تسجيل الحركة');
    // Three synchronous taps, no frame in between.
    final center = tester.getCenter(button);
    await tester.tapAt(center);
    await tester.tapAt(center);
    await tester.tapAt(center);
    gate.complete();
    await tester.pumpAndSettle();
    final posts = adapter.requests.where((r) => r.method == 'POST').toList();
    expect(posts, hasLength(1));
    expect(posts.single.headers[kIdempotencyHeader], isNotEmpty);
  });
}
