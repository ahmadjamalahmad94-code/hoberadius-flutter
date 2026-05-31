import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/events/domain/business_event_model.dart';

void main() {
  test('business events page parses Arabic-safe event labels', () {
    final page = BusinessEventsPage.fromJson({
      'ok': true,
      'data': {
        'count': 1,
        'items': [
          {
            'id': 22,
            'category': 'security',
            'severity': 'warning',
            'actor_type': 'admin',
            'actor_id': 7,
            'target_type': 'subscriber',
            'target_id': 44,
            'event_key': 'operator.review',
            'message': 'تمت مراجعة طلب العميل',
            'correlation_id': 'REQ-22',
            'created_at': '2026-05-31T14:15:00Z',
          },
        ],
      },
    });

    final event = page.items.single;
    expect(page.count, 1);
    expect(event.categoryLabel, 'الأمان');
    expect(event.severityLabel, 'تنبيه');
    expect(event.eventKeyLabel, 'مراجعة تشغيل');
    expect(event.actorLabel, 'مدير #7');
    expect(event.targetLabel, 'مشترك #44');
    expect(event.messageLabel, 'تمت مراجعة طلب العميل');
    expect(event.createdAtLabel, '2026-05-31 14:15');
  });

  test('business summary parses compact counters', () {
    final summary = BusinessSummary.fromJson({
      'ok': true,
      'data': {
        'wallets': 2,
        'wallet_balance': '25.50',
        'ledger_entries': 4,
        'ledger_total': '99.00',
        'events': 8,
        'price_snapshots': 3,
        'revenue_records': 1,
      },
    });

    expect(summary.wallets, 2);
    expect(summary.walletBalance, '25.50');
    expect(summary.ledgerEntries, 4);
    expect(summary.ledgerTotal, '99.00');
    expect(summary.events, 8);
    expect(summary.priceSnapshots, 3);
    expect(summary.revenueRecords, 1);
  });

  test('English event messages are hidden behind Arabic event label', () {
    final event = BusinessEvent.fromJson({
      'category': 'financial',
      'severity': 'info',
      'event_key': 'wallet.credit',
      'message': 'Wallet credit recorded',
    });

    expect(event.messageLabel, 'إضافة رصيد للمحفظة');
    expect(event.categoryLabel, 'المالية');
    expect(event.severityLabel, 'معلومة');
  });
}
