// FIX2 — adoption of the plansreports backend contract (additive fields).
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/core/api/api_exception.dart';
import 'package:hoberadius_app/core/api/visible_error_message.dart';
import 'package:hoberadius_app/core/format/bidi.dart';
import 'package:hoberadius_app/features/accounting/data/accounting_repository.dart';
import 'package:hoberadius_app/features/accounting/presentation/financial_reports_screen.dart';
import 'package:hoberadius_app/features/dashboard/domain/dashboard_model.dart';
import 'package:hoberadius_app/features/revenue/data/revenue_repository.dart';
import 'package:hoberadius_app/features/subscribers/domain/subscriber_actions_model.dart';
import 'package:hoberadius_app/features/subscribers/presentation/widgets/subscriber_action_dialogs.dart';

import 'support/fake_api.dart';

void main() {
  test('dashboard reads subscribers.other', () {
    final m = DashboardMetrics.fromJson({
      'subscribers': {'total': 1004, 'enabled': 900, 'other': 6},
    });
    expect(m.otherSubscribers, 6);
    final none = DashboardMetrics.fromJson({
      'subscribers': {'total': 1},
    });
    expect(none.otherSubscribers, 0);
  });

  test('revenue pages with offset; has_more read; duplicates dropped',
      () async {
    final adapter = RecordingAdapter((r) {
      final off = int.parse('${r.query['offset'] ?? 0}');
      return FakeResponse.ok({
        'items': [
          {
            'id': off + 1,
            'source_type': 'subscriber_payment',
            'status': 'posted',
          },
          {
            'id': off + 2,
            'source_type': 'subscriber_payment',
            'status': 'posted',
          },
        ],
        'count': 2,
        'has_more': off == 0,
      });
    });
    final repo = RevenueRepository(fakeApiClient(adapter));
    final first = await repo.list(limit: 2);
    expect(first.hasMore, isTrue);
    expect(adapter.requests.single.query.containsKey('offset'), isFalse);
    final next = await repo.list(offset: 2, limit: 2);
    expect(adapter.requests.last.query['offset'], 2);
    final merged =
        first.withMore([...first.items, ...next.items], hasMore: next.hasMore);
    expect(merged.items, hasLength(4));
    expect(merged.hasMore, isFalse);
  });

  test('change-plan toast shows the server direction', () {
    final msg = stripBidiMarks(
      changePlanDoneMessage('VIP', {
        'direction': 'lower',
        'minute_delta': 120,
        'debt_amount': 0,
      }),
    );
    expect(msg, contains('VIP'));
    expect(msg, contains('أرخص'));
    expect(msg, contains('أُضيف'));
    expect(changePlanDoneMessage('x', const {}), isNot(contains('(')));
  });

  test('quota usage lines from daily / monthly / period top-up', () {
    final lines = quotaUsageLines({
      'quota_mb': 20480,
      'used_mb': 1024,
      'period_topup_mb': 100,
      'daily': {'combined': 200, 'used_mb': 150},
      'monthly': {'download': 5120, 'used_download_mb': 2048},
    });
    expect(lines, hasLength(4));
    expect(lines[0], contains('1 GB من 20 GB'));
    expect(lines[2], contains('150 MB من 200 MB'));
    expect(lines[3], contains('تنزيل 2 GB من 5 GB'));
    expect(quotaUsageLines({'used_today_mb': 12}), ['المستهلك اليوم: 12 MB']);
  });

  test('reports: server columns, hidden helpers, per-currency money cells', () {
    final t = FinancialReportTable.fromResponse({
      'data': {
        'items': [
          {
            'period': '2026-09',
            'total': 1000.5,
            'transactions': 3,
            'mixed_currency': true,
            'by_currency': [
              {'currency': 'ILS', 'total': 900},
              {'currency': 'USD', 'total': 100.5},
            ],
          },
        ],
        'columns': [
          {'key': 'period', 'label': 'الفترة'},
          {'key': 'transactions', 'label': 'عدد العمليات'},
          {'key': 'total', 'label': 'الإجمالي'},
          {'key': 'by_currency', 'label': 'حسب العملة'},
        ],
      },
    });
    expect(t.columns.first, ('period', 'الفترة'));
    expect(reportColumnKeys(t), ['period', 'transactions', 'total']);
    expect(
      stripBidiMarks(reportCell(t.rows.single, 'total')),
      '900 ILS · 100.50 USD',
    );
    expect(reportCell(t.rows.single, 'transactions'), '3');
    // Old server: no columns → keys of the rows.
    final old = FinancialReportTable.fromResponse({
      'data': {
        'items': [
          {'total': 5.0, 'period': 'x'},
        ],
      },
    });
    expect(old.columns, isEmpty);
    expect(reportColumnKeys(old), containsAll(['total', 'period']));
  });

  test('unknown API path / method → Arabic, never raw', () {
    expect(
      visibleErrorMessage(
        ApiException(
          code: 'http_405',
          message: 'Method Not Allowed',
          status: 405,
        ),
      ),
      kMethodNotAllowedMessage,
    );
    expect(
      visibleErrorMessage(
        ApiException(
          code: 'http_404',
          message: '<html>Not Found</html>',
          status: 404,
        ),
      ),
      kUnknownPathMessage,
    );
    // fix2 servers send an Arabic JSON message: kept.
    expect(
      visibleErrorMessage(
        ApiException(
          code: 'not_found',
          message: 'المسار غير موجود.',
          status: 404,
        ),
      ),
      'المسار غير موجود.',
    );
  });
}
